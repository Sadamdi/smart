import '../../../core/api_client.dart';

class PesanChat {
  const PesanChat({required this.id, required this.pesan, this.jawaban});

  final String id;
  final String pesan;
  final String? jawaban;

  factory PesanChat.fromJson(Map<String, dynamic> j) => PesanChat(
    id: j['id'] as String,
    pesan: j['pesan'] as String,
    jawaban: j['jawaban'] as String?,
  );
}

class ChatRepository {
  ChatRepository(this._api);

  final ApiClient _api;

  Future<bool> tersedia() async {
    final r = await _api.get('/chat/status');
    return (r.data as Map<String, dynamic>)['tersedia'] as bool? ?? false;
  }

  Future<List<PesanChat>> riwayat() async {
    final r = await _api.get('/chat/riwayat');
    return [
      for (final x in r.data as List)
        PesanChat.fromJson(x as Map<String, dynamic>),
    ];
  }

  Future<PesanChat> kirim(String pesan) async {
    final r = await _api.post('/chat', body: {'pesan': pesan});
    return PesanChat.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> hapusRiwayat() => _api.delete('/chat/riwayat');
}
