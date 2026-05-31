import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_models.dart';
import '../providers/social_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';

class FriendsScreen extends StatefulWidget {
  final bool showAsTab;

  const FriendsScreen({super.key, this.showAsTab = false});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadSocial();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Consumer<SocialProvider>(
      builder: (context, social, _) {
        if (social.loading &&
            social.friends.isEmpty &&
            social.players.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (social.error != null &&
            social.friends.isEmpty &&
            social.players.isEmpty) {
          return ErrorStateWidget(
            message: 'Không thể tải bạn bè\n${social.error}',
            onRetry: () => social.loadSocial(query: _searchController.text),
          );
        }

        return RefreshIndicator(
          onRefresh: () => social.loadSocial(query: _searchController.text),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm người chơi theo username',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () =>
                        social.loadSocial(query: _searchController.text),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => social.loadSocial(query: value),
              ),
              if (social.error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(social.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('Lời mời đến', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              if (social.incoming.isEmpty)
                const _SectionHint(text: 'Không có lời mời đang chờ')
              else
                ...social.incoming.map((request) => _RequestCard(
                      request: request,
                      incoming: true,
                    )),
              const SizedBox(height: AppSpacing.lg),
              Text('Bạn bè', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              if (social.friends.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: 'Chưa có bạn bè',
                  subtitle: 'Tìm người chơi và gửi lời mời kết bạn.',
                )
              else
                ...social.friends
                    .map((friendship) => _FriendCard(friendship: friendship)),
              const SizedBox(height: AppSpacing.lg),
              Text('Kết quả tìm kiếm', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              if (social.players.isEmpty)
                const _SectionHint(text: 'Nhập username để tìm người chơi')
              else
                ...social.players.map((player) => _PlayerCard(player: player)),
              if (social.outgoing.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Đã gửi', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                ...social.outgoing.map((request) => _RequestCard(
                      request: request,
                      incoming: false,
                    )),
              ],
            ],
          ),
        );
      },
    );

    if (widget.showAsTab) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Text('Bạn bè', style: AppTextStyles.headlineMedium),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bạn bè')),
      body: body,
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final PlayerSummary player;

  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _Avatar(player: player),
        title: Text(player.username),
        subtitle: Text(
            '${player.eloRating} Elo • ${_statusLabel(player.friendStatus)}'),
        trailing: _ActionButton(player: player),
        onTap: () => Navigator.pushNamed(
          context,
          '/opponent_profile',
          arguments: player.id,
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final FriendshipSummary friendship;

  const _FriendCard({required this.friendship});

  @override
  Widget build(BuildContext context) {
    final friend = friendship.friend;
    return Card(
      child: ListTile(
        leading: _Avatar(player: friend),
        title: Text(friend.username),
        subtitle: const Text(
            'Mời vào phòng sẽ khả dụng khi trạng thái online sẵn sàng'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'remove') {
              context.read<SocialProvider>().removeFriend(friend.id);
            } else if (value == 'profile') {
              Navigator.pushNamed(context, '/opponent_profile',
                  arguments: friend.id);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'profile', child: Text('Xem hồ sơ')),
            PopupMenuItem(value: 'remove', child: Text('Xóa bạn')),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final FriendRequestSummary request;
  final bool incoming;

  const _RequestCard({required this.request, required this.incoming});

  @override
  Widget build(BuildContext context) {
    final player = incoming ? request.requester : request.recipient;
    return Card(
      child: ListTile(
        leading: _Avatar(player: player),
        title: Text(player.username),
        subtitle: Text(incoming ? 'Muốn kết bạn với bạn' : 'Đang chờ phản hồi'),
        trailing: incoming
            ? Wrap(
                spacing: AppSpacing.xs,
                children: [
                  IconButton(
                    tooltip: 'Chấp nhận',
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => context
                        .read<SocialProvider>()
                        .acceptRequest(request.id),
                  ),
                  IconButton(
                    tooltip: 'Từ chối',
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => context
                        .read<SocialProvider>()
                        .rejectRequest(request.id),
                  ),
                ],
              )
            : TextButton(
                onPressed: () =>
                    context.read<SocialProvider>().cancelRequest(request.id),
                child: const Text('Hủy'),
              ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final PlayerSummary player;

  const _ActionButton({required this.player});

  @override
  Widget build(BuildContext context) {
    switch (player.friendStatus) {
      case 'friends':
        return const Chip(label: Text('Bạn bè'));
      case 'pending_incoming':
        return TextButton(
          onPressed: player.friendRequestId == null
              ? null
              : () => context
                  .read<SocialProvider>()
                  .acceptRequest(player.friendRequestId!),
          child: const Text('Chấp nhận'),
        );
      case 'pending_outgoing':
        return const Chip(label: Text('Đã gửi'));
      case 'self':
        return const SizedBox.shrink();
      default:
        return TextButton(
          onPressed: () =>
              context.read<SocialProvider>().sendRequest(player.id),
          child: const Text('Kết bạn'),
        );
    }
  }
}

class _Avatar extends StatelessWidget {
  final PlayerSummary player;

  const _Avatar({required this.player});

  @override
  Widget build(BuildContext context) {
    final avatar = player.avatar ?? '';
    return CircleAvatar(
      backgroundImage: avatar.isEmpty ? null : NetworkImage(avatar),
      child: avatar.isEmpty
          ? Text(
              player.username.isEmpty ? '?' : player.username[0].toUpperCase())
          : null,
    );
  }
}

class _SectionHint extends StatelessWidget {
  final String text;

  const _SectionHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'friends':
      return 'Bạn bè';
    case 'pending_incoming':
      return 'Đã gửi lời mời cho bạn';
    case 'pending_outgoing':
      return 'Đang chờ phản hồi';
    case 'self':
      return 'Bạn';
    default:
      return 'Chưa kết bạn';
  }
}
