/// Profile tab body.
///
/// The signed-in profile shows exactly the contract fields: photo/avatar,
/// username, Arena rating, ranked wins, ranked battles, **Edit profile**,
/// **Battle history** and **Settings**. Nothing else is added.
library;

import 'package:flutter/material.dart';

import '../../theme/arena_tokens.dart';
import '../../battle/ui/battle_style.dart';
import '../../battle/ui/battle_widgets.dart';
import '../runtime/account_runtime.dart';
import '../runtime/account_controller.dart';
import 'account_widgets.dart';
import 'battle_history_page.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'sign_in_flow.dart';

/// Profile tab.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = AccountRuntimeScope.maybeOf(context);
    if (runtime == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          ArenaBattleSpace.s4,
          ArenaBattleSpace.s4,
          ArenaBattleSpace.s4,
          ArenaBattleSpace.s6,
        ),
        children: [
          Text(
            'Profile',
            style: ArenaBattleText.h1.copyWith(color: ArenaColors.softWhite),
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
          const AccountEmptyPanel(
            title: 'Accounts are unavailable',
            body: 'This build has no account runtime wired.',
          ),
        ],
      );
    }
    return AnimatedBuilder(
      animation: runtime.controller,
      builder: (context, _) => _ProfileBody(runtime: runtime),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.runtime});

  final AccountRuntime runtime;

  @override
  Widget build(BuildContext context) {
    final controller = runtime.controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ArenaBattleSpace.s4,
        ArenaBattleSpace.s4,
        ArenaBattleSpace.s4,
        ArenaBattleSpace.s6,
      ),
      children: [
        Text(
          'Profile',
          style: ArenaBattleText.h1.copyWith(color: ArenaColors.softWhite),
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        if (controller.notice != null) ...[
          BattleBanner(
            key: const ValueKey('profile-notice'),
            variant: BattleBannerVariant.info,
            title: controller.notice!,
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
        ],
        switch (controller.status) {
          AccountStatus.restoring => const AccountLoadingRows(count: 2),
          AccountStatus.signedOut => _SignedOut(
              runtime: runtime,
              // This body survives replacing the signed-out controls, so the
              // username prompt keeps a mounted owner after sign-in.
              onGoogleSignIn: () {
                runGoogleSignIn(context, runtime);
              },
              onEmailSignIn: () {
                runEmailCodeSignIn(context, runtime);
              },
            ),
          AccountStatus.signedIn => _SignedIn(runtime: runtime),
        },
      ],
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.runtime});

  final AccountRuntime runtime;

  @override
  Widget build(BuildContext context) {
    final controller = runtime.controller;
    final profile = controller.profile;
    if (profile == null) {
      return AccountProblemPanel(
        key: const ValueKey('profile-load-error'),
        title: 'Could not load your profile',
        body: controller.profileError ??
            'The arena did not answer. Nothing was lost; retry.',
        onRetry: () {
          controller.refreshProfile().then<void>((_) {}, onError: (Object _) {});
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BattleCard(
          accent: ArenaColors.lime,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signed-in player',
                style: ArenaBattleText.micro.copyWith(color: ArenaColors.lime),
              ),
              const SizedBox(height: ArenaBattleSpace.s3),
              BattleIdentity(
                key: const ValueKey('profile-identity'),
                profile: profile,
                role: 'you · player',
                large: true,
              ),
              const SizedBox(height: ArenaBattleSpace.s4),
              Wrap(
                spacing: ArenaBattleSpace.s2,
                runSpacing: ArenaBattleSpace.s2,
                children: [
                  BattleChip(
                    key: const ValueKey('profile-rating'),
                    label: 'Arena rating ${profile.rating}',
                    variant: BattleChipVariant.player,
                  ),
                  BattleChip(
                    key: const ValueKey('profile-ranked-wins'),
                    label: 'Ranked wins ${profile.rankedWins}',
                  ),
                  BattleChip(
                    key: const ValueKey('profile-ranked-battles'),
                    label: 'Ranked battles ${profile.rankedBattles}',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (controller.usernameRequired) ...[
          const SizedBox(height: ArenaBattleSpace.s3),
          BattleBanner(
            key: const ValueKey('profile-username-required'),
            variant: BattleBannerVariant.warning,
            title: 'Choose a username',
            body: 'Battles and challenges need a unique username.',
            actions: <Widget>[
              BattlePrimaryButton(
                key: const ValueKey('profile-choose-username'),
                label: 'Choose username',
                onPressed: () {
                  ensureUsername(context, runtime);
                },
              ),
            ],
          ),
        ],
        if (controller.profileError != null) ...[
          const SizedBox(height: ArenaBattleSpace.s3),
          AccountProblemPanel(
            title: 'Profile refresh failed',
            body: controller.profileError!,
            onRetry: () {
              controller.refreshProfile().then<void>((_) {}, onError: (Object _) {});
            },
          ),
        ],
        const SizedBox(height: ArenaBattleSpace.s4),
        BattleSecondaryButton(
          key: const ValueKey('profile-edit'),
          label: 'Edit profile',
          block: true,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EditProfilePage(runtime: runtime),
              ),
            );
          },
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        BattleSecondaryButton(
          key: const ValueKey('profile-history'),
          label: 'Battle history',
          block: true,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BattleHistoryPage(runtime: runtime),
              ),
            );
          },
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        BattleSecondaryButton(
          key: const ValueKey('profile-settings'),
          label: 'Settings',
          block: true,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsPage(runtime: runtime),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut({
    required this.runtime,
    required this.onGoogleSignIn,
    required this.onEmailSignIn,
  });

  final AccountRuntime runtime;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onEmailSignIn;

  @override
  Widget build(BuildContext context) {
    final controller = runtime.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BattleBanner(
          key: ValueKey('profile-signed-out'),
          variant: BattleBannerVariant.info,
          title: 'Sign in to battle',
          body: 'A challenge link you opened is kept. Sign in and you return '
              'to that exact challenge; no friend search and no code typing.',
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        BattlePrimaryButton(
          key: const ValueKey('profile-sign-in-google'),
          label: 'Continue with Google',
          block: true,
          large: true,
          onPressed: controller.busy ? null : onGoogleSignIn,
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        BattleSecondaryButton(
          key: const ValueKey('profile-sign-in-email'),
          label: 'Continue with email',
          block: true,
          onPressed: controller.busy ? null : onEmailSignIn,
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        if (controller.canCancelSignIn) ...[
          BattleSecondaryButton(
            key: const ValueKey('profile-cancel-sign-in'),
            label: 'Cancel sign-in',
            block: true,
            onPressed: controller.cancelSignIn,
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
        ],
        Text(
          'Avatar upload is optional and can be added later.',
          style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
        ),
      ],
    );
  }
}
