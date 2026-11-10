import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/metrik_dan_progres.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../kalender/presentation/kalender_providers.dart';
import '../../rekomendasi/domain/rekomendasi.dart';
import '../domain/beasiswa.dart';
import 'beasiswa_providers.dart';
import 'simpan_aksi.dart';

/// Pembuka tautan luar; diganti pada uji.
final bukaTautanProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.id});

  final String id;

  Future<void> _bukaPortal(
    BuildContext context,
    WidgetRef ref,
    BeasiswaRingkas b,
  ) async {
    final pesan = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(b.tautanResmi);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      pesan.showSnackBar(
        const SnackBar(content: Text('Tautan resmi tidak valid.')),
      );
      return;
    }
    try {
      await ref.read(beasiswaRepositoryProvider).catatKlik(b.id);
    } catch (_) {
      // Pencatatan klik tidak boleh menghalangi pembukaan tautan.
    }
    final ok = await ref.read(bukaTautanProvider)(uri);
    if (!ok) {
      pesan.showSnackBar(
        const SnackBar(content: Text('Tautan tidak dapat dibuka.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nilai = ref.watch(detailBeasiswaProvider(id));
    final tersimpan = ref.watch(tersimpanProvider).value?.contains(id) ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Beasiswa')),
      body: AsyncIsi<BeasiswaDetail>(
        nilai: nilai,
        ulang: () => ref.invalidate(detailBeasiswaProvider(id)),
        bangun: (d) => _Isi(detail: d, tersimpan: tersimpan),
      ),
      bottomNavigationBar: nilai.hasValue
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: Warna.kartu,
                border: Border(top: BorderSide(color: Warna.outline)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: tersimpan ? 'Hapus dari tersimpan' : 'Simpan',
                        child: OutlinedButton(
                          onPressed: () => ubahSimpan(
                            context,
                            ref,
                            id,
                            tersimpan: tersimpan,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(52, 52),
                            padding: EdgeInsets.zero,
                          ),
                          child: Icon(
                            tersimpan
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _bukaPortal(context, ref, nilai.value!.ringkas),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Kunjungi Laman Resmi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.detail, required this.tersimpan});

  final BeasiswaDetail detail;
  final bool tersimpan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final b = detail.ringkas;
    final tenggat = b.tenggat;
    final sisa = tenggat == null ? null : sisaHari(tenggat);
    final meta = [
      if ((b.penyelenggara ?? '').isNotEmpty) b.penyelenggara!,
      if ((b.negara ?? '').isNotEmpty) b.negara!,
    ].join(' · ');
    final checklist = ref
        .watch(checklistProvider)
        .value
        ?.where((c) => c.beasiswa.id == b.id)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (detail.kategori != null)
              ChipStatus.kategori(Kategori.dari(detail.kategori!)),
            if ((b.jenjang ?? '').isNotEmpty) ChipStatus(label: b.jenjang!),
            if (meta.isNotEmpty) ChipStatus(label: meta),
          ],
        ),
        const SizedBox(height: 12),
        Text(b.nama, style: t.headlineMedium?.copyWith(fontSize: 24)),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KotakInfo(
                  warnaLatar: sisa != null && sisa <= 7
                      ? Warna.errorSoft
                      : Warna.container2,
                  warnaTeks: sisa != null && sisa <= 7
                      ? Warna.error
                      : Warna.navy,
                  label: 'TENGGAT PENDAFTARAN',
                  nilai: tenggat == null
                      ? 'Belum diumumkan'
                      : formatTanggal(tenggat),
                  keterangan: teksSisaHari(tenggat),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KotakInfo(
                  warnaLatar: Warna.container1,
                  warnaTeks: Warna.navy,
                  label: 'DIPERIKSA TERAKHIR',
                  nilai: detail.tanggalDiperiksa == null
                      ? 'Belum tercatat'
                      : formatTanggal(detail.tanggalDiperiksa!),
                  keterangan: 'Dari laman sumber resmi',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: Warna.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pendaftaran dilakukan di laman resmi. SMART tidak mengurus pendaftaran, jadi periksa kembali syarat dan tenggat di sana.',
                style: t.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Bagian(
          judul: 'Manfaat',
          anak: Text(
            (detail.manfaat ?? '').trim().isEmpty
                ? 'Rincian manfaat belum tercatat. Lihat laman resmi.'
                : detail.manfaat!,
            style: t.bodyMedium,
          ),
        ),
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
        if (detail.alasan.isNotEmpty || detail.catatanKekurangan.isNotEmpty)
          _Bagian(
            judul: 'Alasan rekomendasi',
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in detail.alasan)
                  _BarisAlasan(a, Icons.check_circle_rounded, Warna.sukses),
                for (final a in detail.catatanKekurangan)
                  _BarisAlasan(a, Icons.info_rounded, Warna.error),
                const SizedBox(height: 4),
                Text(
                  'Hasil ini bantuan memilih, bukan jaminan diterima.',
                  style: t.bodySmall,
                ),
              ],
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
                              await ref
                                  .read(kalenderRepositoryProvider)
                                  .centang(k.id, v ?? false);
                              ref.invalidate(checklistProvider);
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
          anak: _RencanaDaftar(id: b.id, tersimpan: tersimpan, ref: ref),
        ),
        Text(
          'Rekomendasi SMART hanya membantu menyaring; penyelenggara yang menentukan hasil seleksi.',
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
    required this.keterangan,
  });

  final Color warnaLatar;
  final Color warnaTeks;
  final String label;
  final String nilai;
  final String keterangan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(Jari.kartuDalam),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.labelSmall?.copyWith(color: warnaTeks)),
          const SizedBox(height: 6),
          Text(nilai, style: t.titleSmall?.copyWith(color: warnaTeks)),
          const SizedBox(height: 2),
          Text(keterangan, style: t.bodySmall?.copyWith(color: warnaTeks)),
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        boxShadow: bayanganKartu,
      ),
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

class _BarisAlasan extends StatelessWidget {
  const _BarisAlasan(this.teks, this.ikon, this.warna);

  final String teks;
  final IconData ikon;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 20, color: warna),
          const SizedBox(width: 10),
          Expanded(
            child: Text(teks, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _BarisSyarat extends StatelessWidget {
  const _BarisSyarat(this.p);

  final Persyaratan p;

  (IconData, Color) get _tanda => switch (p.status) {
    'terpenuhi' => (Icons.check_circle_rounded, Warna.sukses),
    'dalam_toleransi' => (Icons.schedule_rounded, Warna.primary),
    'gagal' => (Icons.cancel_rounded, Warna.error),
    _ => (Icons.radio_button_unchecked_rounded, Warna.muted),
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (ikon, warna) = _tanda;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Warna.outline),
        borderRadius: BorderRadius.circular(Jari.kartuDalam),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(ikon, size: 22, color: warna),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.label, style: t.titleSmall),
                if (p.nilai.isNotEmpty) Text(p.nilai, style: t.bodyMedium),
                if (p.catatan != null && p.catatan!.isNotEmpty)
                  Text(p.catatan!, style: t.bodySmall?.copyWith(color: warna)),
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
  const _RencanaDaftar({
    required this.id,
    required this.tersimpan,
    required this.ref,
  });

  final String id;
  final bool tersimpan;
  final WidgetRef ref;

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
                await ref
                    .read(beasiswaRepositoryProvider)
                    .rencanaDaftar(id, kode);
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
