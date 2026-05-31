import 'package:flutter_test/flutter_test.dart';
import 'package:playverse/models/dashboard_models.dart';

void main() {
  test('DashboardSummary parses profile, stats, and recent games', () {
    final summary = DashboardSummary.fromJson({
      'profile': {
        'id': 'u1',
        'username': 'alice',
        'elo_rating': 1234,
        'rank': 2,
        'friend_status': 'self',
      },
      'stats': {
        'game_type': 'caro',
        'wins': 3,
        'losses': 1,
        'draws': 2,
        'elo_rating': 1234,
        'rank': 2,
      },
      'recent_games': [
        {
          'id': 'g1',
          'game_type': 'caro',
          'room_id': 'r1',
          'result': 'win',
          'winner': 'u1',
          'opponent': 'u2',
          'outcome': 'win',
          'created_at': '2026-05-31T00:00:00Z',
        }
      ],
      'friend_count': 4,
      'incoming_request_count': 1,
      'outgoing_request_count': 2,
    });

    expect(summary.profile.username, 'alice');
    expect(summary.stats.gameType, 'caro');
    expect(summary.stats.wins, 3);
    expect(summary.recentGames.single.gameType, 'caro');
    expect(summary.recentGames.single.outcome, 'win');
    expect(summary.friendCount, 4);
    expect(summary.incomingRequestCount, 1);
    expect(summary.outgoingRequestCount, 2);
  });

  test('FriendRequestSummary parses nested users safely', () {
    final request = FriendRequestSummary.fromJson({
      'id': 'req1',
      'status': 'pending',
      'requester_id': 'u1',
      'recipient_id': 'u2',
      'requester': {'id': 'u1', 'username': 'alice'},
      'recipient': {'id': 'u2', 'username': 'bob'},
      'created_at': '2026-05-31T00:00:00Z',
    });

    expect(request.requester.username, 'alice');
    expect(request.recipient.username, 'bob');
    expect(request.status, 'pending');
  });
}
