import 'package:flutter_test/flutter_test.dart';
import 'package:playverse/models/game_catalog.dart';

void main() {
  test('GameCatalogEntry parses Caro catalog contract', () {
    final entry = GameCatalogEntry.fromJson({
      'game_type': 'caro',
      'name': 'PlayVerse',
      'description': 'Caro 15x15',
      'status': 'active',
      'min_players': 1,
      'max_players': 2,
      'supports_online': true,
      'supports_offline': true,
      'supports_ai': true,
    });

    expect(entry.gameType, 'caro');
    expect(entry.isActive, isTrue);
    expect(entry.supportsOnline, isTrue);
    expect(entry.supportsAI, isTrue);
  });
}
