import 'package:flutter_test/flutter_test.dart';
import 'package:playverse/models/user.dart';

void main() {
  test('User.fromJson parses emailVerified and zero date as null', () {
    final user = User.fromJson(const {
      'id': 'u1',
      'username': 'alice',
      'email': 'alice@example.com',
      'role': 'player',
      'email_verified': true,
      'is_banned': false,
      'games_played': 3,
      'games_won': 2,
      'rating': 1205,
      'date_of_birth': '0001-01-01T00:00:00Z',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-02T00:00:00Z',
    });

    expect(user.emailVerified, isTrue);
    expect(user.dateOfBirth, isNull);
    expect(user.rating, 1205);
  });
}
