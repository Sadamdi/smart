import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/format.dart';
import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/metrik_dan_progres.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/tombol_bulat.dart';
import '../../kalender/presentation/kalender_controller.dart';
import '../../rekomendasi/domain/rekomendasi.dart';
import '../domain/beasiswa.dart';
import 'detail_controller.dart';
import 'simpan_aksi.dart';
import 'tersimpan_controller.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.id});

  final String id;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late final DetailController _c;
  final _simpan = Get.find<TersimpanController>();
  final _kalender = Get.find<KalenderController>();

  String get id => widget.id;

  @override
  void initState() {
    super.initState();
    // Satu controller per beasiswa (tag = id); dibuang saat halaman ditutup.
    _c = Get.put(DetailController(id), tag: id);
    _simpan.idTersimpan.pastikan();
    _kalender.checklist.pastikan();
  }

  @override
  void dispose() {
    Get.delete<DetailController>(tag: id);
    super.dispose();
  }

  Future<void> _bukaPortal(BuildContext context, BeasiswaRingkas b) async {
    final pesan = ScaffoldMessenger.of(context);
    final galat = await _c.bukaPortal(b);
    if (galat != null) {
      pesan.showSnackBar(SnackBar(content: Text(galat)));
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final nilai = _c.detail.state.value;
    final tersimpan = _simpan.apakahTersimpan(id);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TombolBulat.kembali(context),
        ),
        actions: [
          if (nilai.hasValue)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TombolBulat(
                ikon: tersimpan
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                tooltip: tersimpan ? 'Hapus dari tersimpan' : 'Simpan beasiswa',
                onTap: () => ubahSimpan(context, id, tersimpan: tersimpan),
              ),
            ),
        ],
      ),
      body: AsyncIsi<BeasiswaDetail>(
        nilai: nilai,
        ulang: _c.detail.muat,
        bangun: (d) => _Isi(detail: d, tersimpan: tersimpan),
      ),
      bottomNavigationBar: nilai.hasValue
          ? DecoratedBox(
              decoration: BoxDecoration(color: Warna.surface),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: FilledButton.icon(
                    onPressed: () => _bukaPortal(context, nilai.value!.ringkas),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Buka Laman Resmi'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.detail, required this.tersimpan});

  final BeasiswaDetail detail;
  final bool tersimpan;

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final b = detail.ringkas;
    final tenggat = b.tenggat;
    final sisa = tenggat == null ? null : sisaHari(tenggat);
    final meta = [
      if ((b.penyelenggara ?? '').isNotEmpty) b.penyelenggara!,
      if ((b.negara ?? '').isNotEmpty) b.negara!,
    ].join(' · ');
    final kalender = Get.find<KalenderController>();
    final checklist = kalender.checklist.value
        ?.where((c) => c.beasiswa.id == b.id)
        .firstOrNull;

    final dekat = sisa != null && sisa >= 0 && sisa <= 7;
    final warnaTenggat = dekat ? Warna.error : Warna.navy;
    final catatan = detail.catatanKekurangan;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          b.nama,
          style: t.headlineMedium?.copyWith(fontSize: 24, height: 1.3),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(meta, style: t.bodySmall?.copyWith(fontSize: 13)),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if ((b.jenjang ?? '').isNotEmpty) Lencana(b.jenjang!),
            if (detail.kategori != null)
              Lencana.kategori(Kategori.dari(detail.kategori!)),
          ],
        ),
        const SizedBox(height: 16),
        _KotakInfo(
          warnaLatar: dekat ? Warna.errorSoft : Warna.container2,
          warnaTeks: warnaTenggat,
          label: 'TENGGAT',
          nilai: tenggat == null
              ? 'Belum diumumkan'
              : sisa! < 0
              ? 'Sudah lewat'
              : sisa == 0
              ? 'Hari ini'
              : '$sisa hari lagi',
          keterangan: tenggat == null ? null : formatTanggal(tenggat),
        ),
        const SizedBox(height: 24),
        _Bagian(
          judul: 'Syarat dan kelayakanmu',
          anak: detail.persyaratan.isEmpty
              ? Text('Persyaratan belum tercatat.', style: t.bodyMedium)
              : Column(
                  children: [
                    for (final p in detail.persyaratan) _BarisSyarat(p),
                  ],
                ),
        ),
        if (detail.alasan.isNotEmpty || catatan.isNotEmpty)
          _Bagian(
            judul: 'Alasan rekomendasi',
            anak: Text(
              [
                ...detail.alasan,
                ...catatan,
              ].map((e) => e.endsWith('.') ? e : '$e.').join(' '),
              style: t.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
            ),
          ),
        _Bagian(
          judul: 'Manfaat',
          anak: Text(
            (detail.manfaat ?? '').trim().isEmpty
                ? 'Rincian manfaat belum tercatat. Lihat laman resmi.'
                : detail.manfaat!,
            style: t.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
          ),
        ),
        _Bagian(
          judul: 'Berkas wajib',
          anak: detail.berkasWajib.isEmpty
              ? Text('Daftar berkas belum tercatat.', style: t.bodyMedium)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (checklist != null) ...[
                      Text(
                        '${checklist.jumlahSelesai} dari ${checklist.berkas.length} berkas siap',
                        style: t.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      BarProgres(
                        nilai: checklist.berkas.isEmpty
                            ? 0
                            : checklist.jumlahSelesai / checklist.berkas.length,
                      ),
                      const SizedBox(height: 6),
                      for (final k in checklist.berkas)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: k.selesai,
                          title: Text(k.namaBerkas),
                          onChanged: (v) async {
                            final pesan = ScaffoldMessenger.of(context);
                            try {
                              await kalender.centang(k.id, v ?? false);
                            } catch (e) {
                              pesan.showSnackBar(
                                SnackBar(content: Text(pesanGalat(e))),
                              );
                            }
                          },
                        ),
                    ] else ...[
                      for (final k in detail.berkasWajib)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.description_outlined,
                            color: Warna.primary,
                          ),
                          title: Text(k.namaBerkas),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Simpan beasiswa ini untuk mencentang berkas yang sudah siap.',
                        style: t.bodySmall,
                      ),
                    ],
                  ],
                ),
        ),
        _Bagian(
          judul: 'Rencana pendaftaran',
          anak: _RencanaDaftar(id: b.id, tersimpan: tersimpan),
        ),
        if (detail.tanggalDiperiksa != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Diperiksa terakhir ${formatTanggal(detail.tanggalDiperiksa!)} dari laman sumber resmi. Pendaftaran dilakukan di laman resmi; SMART tidak mengurus pendaftaran.',
              style: t.bodySmall,
            ),
          ),
        Text(
          'Hasil ini bantuan memilih, bukan jaminan diterima. Penyelenggara yang menentukan hasil seleksi.',
          style: t.bodySmall,
        ),
      ],
    );
  }
}

class _KotakInfo extends StatelessWidget {
  const _KotakInfo({
    required this.warnaLatar,
    required this.warnaTeks,
    required this.label,
    required this.nilai,
    this.keterangan,
  });

  final Color warnaLatar;
  final Color warnaTeks;
  final String label;
  final String nilai;
  final String? keterangan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.labelSmall?.copyWith(color: warnaTeks, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(nilai, style: t.titleMedium?.copyWith(color: warnaTeks)),
          if (keterangan != null)
            Text(keterangan!, style: t.bodySmall?.copyWith(color: warnaTeks)),
        ],
      ),
    );
  }
}

class _Bagian extends StatelessWidget {
  const _Bagian({required this.judul, required this.anak});

  final String judul;
  final Widget anak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Material(type: MaterialType.transparency, child: anak),
        ],
      ),
    );
  }
}

class _BarisSyarat extends StatelessWidget {
  const _BarisSyarat(this.p);

  final Persyaratan p;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final warna = switch (p.status) {
      'terpenuhi' => Warna.sukses,
      'dalam_toleransi' => Warna.primary,
      'gagal' => Warna.error,
      _ => Warna.outline,
    };
    final Widget tanda = switch (p.status) {
      'terpenuhi' => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(color: Warna.sukses, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, size: 16, color: Warna.putih),
      ),
      'dalam_toleransi' => Icon(Icons.schedule_rounded, size: 22, color: warna),
      'gagal' => Icon(Icons.cancel_rounded, size: 22, color: warna),
      _ => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Warna.outline, width: 1.5),
        ),
      ),
    };
    final judul = p.nilai.isEmpty ? p.label : '${p.label} ${p.nilai}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Warna.kartu,
        border: Border.all(color: Warna.container4),
        borderRadius: BorderRadius.circular(Jari.kartuDalam),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tanda,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (p.catatan != null && p.catatan!.isNotEmpty)
                  Text(
                    p.catatan!,
                    style: t.bodySmall?.copyWith(
                      color: p.status == 'terpenuhi' ? Warna.sukses : warna,
                    ),
                  ),
                if (!p.dapatDikejar && p.status != 'terpenuhi')
                  Text(
                    'Tidak dapat dikejar dalam waktu singkat',
                    style: t.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RencanaDaftar extends StatelessWidget {
  const _RencanaDaftar({required this.id, required this.tersimpan});

  final String id;
  final bool tersimpan;

  static const _opsi = [
    ('akan_daftar', 'Akan daftar'),
    ('sudah_daftar', 'Sudah daftar'),
    ('tidak_jadi', 'Tidak jadi'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (kode, label) in _opsi)
          ActionChip(
            label: Text(label),
            onPressed: () async {
              final pesan = ScaffoldMessenger.of(context);
              try {
                await Get.find<DetailController>(tag: id).rencanaDaftar(kode);
                pesan.showSnackBar(
                  SnackBar(content: Text('Rencana dicatat: $label.')),
                );
              } catch (e) {
                pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
              }
            },
          ),
      ],
    );
  }
}
