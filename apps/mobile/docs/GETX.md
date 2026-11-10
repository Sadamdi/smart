# Pengelolaan State dengan GetX (SMART Mobile 1.4.0)

Seluruh lapisan state aplikasi memakai GetX (paket `get`): `GetxController`, variabel reaktif `.obs`, dan `Obx`. Navigasi tetap memakai go_router lewat `MaterialApp.router`, sehingga hanya state management yang berpindah dari Riverpod ke GetX. Tidak ada lagi dependensi `flutter_riverpod`.

## Pola dasar

- Satu `GetxController` per fitur, di `lib/features/<fitur>/presentation/`.
- State disimpan di `Rx` (`RxBool`, `Rx<T>`, `RxnString`, `Rxn<T>`). Layar membacanya di dalam `Obx(() => ...)`.
- Layar mengambil controller dengan `Get.find<NamaController>()`. Controller dan repository didaftarkan sekali oleh `pasangDependensi()` (`lib/core/dependensi.dart`), dipanggil di `main()`.
- Panggilan jaringan memakai `async/await` di controller; layar hanya memanggil metode controller dan menampilkan hasilnya.

## Peta controller ke layar

| Controller | Isi state | Layar |
| --- | --- | --- |
| `AuthController` | `state` (memeriksa, keluar, masuk + pengguna), `mengirim`, `galatForm` | Masuk, Daftar, router (redirect), kepala halaman |
| `TemaController` | `mode` (sistem, terang, gelap), disimpan di berkas | `MaterialApp`, Pengaturan |
| `BerandaController` | menggabungkan ringkasan, pilihan utama, acara | Beranda |
| `RekomendasiController` | `ringkasan`, daftar per kategori, `kategori`, `menghitung` | Rekomendasi (Hitung ulang), Beranda |
| `JelajahController` | `state` (daftar, kursor, pencarian, filter jenjang, memuat lagi) | Jelajah |
| `TersimpanController` | `idTersimpan`, `daftar` | Beasiswa Tersimpan, penanda bookmark di Jelajah, Rekomendasi, Detail |
| `DetailController` (per id, memakai `tag`) | `detail`, aksi buka tautan dan rencana daftar | Detail Beasiswa |
| `KalenderController` | `acara`, `checklist`, tambah dan selesaikan tugas, centang berkas | Kalender, Beranda, Detail |
| `ProfilController` | `sedangDiubah`, `mengirim`, `galat` | Profil (mode baca dan Ubah profil), Profil Lanjutan, tombol Back di cangkang |
| `DokumenController` | `daftar`, `jenis`, `mengirim` | Dokumen |
| `ChatController` | `tersedia`, `riwayat`, `mengirim`, `galat` | Chat |
| `NotifikasiController` | `daftar`, `belumDibaca` | Notifikasi, lencana lonceng |
| `PengaturanController` | `menyimpan`, ubah preferensi pengingat | Pengaturan |

Pembaruan aplikasi tetap memakai `PembaruanController` (`ChangeNotifier`) yang hidup di luar dialog; bagian ini bukan state fitur sehingga tidak diubah.

## Pola memuat, kosong, galat, dan tanpa jaringan

`lib/core/async_state.dart` menyediakan dua kelas kecil:

- `AsyncState<T>`: satu dari tiga keadaan `memuat`, `galat`, `data`, dengan `when(loading:, error:, data:)`.
- `Muatan<T>`: pembungkus `Rx<AsyncState<T>>` plus fungsi pengambil data. Metodenya `muat()` (ambil ulang), `pastikan()` (muat sekali), `reset()` (kosongkan saat keluar). Data lama tetap tampil selama pemuatan ulang.

Contoh di controller:

```dart
class NotifikasiController extends GetxController {
  late final daftar = Muatan<List<Notifikasi>>(
    Get.find<NotifikasiRepository>().daftar,
  );
}
```

Contoh di layar:

```dart
Obx(() => AsyncIsi<List<Notifikasi>>(
  nilai: c.daftar.state.value,
  ulang: c.daftar.muat,        // tombol "Coba lagi"
  bangun: (daftar) => ...,     // keadaan kosong ditangani di sini
));
```

`AsyncIsi` menampilkan `MemuatState`, `GalatState`, atau isi. Galat jaringan (termasuk tanpa jaringan) diubah menjadi pesan Indonesia oleh `pesanGalat()` dan ditampilkan bersama tombol "Coba lagi". Keadaan kosong tiap layar memakai `KosongState`. Jelajah memakai `JelajahState` (class immutable di dalam `Rx`) karena punya paginasi: `memuat`, `memuatLagi`, `galat`, `galatLagi`.

Saat pengguna keluar atau sesi berakhir, `bersihkanDataSesi()` mengosongkan data semua controller agar akun berikutnya tidak melihat data lama.

## Router dan GetX

`SmartApp` membuat `GoRouter` sekali dan memasang pemantau `ever(auth.state, ...)` yang memicu `refreshListenable`, sehingga redirect (belum masuk ke layar Masuk) mengikuti `AuthController`. `MaterialApp.router` dipakai, bukan `GetMaterialApp`, agar go_router tidak terganggu.

## Cara memasang di tes

`test/helpers.dart` menyediakan:

- `siapkanGet()`: dipanggil di awal `main()` tes; menjalankan `Get.testMode = true` dan `Get.reset()` di `setUp` dan `tearDown`.
- `pasangGetUji(server, storage:, bukaTautan:)`: memanggil `pasangDependensi(dio: dioPalsu(server), storage: MemoryTokenStorage(...))` sehingga semua controller memakai Dio palsu dan token di memori.
- `aplikasi(server, sudahMasuk:)`: memasang dependensi lalu mengembalikan `SmartApp`.

```dart
void main() {
  siapkanGet();
  testWidgets('contoh', (t) async {
    final s = ServerPalsu({'GET /me/tersimpan': (_) => Balasan.ok([])});
    await t.pumpWidget(aplikasi(s));
    await t.pumpAndSettle();
  });
}
```
