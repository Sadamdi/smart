import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Menampilkan jawaban AI sebagai teks beraturan (judul, huruf tebal dan miring, daftar, tabel, kutipan, kode, tautan),
/// bukan teks mentah. Tautan hanya http dan https yang dibuka di peramban.
class TeksMarkdown extends StatelessWidget {
  const TeksMarkdown(this.teks, {super.key, this.warna});

  final String teks;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dasar = (t.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 14,
      height: 1.5,
      color: warna,
    );
    return MarkdownBody(
      data: teks,
      selectable: true,
      softLineBreak: true,
      onTapLink: (_, href, _) async {
        final u = href == null ? null : Uri.tryParse(href);
        if (u != null && (u.scheme == 'https' || u.scheme == 'http')) {
          await launchUrl(u, mode: LaunchMode.externalApplication);
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: dasar,
        strong: dasar.copyWith(fontWeight: FontWeight.w800),
        em: dasar.copyWith(fontStyle: FontStyle.italic),
        h1: dasar.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
        h2: dasar.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
        h3: dasar.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        listBullet: dasar.copyWith(color: Warna.primary),
        a: dasar.copyWith(
          color: Warna.primary,
          decoration: TextDecoration.underline,
        ),
        code: dasar.copyWith(
          fontFamily: 'monospace',
          fontSize: 12.5,
          backgroundColor: Warna.container2,
        ),
        codeblockDecoration: BoxDecoration(
          color: Warna.container2,
          borderRadius: BorderRadius.circular(10),
        ),
        blockquote: dasar.copyWith(color: Warna.muted),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: Warna.primary, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.only(left: 10),
        tableBorder: TableBorder.all(color: Warna.container4, width: 1),
        tableHead: dasar.copyWith(fontWeight: FontWeight.w700),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: Warna.container4)),
        ),
        pPadding: const EdgeInsets.only(bottom: 4),
      ),
    );
  }
}
