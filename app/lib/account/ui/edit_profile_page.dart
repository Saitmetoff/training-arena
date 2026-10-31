/// Edit profile page.
///
/// Username changes go through the backend unique index (race-safe) and
/// avatar uploads accept only the backend's safe image limits
/// (JPEG/PNG/WebP, max 2 MB) from the document picker — never camera frames.
/// Both keep remove and retry paths.
library;

import 'package:flutter/material.dart';

import '../../theme/arena_tokens.dart';
import '../../battle/ui/battle_style.dart';
import '../../battle/ui/battle_widgets.dart';
import '../models/account_models.dart';
import '../runtime/account_runtime.dart';
import 'account_widgets.dart';

/// Edit profile body.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.runtime});

  final AccountRuntime runtime;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _usernameController;
  String? _usernameError;
  bool _savingUsername = false;

  AvatarUpload? _pendingUpload;
  bool _uploading = false;
  String? _avatarError;
  bool _avatarRetryable = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.runtime.controller.profile?.username ?? '',
    );
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    if (_usernameError != null) {
      setState(() => _usernameError = null);
    } else {
      setState(() {});
    }
  }

  bool get _usernameUnchanged {
    final current = widget.runtime.controller.profile?.username;
    final value = ArenaUsername.normalize(_usernameController.text);
    if (current == null || current.isEmpty) {
      return false;
    }
    return ArenaUsername.isSame(current, value);
  }

  String? get _liveUsernameError =>
      ArenaUsername.validationMessage(_usernameController.text);

  Future<void> _saveUsername() async {
    final invalid = _liveUsernameError;
    if (invalid != null) {
      setState(() => _usernameError = invalid);
      return;
    }
    setState(() {
      _savingUsername = true;
      _usernameError = null;
    });
    try {
      await widget.runtime.controller
          .claimUsername(_usernameController.text);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username saved.')),
      );
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _usernameError = error.message);
    } finally {
      if (mounted) {
        setState(() => _savingUsername = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    setState(() {
      _uploading = true;
      _avatarError = null;
      _avatarRetryable = false;
    });
    try {
      final upload = await widget.runtime.avatarPicker.pickFromLibrary();
      if (upload == null) {
        return;
      }
      _pendingUpload = upload;
      await widget.runtime.controller.updateAvatar(upload);
      _pendingUpload = null;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated.')),
      );
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarError = error.message;
        _avatarRetryable = error.isRetryable;
      });
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _retryAvatar() async {
    final upload = _pendingUpload;
    if (upload == null) {
      await _pickAvatar();
      return;
    }
    setState(() {
      _uploading = true;
      _avatarError = null;
    });
    try {
      await widget.runtime.controller.updateAvatar(upload);
      _pendingUpload = null;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated.')),
      );
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarError = error.message;
        _avatarRetryable = error.isRetryable;
      });
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _uploading = true;
      _avatarError = null;
      _pendingUpload = null;
    });
    try {
      await widget.runtime.controller.removeAvatar();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo removed.')),
      );
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarError = error.message;
        _avatarRetryable = false;
      });
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.runtime.controller;
    final profile = controller.profile;
    return Scaffold(
      backgroundColor: ArenaColors.charcoal,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => ListView(
            key: const ValueKey('edit-profile-page'),
            padding: const EdgeInsets.fromLTRB(
              ArenaBattleSpace.s4,
              ArenaBattleSpace.s2,
              ArenaBattleSpace.s4,
              ArenaBattleSpace.s6,
            ),
            children: [
              const AccountPageHeader(
                title: 'Edit profile',
                backLabel: 'Back to Profile',
              ),
              const SizedBox(height: ArenaBattleSpace.s3),
              if (profile == null)
                const AccountEmptyPanel(
                  title: 'Sign in required',
                  body: 'Sign in to edit your profile.',
                )
              else ...[
                BattleCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photo',
                        style: ArenaBattleText.h3.copyWith(
                          color: ArenaColors.softWhite,
                        ),
                      ),
                      const SizedBox(height: ArenaBattleSpace.s3),
                      BattleIdentity(profile: profile, large: true),
                      const SizedBox(height: ArenaBattleSpace.s3),
                      Wrap(
                        spacing: ArenaBattleSpace.s2,
                        runSpacing: ArenaBattleSpace.s2,
                        children: [
                          BattlePrimaryButton(
                            key: const ValueKey('edit-avatar-upload'),
                            label: _uploading ? 'Working…' : 'Upload photo',
                            onPressed: _uploading ? null : _pickAvatar,
                          ),
                          if (_avatarRetryable)
                            BattleSecondaryButton(
                              key: const ValueKey('edit-avatar-retry'),
                              label: 'Retry upload',
                              onPressed: _uploading ? null : _retryAvatar,
                            ),
                          if (profile.avatarUrl != null)
                            BattleDangerButton(
                              key: const ValueKey('edit-avatar-remove'),
                              label: 'Remove photo',
                              onPressed: _uploading ? null : _removeAvatar,
                            ),
                        ],
                      ),
                      const SizedBox(height: ArenaBattleSpace.s2),
                      Text(
                        'JPEG, PNG or WebP up to 2 MB. Photos come from your '
                        'files; the camera is never used for avatars.',
                        style: ArenaBattleText.small.copyWith(
                          color: ArenaColors.quiet,
                        ),
                      ),
                      if (_avatarError != null) ...[
                        const SizedBox(height: ArenaBattleSpace.s2),
                        Text(
                          _avatarError!,
                          key: const ValueKey('edit-avatar-error'),
                          style: ArenaBattleText.small.copyWith(
                            color: ArenaColors.danger,
                          ),
                        ),
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
                        'Username',
                        style: ArenaBattleText.h3.copyWith(
                          color: ArenaColors.softWhite,
                        ),
                      ),
                      const SizedBox(height: ArenaBattleSpace.s2),
                      Text(
                        '3–20 letters, digits or underscore. It must be '
                        'unique; the server decides that.',
                        style: ArenaBattleText.small.copyWith(
                          color: ArenaColors.secondary,
                        ),
                      ),
                      const SizedBox(height: ArenaBattleSpace.s3),
                      TextField(
                        key: const ValueKey('edit-username-field'),
                        controller: _usernameController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveUsername(),
                        style: ArenaBattleText.body.copyWith(
                          color: ArenaColors.softWhite,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: ArenaBattleText.small.copyWith(
                            color: ArenaColors.secondary,
                          ),
                          filled: true,
                          fillColor: ArenaColors.raised,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ArenaBattleSpace.radiusControl,
                            ),
                            borderSide: const BorderSide(
                              color: ArenaColors.lineStrong,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ArenaBattleSpace.radiusControl,
                            ),
                            borderSide: const BorderSide(
                              color: ArenaColors.lime,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      if (_usernameError != null) ...[
                        const SizedBox(height: ArenaBattleSpace.s2),
                        Text(
                          _usernameError!,
                          key: const ValueKey('edit-username-error'),
                          style: ArenaBattleText.small.copyWith(
                            color: ArenaColors.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: ArenaBattleSpace.s3),
                      BattlePrimaryButton(
                        key: const ValueKey('edit-username-save'),
                        label: 'Save username',
                        block: true,
                        onPressed: _savingUsername ||
                                _liveUsernameError != null ||
                                _usernameUnchanged
                            ? null
                            : _saveUsername,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
