/// Settings page.
///
/// Kept deliberately small: account actions (change username entry point,
/// sign out, delete account), the blocked players list (the only way to undo
/// a block), the camera privacy statement and links to the public privacy,
/// support and external deletion pages. Notifications belong to task `08` and
/// are not shown here.
library;

import 'package:flutter/material.dart';

import '../../config/arena_config.dart';
import '../../theme/arena_tokens.dart';
import '../../domain/arena_types.dart';
import '../../battle/ui/battle_style.dart';
import '../../battle/ui/battle_widgets.dart';
import '../models/account_models.dart';
import '../runtime/account_runtime.dart';
import 'account_widgets.dart';
import 'edit_profile_page.dart';
import 'public_pages.dart';

/// Settings body.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.runtime, this.publicPages});

  final AccountRuntime runtime;

  /// Test seam for the public page links. When null the pages are resolved
  /// from the ambient [ArenaConfigScope].
  final PublicPages? publicPages;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _loadingBlocked = true;
  bool _blockedFailed = false;
  List<ArenaProfile> _blocked = const <ArenaProfile>[];

  @override
  void initState() {
    super.initState();
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    setState(() {
      _loadingBlocked = true;
      _blockedFailed = false;
    });
    try {
      final profiles = await widget.runtime.api.blocked();
      if (!mounted) {
        return;
      }
      setState(() {
        _blocked = profiles;
        _loadingBlocked = false;
      });
    } on AccountException {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingBlocked = false;
        _blockedFailed = true;
      });
    }
  }

  Future<void> _unblock(ArenaProfile profile) async {
    try {
      await widget.runtime.api.unblock(profile.id);
      await _loadBlocked();
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ArenaColors.graphite,
        title: Text(
          'Delete your account?',
          style: ArenaBattleText.h2.copyWith(color: ArenaColors.softWhite),
        ),
        content: Text(
          'This removes your profile and avatar, revokes your challenge link '
          'and cancels pending requests. This cannot be undone.',
          style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
        ),
        actions: [
          TextButton(
            key: const ValueKey('delete-account-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep account'),
          ),
          TextButton(
            key: const ValueKey('delete-account-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete account',
              style: TextStyle(color: ArenaColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await widget.runtime.controller.deleteAccount();
    } on AccountException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.runtime.controller.notice ??
                'The account could not be deleted. Try again.',
          ),
        ),
      );
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openPublicPage(PublicPages pages, Uri url) async {
    final opened = await pages.open(url);
    if (opened || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pages.configured
              ? 'The page could not be opened on this device.'
              : 'The public pages are not published for this build yet.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.runtime.controller;
    final username = controller.profile?.username;
    final pages = widget.publicPages ?? PublicPages.maybeOf(context);
    return Scaffold(
      backgroundColor: ArenaColors.charcoal,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => ListView(
            key: const ValueKey('settings-page'),
            padding: const EdgeInsets.fromLTRB(
              ArenaBattleSpace.s4,
              ArenaBattleSpace.s2,
              ArenaBattleSpace.s4,
              ArenaBattleSpace.s6,
            ),
            children: [
              const AccountPageHeader(
                title: 'Settings',
                backLabel: 'Back to Profile',
              ),
              const SizedBox(height: ArenaBattleSpace.s3),
              if (controller.notice != null) ...[
                BattleBanner(
                  key: const ValueKey('settings-notice'),
                  variant: BattleBannerVariant.info,
                  title: controller.notice!,
                ),
                const SizedBox(height: ArenaBattleSpace.s3),
              ],
              BattleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: ArenaBattleText.h3.copyWith(
                        color: ArenaColors.softWhite,
                      ),
                    ),
                    const SizedBox(height: ArenaBattleSpace.s2),
                    Text(
                      username == null || username.isEmpty
                          ? 'No username yet'
                          : '@$username',
                      style: ArenaBattleText.body.copyWith(
                        color: ArenaColors.secondary,
                      ),
                    ),
                    const SizedBox(height: ArenaBattleSpace.s3),
                    BattleSecondaryButton(
                      key: const ValueKey('settings-edit-profile'),
                      label: 'Edit profile',
                      block: true,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => EditProfilePage(
                              runtime: widget.runtime,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: ArenaBattleSpace.s2),
                    BattleSecondaryButton(
                      key: const ValueKey('settings-sign-out'),
                      label: 'Sign out',
                      block: true,
                      onPressed: controller.busy
                          ? null
                          : () async {
                              await controller.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ArenaBattleSpace.s3),
              BattleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blocked players',
                      style: ArenaBattleText.h3.copyWith(
                        color: ArenaColors.softWhite,
                      ),
                    ),
                    const SizedBox(height: ArenaBattleSpace.s2),
                    if (_loadingBlocked)
                      Text(
                        'Loading…',
                        style: ArenaBattleText.small.copyWith(
                          color: ArenaColors.secondary,
                        ),
                      )
                    else if (_blockedFailed)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'The blocked list could not be loaded.',
                              style: ArenaBattleText.small.copyWith(
                                color: ArenaColors.danger,
                              ),
                            ),
                          ),
                          BattleQuietButton(
                            label: 'Retry',
                            onPressed: _loadBlocked,
                          ),
                        ],
                      )
                    else if (_blocked.isEmpty)
                      Text(
                        'You have not blocked anyone. Blocked players cannot '
                        'send requests or meet you in ranked queue.',
                        style: ArenaBattleText.small.copyWith(
                          color: ArenaColors.secondary,
                        ),
                      )
                    else
                      for (final profile in _blocked) ...[
                        Row(
                          children: [
                            Expanded(
                              child: BattleIdentity(
                                profile: profile,
                                role: 'blocked',
                                accent: true,
                              ),
                            ),
                            BattleSecondaryButton(
                              key: ValueKey('settings-unblock-${profile.id}'),
                              label: 'Unblock',
                              onPressed: () => _unblock(profile),
                            ),
                          ],
                        ),
                        const SizedBox(height: ArenaBattleSpace.s3),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: ArenaBattleSpace.s3),
              BattleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy',
                      style: ArenaBattleText.h3.copyWith(
                        color: ArenaColors.softWhite,
                      ),
                    ),
                    const SizedBox(height: ArenaBattleSpace.s2),
                    Text(
                      'Camera frames stay on this device and are never '
                      'uploaded. Only rep counts reach the match score. Public '
                      'profile content is username, rating and an optional '
                      'avatar.',
                      style: ArenaBattleText.small.copyWith(
                        color: ArenaColors.secondary,
                      ),
                    ),
                    if (pages != null) ...[
                      const SizedBox(height: ArenaBattleSpace.s3),
                      BattleSecondaryButton(
                        key: const ValueKey('settings-privacy-policy'),
                        label: 'Privacy policy',
                        block: true,
                        onPressed: () =>
                            _openPublicPage(pages, pages.privacyUrl),
                      ),
                      const SizedBox(height: ArenaBattleSpace.s2),
                      BattleSecondaryButton(
                        key: const ValueKey('settings-support'),
                        label: 'Support',
                        block: true,
                        onPressed: () => _openPublicPage(pages, pages.supportUrl),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: ArenaBattleSpace.s3),
              BattleDangerButton(
                key: const ValueKey('settings-delete-account'),
                label: 'Delete account',
                block: true,
                onPressed: controller.busy ? null : _confirmDelete,
              ),
              if (pages != null) ...[
                const SizedBox(height: ArenaBattleSpace.s1),
                BattleQuietButton(
                  key: const ValueKey('settings-delete-account-web'),
                  label: 'Delete from the web instead',
                  onPressed: () =>
                      _openPublicPage(pages, pages.deletionRequestUrl),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
