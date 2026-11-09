# LumiCart — WhatsApp AI CS (GitHub + Cloudflare)

Proyek **starter** untuk perusahaan dummy LumiCart. Menyediakan:

1. `/web/index.html`: prototype dashboard CS + WhatsApp yang berjalan **simulasi secara lokal di browser**, dapat di-host di Cloudflare Pages. **Belum terhubung** ke D1/Worker/akun admin sungguhan.
2. `/worker`: webhook WhatsApp Cloud API di Cloudflare Workers dengan validasi GET/POST (`X-Hub-Signature-256`), deduplikasi pesan, penyimpanan di D1, status pesanan yang dibatasi ke nomor pengirim, handover otomatis via kata `admin`, dan jawaban AI opsional melalui OpenAI Responses API.
3. `/worker/schema.sql`: tabel D1 yang diperlukan.

> **Belum production-ready.** Backend Worker belum punya dashboard admin sungguhan, autentikasi agen, antrian pesan yang durable, penanganan media, pengelolaan kegagalan/retry yang andal, aturan retensi/penghapusan data, dan audit keamanan. Dashboard `/web` hanya demo dan **tidak** dapat mengambil alih WhatsApp sebenarnya. Untuk produksi, tambahkan Cloudflare Access + verifikasi identitas pengguna pada API dashboard, Queues/retry serta monitoring, izin dan kebijakan data, kontrol rate limit, dan prosedur eskalasi operasional.

## A. Upload kode ke GitHub

Buat repository **private** `lumicart-wa-ai` di GitHub, lalu:

```bash
git init
git add .
git commit -m "Initial LumiCart WA AI starter"
git branch -M main
git remote add origin https://github.com/USERNAME/lumicart-wa-ai.git
git push -u origin main
```

Jangan pernah memasukkan token, App Secret, atau API Key ke GitHub (termasuk repo privat).

## B. Deploy prototype UI ke Cloudflare Pages

1. Cloudflare Dashboard -> Workers & Pages -> Create -> Pages -> Connect to Git.
2. Pilih repository `lumicart-wa-ai`.
3. Set **Root directory** = `web`.
4. Set **Build command** kosong (static HTML), **Output directory** = `.` (relatif terhadap root `web`).
5. Deploy. Cloudflare akan memberi URL `*.pages.dev`.

## C. Buat database D1 dan Worker

Instal Node.js, buka terminal:

```bash
cd worker
npm install
npx wrangler login
npx wrangler d1 create lumicart-db
```

Ganti `database_id` pada `worker/wrangler.toml` dengan UUID yang diberikan Cloudflare. Lalu:

```bash
npm run db:local
npm run db:remote
```

Atur **secrets** Cloudflare Worker (jangan masukkan ke GitHub):

```bash
npx wrangler secret put WA_VERIFY_TOKEN
npx wrangler secret put WA_APP_SECRET
npx wrangler secret put WA_ACCESS_TOKEN
npx wrangler secret put WA_PHONE_NUMBER_ID
npx wrangler secret put OPENAI_API_KEY  # opsional; tanpa ini bot menggunakan FAQ fallback
```

Anda juga bisa mengisi Secrets melalui dashboard Cloudflare. Untuk pertama kali, jalankan `npm run deploy` agar Worker terbentuk, lalu tambah secrets di dashboard, lalu redeploy jika diperlukan. Bila `wrangler secret put` meminta pembuatan Worker dulu, lakukan deploy awal terlebih dahulu.

`GRAPH_API_VERSION` dalam `wrangler.toml` harus disesuaikan dengan versi yang masih didukung oleh Meta. `OPENAI_MODEL` dapat diganti dengan model yang tersedia di akun API Anda.

## D. Deploy Worker via GitHub

Cloudflare -> Workers & Pages -> Create application -> GitHub -> pilih repo yang sama. Set **Root directory** = `worker` dan **Deploy command** = `npx wrangler deploy`; samakan nama Worker dengan `name` di `wrangler.toml` (`lumicart-wa-bot`). Alternatif: jalankan `npm run deploy` secara manual setelah perubahan.

Integrasi GitHub ini harus diarahkan ke folder `worker`, bukan folder `web`.

## E. Hubungkan WhatsApp Cloud API

1. Di Meta for Developers, buat aplikasi dan tambahkan WhatsApp Business Platform.
2. Siapkan nomor testing dahulu; dapatkan `WA_PHONE_NUMBER_ID` dan access token.
3. Isi `WA_APP_SECRET` dari aplikasi Meta, dan buat sendiri `WA_VERIFY_TOKEN` acak yang kuat.
4. Pada konfigurasi webhook WhatsApp, pasang URL callback:

   `https://lumicart-wa-bot.<your-subdomain>.workers.dev/webhook`

5. Isi Verify Token **persis** sama dengan secret `WA_VERIFY_TOKEN`.
6. Subscribe event `messages` pada WhatsApp. Pastikan WABA/app tersubscribe sesuai pengaturan Meta.
7. Uji pesan WhatsApp pertama dengan nomor pengujian dan izin yang sesuai.

## F. Perilaku chatbot Worker

- `halo`: jika `OPENAI_API_KEY` tersedia, jawab berdasar FAQ dummy; jika tidak, fallback statis.
- `cek pesanan LM-2048`: baca tabel `orders` berdasarkan **ID pesanan DAN nomor WhatsApp pengirim**. Data pesanan tidak akan dikarang dan tidak tersedia sebelum tabel diisi.
- `admin`: ubah `mode` menjadi `human`, beri konfirmasi. Pesan setelahnya disimpan tanpa balasan otomatis. **Dashboard human inbox sungguhan belum dibuat**; gunakan integrasi dashboard/operasional resmi sebelum live.

> Penting: Implementasi contoh ini meng-ACK webhook segera dan memproses pesan dengan `waitUntil`. Ini cocok sebagai contoh awal, tetapi belum menyimpan pekerjaan pada antrean durable. Jika proses gagal setelah pesan masuk tercatat, balasan bisa hilang. Gunakan Cloudflare Queues, status pemrosesan, retry, dan dead-letter queue untuk produksi.

## G. Keamanan sebelum live

- Lindungi API dashboard dengan Cloudflare Access atau sistem autentikasi server-side serta RBAC.
- Jangan mengekspos nama, nomor, atau status order kepada nomor yang belum diotorisasi.
- Tentukan retensi data, hak penghapusan, backup, pemberitahuan privasi, dan persetujuan yang diperlukan.
- Verifikasi tanda tangan Meta HMAC-SHA256; contoh webhook sudah melakukannya.
- Patuhi jendela layanan WhatsApp 24 jam dan template yang disetujui jika mengirim pesan di luar jendela.
- Batasi tindakan AI; refund, perubahan alamat, dan pembatalan harus dikonfirmasi/diotorisasi dengan cara aman.

## H. Referensi

- Git integration Workers: https://developers.cloudflare.com/workers/ci-cd/builds/git-integration/
- Git integration Pages: https://developers.cloudflare.com/pages/configuration/git-integration/
- D1: https://developers.cloudflare.com/d1/get-started/
- Workers Secrets: https://developers.cloudflare.com/workers/configuration/secrets/
- Meta Postman WhatsApp Cloud API: https://www.postman.com/meta/whatsapp-business-platform/documentation/wlk6lh4/whatsapp-cloud-api
- OpenAI API: https://platform.openai.com/docs/api-reference/responses
