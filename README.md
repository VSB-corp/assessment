# Assessment RSU Budhi Asih

Salinan webapp sebelumnya menggunakan formulir Nakes dan Non-Nakes, satu pernyataan per layar. Penyimpanan dialihkan ke Supabase, dan halaman admin menyediakan filter, pengaturan buka/tutup, serta ekspor XLSX.

## Pemasangan

1. Gunakan proyek Supabase khusus assessment. Jalankan `schema.sql` pada SQL Editor setelah memeriksa skema dan kebijakan yang sudah ada.
2. Di Authentication buat akun email/kata sandi untuk setiap admin. Tambahkan UUID tiap akun ke `public.assessment_admins` melalui SQL Editor. Hanya akun yang terdaftar dapat membaca data atau mengubah status survei.
3. Isi `config.js` dengan Project URL dan **publishable key** Supabase. Jangan gunakan secret key atau service role di browser.
4. Sajikan folder ini sebagai situs statis HTTPS. `index.html` adalah formulir dan `admin.html` halaman admin. Izinkan domain situs di konfigurasi Auth yang sesuai.
5. Uji kedua jenis survei dengan data fiktif, coba kirim ulang dengan ID yang sama, pastikan akun non-admin tidak bisa membaca respons, dan buka file ekspor di Excel. Uji beban di lingkungan target sebelum penggunaan 1.200 responden.

Jawaban hanya dinyatakan terkirim setelah server menerima respons; ID yang sama mencegah duplikasi saat mencoba ulang. Filter pada halaman admin juga berlaku untuk ekspor. Waktu ekspor ditampilkan dalam WIB. Situs memerlukan akses internet ke Supabase dan CDN pustaka admin. Kuesioner mengumpulkan identitas dan nomor WhatsApp; atur akses admin dan masa simpan sesuai kebutuhan organisasi. Akses publik ke fungsi kirim memerlukan proteksi tambahan seperti rate limiting/CAPTCHA sebelum digunakan secara terbuka.
