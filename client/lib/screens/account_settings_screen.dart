import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_models.dart';
import '../models/game_stats.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/player_stats_card.dart';

class AccountSettingsScreen extends StatefulWidget {
  final bool showAsTab;

  const AccountSettingsScreen({super.key, this.showAsTab = false});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _avatarController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  DashboardSummary? _summary;
  DateTime? _dateOfBirth;
  bool _loading = true;
  bool _savingProfile = false;
  bool _sendingVerification = false;
  bool _loggingOut = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _avatarController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Bạn cần đăng nhập lại để quản lý tài khoản';
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await context.read<ApiService>().getDashboardSummary();
      if (!mounted) return;

      _summary = summary;
      _syncControllers(auth.currentUser ?? currentUser);
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _syncControllers(currentUser);
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _syncControllers(User user) {
    _fullNameController.text = user.fullName ?? '';
    _avatarController.text = user.avatar ?? '';
    _phoneController.text = user.phoneNumber ?? '';
    _bioController.text = user.bio ?? '';
    _dateOfBirth = user.dateOfBirth;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateOfBirth = picked;
    });
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _savingProfile = true;
    });

    try {
      final updatedUser = await context.read<ApiService>().updateProfile(
            fullName: _fullNameController.text.trim(),
            avatar: _avatarController.text.trim(),
            dateOfBirth: _dateOfBirth,
            phoneNumber: _phoneController.text.trim(),
            bio: _bioController.text.trim(),
          );
      if (!mounted) return;
      context.read<AuthProvider>().setCurrentUser(updatedUser);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật hồ sơ')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingProfile = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var submitting = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setModalState(() {
                submitting = true;
              });
              try {
                await context.read<ApiService>().changePassword(
                      currentPassword: currentController.text,
                      newPassword: newController.text,
                    );
                if (context.mounted) Navigator.of(context).pop(true);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              } finally {
                if (context.mounted) {
                  setModalState(() {
                    submitting = false;
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đổi mật khẩu', style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: currentController,
                      decoration:
                          const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                      obscureText: true,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nhập mật khẩu hiện tại'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: newController,
                      decoration:
                          const InputDecoration(labelText: 'Mật khẩu mới'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nhập mật khẩu mới';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: confirmController,
                      decoration: const InputDecoration(
                          labelText: 'Nhập lại mật khẩu mới'),
                      obscureText: true,
                      validator: (value) {
                        if (value != newController.text) {
                          return 'Mật khẩu xác nhận chưa khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting ? null : submit,
                        child: submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Cập nhật mật khẩu'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đổi mật khẩu thành công')),
      );
    }
  }

  Future<void> _changeEmail() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    final emailController =
        TextEditingController(text: currentUser?.email ?? '');
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var submitting = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setModalState(() {
                submitting = true;
              });
              try {
                final updatedUser =
                    await context.read<ApiService>().updateEmail(
                          newEmail: emailController.text.trim(),
                          password: passwordController.text,
                        );
                if (!context.mounted) return;
                context.read<AuthProvider>().setCurrentUser(updatedUser);
                Navigator.of(context).pop(true);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              } finally {
                if (context.mounted) {
                  setModalState(() {
                    submitting = false;
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đổi email', style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email mới'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nhập email mới';
                        }
                        if (!value.contains('@')) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: passwordController,
                      decoration:
                          const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                      obscureText: true,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nhập mật khẩu hiện tại'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sau khi đổi email, bạn cần xác minh lại email mới để tiếp tục dùng các tính năng cần xác minh.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting ? null : submit,
                        child: submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Cập nhật email'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();

    if (result == true && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Đã đổi email. Vui lòng kiểm tra hộp thư để xác minh email mới.'),
        ),
      );
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _sendingVerification = true;
    });
    try {
      await context.read<ApiService>().resendVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại email xác minh')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingVerification = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _loggingOut = true;
    });
    try {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } finally {
      if (mounted) {
        setState(() {
          _loggingOut = false;
        });
      }
    }
  }

  Widget _buildBody(User currentUser) {
    final summary = _summary;
    final stats = summary != null
        ? GameStats(
            wins: summary.stats.wins,
            losses: summary.stats.losses,
            draws: summary.stats.draws,
            eloRating: summary.stats.eloRating,
            rank: summary.stats.rank,
          )
        : GameStats(
            wins: 0,
            losses: 0,
            draws: 0,
            eloRating: currentUser.rating,
            rank: 0);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child:
                Text('Quản lý tài khoản', style: AppTextStyles.headlineMedium),
          ),
          if (!currentUser.emailVerified)
            Card(
              margin: const EdgeInsets.all(AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email chưa được xác minh',
                        style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Một số tính năng online yêu cầu email đã xác minh. Hãy kiểm tra hộp thư hoặc gửi lại email xác minh.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.tonalIcon(
                      onPressed:
                          _sendingVerification ? null : _resendVerification,
                      icon: _sendingVerification
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mark_email_unread_outlined),
                      label: const Text('Gửi lại email xác minh'),
                    ),
                  ],
                ),
              ),
            ),
          PlayerStatsCard(
            stats: stats,
            username: currentUser.fullName?.isNotEmpty == true
                ? currentUser.fullName!
                : currentUser.username,
            avatarUrl: currentUser.avatar,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _CountChip(label: 'Bạn bè', value: summary?.friendCount ?? 0),
                _CountChip(
                    label: 'Lời mời đến',
                    value: summary?.incomingRequestCount ?? 0),
                _CountChip(
                    label: 'Lời mời đi',
                    value: summary?.outgoingRequestCount ?? 0),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.all(AppSpacing.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _profileFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin cá nhân', style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      initialValue: currentUser.username,
                      enabled: false,
                      decoration:
                          const InputDecoration(labelText: 'Tên đăng nhập'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Họ và tên'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      initialValue: currentUser.email,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email hiện tại',
                        suffixIcon: currentUser.emailVerified
                            ? const Icon(Icons.verified, color: Colors.green)
                            : const Icon(Icons.error_outline,
                                color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _avatarController,
                      decoration: const InputDecoration(
                          labelText: 'Ảnh đại diện (URL)'),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) return null;
                        final uri = Uri.tryParse(trimmed);
                        if (uri == null ||
                            !uri.hasScheme ||
                            !uri.hasAuthority) {
                          return 'URL ảnh đại diện không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                          labelText: 'Số điện thoại (+84...)'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày sinh'),
                      subtitle: Text(
                        _dateOfBirth == null
                            ? 'Chưa cập nhật'
                            : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
                      ),
                      trailing: IconButton(
                        onPressed: _pickDateOfBirth,
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(labelText: 'Tiểu sử'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _savingProfile ? null : _saveProfile,
                        child: _savingProfile
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Lưu thay đổi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Đổi mật khẩu'),
                  subtitle: const Text('Cập nhật mật khẩu đăng nhập của bạn'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePassword,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: const Text('Đổi email'),
                  subtitle: const Text('Đổi email và xác minh lại địa chỉ mới'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changeEmail,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Đăng xuất'),
                  subtitle: const Text('Kết thúc phiên đăng nhập hiện tại'),
                  trailing: _loggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _loggingOut ? null : _logout,
                ),
              ],
            ),
          ),
          if (summary != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
              child: Text('Ván gần đây', style: AppTextStyles.titleLarge),
            ),
            if (summary.recentGames.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('Bạn chưa có ván đấu nào gần đây'),
                  ),
                ),
              )
            else
              ...summary.recentGames.map(
                (game) => Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: ListTile(
                    title: Text(_gameOutcomeLabel(game)),
                    subtitle: Text(
                      '${_gameTypeLabel(game.gameType)} • ${game.opponent ?? 'Chưa có đối thủ'}',
                    ),
                    trailing: Text(_formatDate(game.createdAt)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _gameOutcomeLabel(DashboardGameRecord game) {
    switch (game.outcome) {
      case 'win':
        return 'Thắng';
      case 'loss':
        return 'Thua';
      case 'draw':
        return 'Hòa';
      default:
        return game.result;
    }
  }

  String _gameTypeLabel(String gameType) {
    switch (gameType) {
      case 'chess':
        return 'Cờ vua';
      case 'caro':
        return 'Caro';
      default:
        return gameType;
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (currentUser == null) {
      body = const ErrorStateWidget(
          message: 'Bạn cần đăng nhập để quản lý tài khoản');
    } else if (_error != null && _summary == null) {
      body = ErrorStateWidget(
        message: 'Không thể tải dữ liệu tài khoản\n$_error',
        onRetry: _loadData,
      );
    } else {
      body = _buildBody(currentUser);
    }

    if (widget.showAsTab) {
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: Text('Quản lý tài khoản',
                  style: AppTextStyles.headlineMedium),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý tài khoản')),
      body: body,
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;

  const _CountChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}
