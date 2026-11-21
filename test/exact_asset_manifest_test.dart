import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../tools/export_visual_manifest.dart' as visual_manifest;

void main() {
  test('exporta 744 caminhos reais de imagens do Flutter', () {
    visual_manifest.main();
    final jsonFile = File('build/image-audit/exact-dart-asset-manifest.json');
    expect(jsonFile.existsSync(), isTrue);
    final rows = jsonDecode(jsonFile.readAsStringSync()) as List<dynamic>;
    expect(rows, hasLength(744));
    expect(rows.every((row) => row['exists'] == true), isTrue);
  });
}
