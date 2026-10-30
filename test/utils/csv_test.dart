import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/csv.dart';

void main() {
  test('a cell is quoted only when it must be', () {
    expect(csvCell(null), '');
    expect(csvCell(12), '12');
    expect(csvCell('Kick 15.wav'), 'Kick 15.wav');
    expect(csvCell('a, b'), '"a, b"');
    expect(csvCell('say "hi"'), '"say ""hi"""');
    expect(csvCell('two\nlines'), '"two\nlines"');
  });

  test('a table starts with the BOM and the header', () {
    expect(csvTable(['a', 'b'], [
      [1, 'x,y'],
      [null, 2],
    ]), '\uFEFFa,b\n1,"x,y"\n,2\n');
  });
}
