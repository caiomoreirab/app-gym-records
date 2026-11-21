// Run from project root: dart run tools/export_visual_manifest.dart
// Produces exactly resolved paths, not guessed fallback names.
import 'dart:convert';
import 'dart:io';

import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/user_profile.dart';
import 'package:gymrecords/services/illustration_assets.dart';

void main() {
  final output = Directory('build/image-audit')..createSync(recursive: true);
  final entries = <Map<String, Object?>>[];
  final errors = <String>[];

  for (final machine in buildExerciseCatalog()) {
    for (final style in IllustrationStyle.values) {
      for (final kind in const ['execution', 'muscles']) {
        final path = kind == 'execution'
            ? IllustrationAssets.exercise(machine, style)
            : IllustrationAssets.muscle(machine, style);
        final exists = File(path).existsSync();
        final underReview =
            kind == 'execution' &&
            IllustrationAssets.needsExecutionArtworkReview(machine);
        final source = machine.id == 'plank' && kind == 'execution'
            ? 'generated_dedicated'
            : machine.visualAssetId != null
                ? 'explicit_asset_id'
                : 'shared_group_fallback';
        entries.add({
          'exerciseId': machine.id,
          'exercise': machine.name,
          'group': machine.group.name,
          'equipment': machine.equipment.name,
          'profile': style.assetFolder,
          'view': kind,
          'resolvedPath': path,
          'exists': exists,
          'source': source,
          'executionUnderReview': underReview,
          'semanticsVerifiedAutomatically': false,
        });
        if (!exists) errors.add('${machine.id}: ${style.name} / $kind: $path');
      }
    }
  }

  File('build/image-audit/exact-dart-asset-manifest.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(entries),
  );

  String quote(Object? value) {
    final content = (value ?? '').toString().replaceAll('"', '""');
    return '"$content"';
  }
  const columns = [
    'exerciseId', 'exercise', 'group', 'equipment', 'profile', 'view',
    'resolvedPath', 'exists', 'source', 'executionUnderReview',
    'semanticsVerifiedAutomatically'
  ];
  final csv = StringBuffer()..writeln(columns.map(quote).join(','));
  for (final row in entries) {
    csv.writeln(columns.map((key) => quote(row[key])).join(','));
  }
  File('build/image-audit/exact-dart-asset-manifest.csv')
      .writeAsStringSync(csv.toString());

  stdout.writeln('Exact Dart relations: ${entries.length}; missing: ${errors.length}');
  for (final error in errors) { stderr.writeln(error); }
  if (entries.length != 744 || errors.isNotEmpty) { exitCode = 1; }
}
