Buat file tersebut di folder proyek kamu:

```bash
nano ~/MllamaMobile/README.md
```

Lalu paste isi berikut ini:

```markdown
<div align="center">

# 🛡️ Mllama Mobile
**Asisten AI Keamanan Siber (WhiteHat) untuk Termux Android**

[![RAM](https://img.shields.io/badge/RAM-4GB%20--%206GB-green)]()
[![Model](https://img.shields.io/badge/Model-Qwen2.5--3B-blue)]()
[![Engine](https://img.shields.io/badge/Engine-llama.cpp-orange)]()

</div>

---

## 📖 Tentang Proyek
**Mllama Mobile** adalah script dashboard berbasis terminal yang memungkinkan kamu menjalankan AI keamanan siber (WhiteHat) langsung dari Termux di HP Android. AI dirancang khusus untuk menjawab pertanyaan seputar kerentanan (vulnerability), analisis malware, pertahanan server, dan kode eksploitasi (untuk tujuan edukasi/pertahanan).

Script ini dioptimalkan untuk HP Android dengan RAM **4GB hingga 6GB** sehingga tidak akan membuat aplikasi Termux force close (OOM) dan AI tidak akan mengalami halusinasi (ngacok).

## ✨ Fitur Utama
- 🚀 **Auto-Setup**: Otomatis mengekstrak file `llama-b9273-bin-android-arm64.tar.gz`.
- 📥 **One-Click Download**: Langsung download model AI yang paling cocok untuk RAM kecil.
- 🧠 **Memori JSON**: Riwayat chat disimpan dalam format `.json`. Kamu bisa lanjut chat di lain hari dan AI akan mengingatnya.
- 🛡️ **System Prompt WhiteHat**: AI difokuskan 100% pada keamanan siber dan etis.
- 📊 **Dashboard Interaktif**: Tampilan menu terminal yang mudah digunakan.

---

## 📱 Persyaratan Sistem
Sebelum memulai, pastikan HP kamu memenuhi kriteria berikut:
1. **Sistem Operasi**: Android 8.0 ke atas.
2. **RAM**: Minimal 4GB (Disarankan 6GB agar respon AI lebih cepat).
3. **Penyimpanan**: Minimal 3GB ruang kosong (untuk model dan binary).
4. **Koneksi Internet**: Diperlukan untuk download model (hanya sekali di awal).
5. **Aplikasi**: [Termux](https://f-droid.org/en/packages/com.termux/) (Disarankan download dari F-Droid, bukan Play Store).

---

## 🚀 Tata Cara Penggunaan (Step-by-Step)

Ikuti langkah-langkah berikut secara berurutan di aplikasi Termux kamu:

### Langkah 1: Update Termux & Install Dependency
Pertama, pastikan paket di Termux kamu sudah up-to-date dan install `jq` (untuk membaca file JSON) serta `wget` (untuk download model).
```bash
pkg update && pkg upgrade -y
pkg install wget git jq -y
```

### Langkah 2: Buat Struktur Folder
Buat folder utama proyek dan folder pendukungnya.
```bash
mkdir -p $HOME/MllamaMobile/model
mkdir -p $HOME/MllamaMobile/sessions
```

### Langkah 3: Masukkan File Binary
Pindahkan file `llama-b9273-bin-android-arm64.tar.gz` yang sudah kamu download ke dalam folder `model/`. 
Jika file ada di folder `Download` internal HP, jalankan:
```bash
termux-setup-storage # Beri izin akses storage ke Termux
mv $HOME/storage/download/llama-b9273-bin-android-arm64.tar.gz $HOME/MllamaMobile/model/
```
*(Catatan: Sesuaikan nama filenya jika berbeda).*

### Langkah 4: Buat File Dashboard
Buat file script utama menggunakan text editor `nano`.
```bash
nano $HOME/MllamaMobile/mllama.sh
```
Lalu **paste seluruh kode script dari jawaban saya sebelumnya** ke dalam nano. Simpan dengan cara tekan `CTRL+X`, lalu tekan `Y`, lalu tekan `Enter`.

### Langkah 5: Beri Hak Akses Eksekusi
Jadikan script agar bisa dijalankan sebagai program.
```bash
chmod +x $HOME/MllamaMobile/mllama.sh
```

### Langkah 6: Jalankan Mllama Mobile!
Sekarang kamu bisa menjalankan programnya:
```bash
cd $HOME/MllamaMobile
./mllama.sh
```

---

## ⚙️ Cara Menggunakan Dashboard

Saat pertama kali dijalankan, kamu akan disambut dengan ASCII Art "Mllama Mobile" dan diminta untuk mendownload model. Pilih `y` untuk download (ukuran ~1.9GB, tunggu hingga selesai).

Setelah model selesai didownload, kamu akan masuk ke menu utama:

```text
1. Mulai Percakapan Baru
2. Lanjutkan Percakapan Tersimpan
3. Hapus Riwayat Percakapan
4. Keluar
```

- **Pilih 1**: Kamu akan diminta memberi nama sesi (contoh: `pentest_web`). Setelah itu, kamu langsung bisa bertanya pada AI. Ketik `.exit` untuk kembali ke dashboard. Riwayat akan otomatis tersimpan di `sessions/pentest_web.json`.
- **Pilih 2**: Memuat sesi lama. AI akan membaca file JSON-mu dan mengingat seluruh percakapan sebelumnya.
- **Pilih 3**: Menghapus file sesi `.json` yang tidak lagi dibutuhkan agar penyimpanan tidak penuh.

---

## 🧠 Kenapa AI-nya Tidak Ngacok (Halusinasi)?

Script ini menggunakan parameter khusus di `llama.cpp` agar AI tetap waras dan fokus:
- `--temp 0.7`: Suhu rendah, membuat AI menjawab berdasarkan fakta logis, bukan imajinasi.
- `--top-k 40` & `--top-p 0.9`: Membatasi kata-kata yang tidak relevan.
- `--repeat-penalty 1.1`: Mencegah AI mengulang-ulang kalimat yang sama.
- `--system-prompt`: Memaksa AI untuk tidak keluar dari karakter WhiteHat.

---

## 📂 Struktur Direktori

Berikut adalah isi dari folder `MllamaMobile` setelah semua berjalan:

```text
MllamaMobile/
 ├── mllama.sh           # Script dashboard utama
 ├── README.md           # Dokumentasi ini
 ├── model/
 │   ├── llama-b9273-bin-android-arm64.tar.gz  # Sumber binary kamu
 │   ├── main           # Binary yang sudah diekstrak otomatis
 │   └── cyber-model.gguf # Model AI Qwen 2.5 (Hasil download)
 └── sessions/
     └── pentest_web.json # Contoh file riwayat chat kamu
```

---

## ⚠️ Disclaimer
Alat ini dibuat untuk tujuan edukasi keamanan siber dan pertahanan jaringan (WhiteHat). Segala informasi kerentanan yang diberikan oleh AI harus digunakan secara legal dan etis. Penulis tidak bertanggung jawab atas penyalahgunaan informasi dari tool ini.

```

Simpan file README.md tersebut. Sekarang proyek **Mllama Mobile** kamu sudah memiliki dokumentasi yang sangat rapi dan profesional!