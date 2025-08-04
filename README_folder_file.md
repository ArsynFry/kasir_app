# Struktur Folder & File Aplikasi Kasir

Berikut penjelasan singkat fungsi setiap folder dan file utama di proyek ini:

## lib/
- Folder utama kode aplikasi Flutter.

### main.dart
// Entry point aplikasi Flutter, inisialisasi Supabase, theme, dan routing.

### service_locator.dart
// Dependency injection, mendaftarkan provider, repository, dan service yang digunakan di seluruh aplikasi.

### app/
- assets/  // Konstanta path asset gambar/icon.
- const/   // Konstanta global aplikasi (misal: string, warna, dsb).
- database/ // Konfigurasi dan helper database lokal (SQLite).
- locale/  // File terkait lokalization/multibahasa.
- routes/  // Definisi dan helper routing aplikasi.
- services/ // Service untuk auth, storage, koneksi, dsb.
  - auth/  // Service untuk autentikasi (login, register, sign out).
  - firebase_storage/ // Service upload/download gambar (sekarang sudah diganti ke Supabase Storage).
- themes/  // Konfigurasi tema, warna, dan style aplikasi.
- utilities/ // Helper/utilitas umum (misal: logger, formatter).

### core/
- auth/      // Abstraksi base class untuk autentikasi.
- errors/    // Definisi error dan exception aplikasi.
- extensions/ // Extension method untuk tipe data umum.
- usecase/   // Base class untuk usecase (pola clean architecture).

### data/
- datasources/ // Data source untuk akses data (remote/Supabase & lokal/SQLite).
  - remote/    // Implementasi akses data ke Supabase.
  - local/     // Implementasi akses data ke database lokal.
  - interfaces/ // Abstraksi interface data source.
- models/      // Model data (DTO) untuk mapping data dari/ke database/API.
- repositories/ // Implementasi repository (menghubungkan data source ke domain).

### domain/
- entities/     // Entity utama aplikasi (Product, User, Transaction, dsb).
- repositories/ // Abstraksi repository (interface).
- usecases/     // Usecase aplikasi (logika bisnis utama).

### presentation/
- providers/ // Provider (state management) untuk setiap fitur (produk, transaksi, auth, dsb).
- screens/   // Halaman/tampilan utama aplikasi (login, dashboard, produk, transaksi, dsb).
- widgets/   // Widget custom yang digunakan di banyak tempat.

### test/
// Unit test dan integration test aplikasi.

---

## Contoh Komentar di Awal File

Misal pada file `product_form_provider.dart`:

```dart
// Provider untuk mengelola state form tambah/edit produk.
// Meng-handle input, validasi, dan pemanggilan usecase create/update produk.

class ProductFormProvider extends ChangeNotifier {
  // ...existing code...
}
```

Misal pada file `transaction_remote_datasource_impl.dart`:

```dart
// Data source untuk akses data transaksi ke Supabase (remote).
// Implementasi CRUD transaksi dan detail transaksi.

class TransactionRemoteDatasourceImpl extends TransactionDatasource {
  // ...existing code...
}
```

---

**Tips:**
- Tambahkan komentar serupa di awal setiap file utama untuk memudahkan pemahaman tim.
- Komentar pada folder bisa ditulis di README.md atau file khusus dokumentasi.
