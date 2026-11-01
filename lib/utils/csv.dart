/// One CSV cell: quoted when it holds a quote, comma or line break.
String csvCell(Object? value) {
  final text = value?.toString() ?? '';
  return RegExp(r'[",\n\r]').hasMatch(text)
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

/// UTF-8's byte order mark, so Excel reads accented names correctly.
const kCsvBom = '﻿';

/// A whole CSV file: [kCsvBom], [header], then [rows], a line each.
String csvTable(List<String> header, Iterable<List<Object?>> rows) {
  final out = StringBuffer(kCsvBom)..writeln(header.map(csvCell).join(','));
  for (final row in rows) {
    out.writeln(row.map(csvCell).join(','));
  }
  return out.toString();
}
