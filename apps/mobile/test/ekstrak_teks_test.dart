import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/lokal/ekstrak_teks.dart';
import 'package:smart_mobile/features/chat/data/chat_repository.dart';

Uint8List _zip(Map<String, String> isi) {
  final a = Archive();
  isi.forEach((n, t) {
    final b = utf8.encode(t);
    a.addFile(ArchiveFile(n, b.length, b));
  });
  return Uint8List.fromList(ZipEncoder().encode(a));
}

void main() {
  lampiranTes();
  test('teks biasa, csv, dan json dibaca apa adanya', () {
    expect(teksDariBytes('txt', Uint8List.fromList(utf8.encode('Halo dunia\n\n\n\nBaris'))), 'Halo dunia\n\nBaris');
    expect(teksDariBytes('csv', Uint8List.fromList(utf8.encode('nama,ipk\nAdam,3.55'))), contains('Adam,3.55'));
    expect(teksDariBytes('json', Uint8List.fromList(utf8.encode('{"a":1}'))), '{"a":1}');
  });

  test('docx: paragraf dan tabel', () {
    const xml =
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>'
        '<w:p><w:r><w:t>Nabila Putri</w:t></w:r></w:p>'
        '<w:p><w:r><w:t>IPK </w:t></w:r><w:r><w:t>3,72</w:t></w:r></w:p>'
        '<w:tbl><w:tr><w:tc><w:p><w:r><w:t>Organisasi</w:t></w:r></w:p></w:tc><w:tc><w:p><w:r><w:t>BEM</w:t></w:r></w:p></w:tc></w:tr></w:tbl>'
        '</w:body></w:document>';
    final t = teksDariBytes('docx', _zip({'word/document.xml': xml}));
    expect(t, contains('Nabila Putri'));
    expect(t, contains('IPK 3,72'));
    expect(t, contains('Organisasi'));
    expect(t, contains('BEM'));
  });

  test('pptx: slide berurutan numerik', () {
    String s(String x) =>
        '<p:sld xmlns:p="p" xmlns:a="a"><a:p><a:r><a:t>$x</a:t></a:r></a:p></p:sld>';
    final t = teksDariBytes('pptx', _zip({
      'ppt/slides/slide10.xml': s('Sepuluh'),
      'ppt/slides/slide2.xml': s('Dua'),
      'ppt/slides/slide1.xml': s('Satu'),
    }));
    expect(t.indexOf('Satu'), lessThan(t.indexOf('Dua')));
    expect(t.indexOf('Dua'), lessThan(t.indexOf('Sepuluh')));
    expect(t, contains('--- Slide 2 ---'));
  });

  test('xlsx: string bersama, angka, dan nama lembar', () {
    final t = teksDariBytes('xlsx', _zip({
      'xl/workbook.xml': '<workbook><sheets><sheet name="Nilai" sheetId="1"/></sheets></workbook>',
      'xl/sharedStrings.xml': '<sst><si><t>Mata kuliah</t></si><si><t>Nilai</t></si><si><t>Basis Data</t></si></sst>',
      'xl/worksheets/sheet1.xml':
          '<worksheet><sheetData>'
          '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c></row>'
          '<row r="2"><c r="A2" t="s"><v>2</v></c><c r="B2"><v>95</v></c></row>'
          '</sheetData></worksheet>',
    }));
    expect(t, contains('--- Lembar Nilai ---'));
    expect(t, contains('Mata kuliah\tNilai'));
    expect(t, contains('Basis Data\t95'));
  });

  test('odt dan epub dibaca', () {
    final odt = teksDariBytes('odt', _zip({
      'content.xml':
          '<office:document-content xmlns:office="o" xmlns:text="t"><office:body><office:text>'
          '<text:h>Judul</text:h><text:p>Isi <text:s/>paragraf</text:p></office:text></office:body></office:document-content>',
    }));
    expect(odt, contains('Judul'));
    expect(odt, matches(RegExp(r'Isi\s+paragraf')));
    final epub = teksDariBytes('epub', _zip({
      'OEBPS/bab1.xhtml': '<html><body><h1>Bab Satu</h1><p>Isi &amp; arti</p></body></html>',
    }));
    expect(epub, contains('Bab Satu'));
    expect(epub, contains('Isi & arti'));
  });

  test('html dan rtf dibersihkan', () {
    final h = teksDariHtml('<html><head><style>x{}</style></head><body><p>Satu&nbsp;dua</p><script>bad()</script><p>Tiga &#65;</p></body></html>');
    expect(h, contains('Satu dua'));
    expect(h, contains('Tiga A'));
    expect(h, isNot(contains('bad')));
    final r = teksDariRtf(r'{\rtf1\ansi{\fonttbl{\f0 Arial;}}\f0 Halo\par Dunia \b baru\b0}');
    expect(r, contains('Halo'));
    expect(r, contains('Dunia'));
    expect(r, isNot(contains('rtf1')));
  });

  test('format lama dan tak dikenal ditolak dengan pesan jelas', () {
    expect(() => teksDariBytes('doc', Uint8List(4)), throwsA(isA<EkstrakGagal>()));
    expect(() => teksDariBytes('xyz', Uint8List(4)), throwsA(isA<EkstrakGagal>()));
    expect(() => teksDariBytes('docx', Uint8List.fromList([1, 2, 3])), throwsA(isA<EkstrakGagal>()));
  });

  test('potongRelevan memuat awal dan bagian yang berkaitan dengan pertanyaan', () {
    final teks = '${'Identitas Nabila Putri. ' * 40}${'Pengalaman magang di bank. ' * 100}'
        '${'Sertifikat IELTS 7.0 dari British Council. ' * 30}${'Hobi membaca. ' * 100}';
    final p = potongRelevan(teks, 'Berapa skor IELTS saya?', batas: 3000);
    expect(p.length, lessThanOrEqualTo(3100));
    expect(p, startsWith('Identitas Nabila Putri'));
    expect(p, contains('IELTS 7.0'));
    expect(potongRelevan('pendek', 'apa saja', batas: 3000), 'pendek');
  });
}

void lampiranTes() {
  group('penanda lampiran', () {
    test('memisahkan nama berkas dari teks pesan', () {
      final p = pisahLampiran('Berapa IPK saya?\n[Lampiran: cv a.pdf; nilai, akhir.xlsx]');
      expect(p.teks, 'Berapa IPK saya?');
      expect(p.nama, ['cv a.pdf', 'nilai, akhir.xlsx']);
    });
    test('pesan biasa tidak berubah', () {
      final p = pisahLampiran('Halo [bukan lampiran] dunia');
      expect(p.teks, 'Halo [bukan lampiran] dunia');
      expect(p.nama, isEmpty);
    });
  });
}
