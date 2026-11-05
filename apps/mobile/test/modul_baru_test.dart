import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/features/auth/domain/pengguna.dart';
import 'package:smart_mobile/features/chat/data/chat_repository.dart';
import 'package:smart_mobile/features/dokumen/domain/dokumen.dart';
import 'package:smart_mobile/features/profil/domain/profil_lanjutan.dart';

void main() {
  test('Dokumen meringkas nilai yang terbaca', () {
    final d = Dokumen.fromJson({
      'id': 'd1',
      'jenis': 'cv',
      'nama_berkas': 'cv.png',
      'status_baca': 'selesai',
      'hasil_baca': {
        'ipk': 3.71,
        'semester': 6,
        'skor_bahasa': {'toefl': 547.0},
      },
    });
    expect(d.ringkasan, ['IPK 3.71', 'Semester 6', 'TOEFL 547.0']);
  });

  test('Pengguna memuat profil tambahan dan preferensi notifikasi', () {
    final p = Pengguna.fromJson({
      'id': 'u1',
      'email': 'a@example.com',
      'nama': 'Aku',
      'kondisi_khusus': ['disabilitas', 'ekonomi_kurang_mampu'],
      'catatan_tambahan': 'penerima KIP',
      'preferensi_notifikasi': {'email': false, 'push': true},
    });
    expect(p.kondisiKhusus, ['disabilitas', 'ekonomi_kurang_mampu']);
    expect(p.catatanTambahan, 'penerima KIP');
    expect(p.notifEmail, isFalse);
    expect(p.notifPush, isTrue);
    const m = ProfilMasukan(
      kondisiKhusus: ['disabilitas'],
      catatanTambahan: 'x',
    );
    expect(m.toJson(), {
      'kondisi_khusus': ['disabilitas'],
      'catatan_tambahan': 'x',
    });
  });

  test('PesanChat membaca jawaban kosong', () {
    final p = PesanChat.fromJson({
      'id': 'c1',
      'pesan': 'halo',
      'jawaban': null,
    });
    expect(p.jawaban, isNull);
  });

  test('Baris profil lanjutan diurai dan diformat bolak-balik', () {
    final daftar = uraiBaris(
      'HMJ TI | Ketua | 2025\nUKM Robotik\n\n | tanpa nama',
      ['nama', 'jabatan', 'tahun'],
    );
    expect(daftar, [
      {'nama': 'HMJ TI', 'jabatan': 'Ketua', 'tahun': 2025},
      {'nama': 'UKM Robotik'},
    ]);
    expect(
      formatBaris(daftar, ['nama', 'jabatan', 'tahun']),
      'HMJ TI | Ketua | 2025\nUKM Robotik',
    );
    expect(uraiDaftarKoma('Python, , SQL'), ['Python', 'SQL']);
  });
}
