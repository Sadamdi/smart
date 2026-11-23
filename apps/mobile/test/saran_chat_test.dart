import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/features/chat/data/chat_repository.dart';
import 'package:smart_mobile/features/chat/presentation/saran_chat.dart';

void main() {
  test('tanpa riwayat memberi pertanyaan pembuka', () {
    expect(saranBerikut(const []), isNotEmpty);
    expect(saranBerikut(const [], lampiran: true).first, contains('CV'));
  });

  test('mengikuti beasiswa dan topik terakhir, tanpa mengulang pertanyaan', () {
    final r = [
      const PesanChat(
        id: '1',
        pesan: 'Apa syarat IPK dan IELTS?',
        jawaban: 'IPK minimal 3.0 dan IELTS 6.5.',
        rujukan: [(id: 'b1', nama: 'Chevening')],
      ),
    ];
    final s = saranBerikut(r);
    expect(s.length, 4);
    expect(s.first, contains('Chevening'));
    expect(s.toSet().length, s.length);
    final ulang = saranBerikut([
      ...r,
      PesanChat(id: '2', pesan: s.first, jawaban: 'ok'),
    ]);
    expect(ulang, isNot(contains(s.first)));
  });
}
