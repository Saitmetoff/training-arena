/// Sign-in flow widgets and prompt adapters.
///
/// Google sign-in opens the provider directly. Email sign-in collects the
/// address and the emailed code, then any missing username, in the smallest
/// possible number of steps. Every step is cancellable and every failure uses
/// plain copy from [AccountException]; no address or token is echoed in the
/// UI or in errors.
library;

import 'package:flutter/material.dart';

import '../../theme/arena_tokens.dart';
import '../../battle/ui/battle_style.dart';
import '../../battle/ui/battle_widgets.dart';
import '../challenge/auth_prompts.dart';
import '../models/account_models.dart';
import '../runtime/account_runtime.dart';

/// Runs Google sign-in, then the username step when the backend has none.
Future<void> runGoogleSignIn(
  BuildContext context,
  AccountRuntime runtime,
) async {
  try {
    await runtime.controller.signInWithGoogle();
  } on AccountException {
    return;
  }
  if (!context.mounted) {
    return;
  }
  if (runtime.controller.usernameRequired) {
    await ensureUsername(context, runtime);
  }
}

/// Runs email-code sign-in with prompts, then the username step.
Future<void> runEmailCodeSignIn(
  BuildContext context,
  AccountRuntime runtime,
) async {
  final controller = runtime.controller;
  final email = await showEmailPromptSheet(context);
  if (email == null || !context.mounted) {
    return;
  }
  try {
    await controller.requestEmailCode(email);
  } on AccountException {
    return;
  }
  if (!context.mounted) {
    return;
  }
  final code = await showCodePromptSheet(context);
  if (code == null) {
    return;
  }
  try {
    await controller.verifyEmailCode(email: email, code: code);
  } on AccountException {
    return;
  }
  if (!context.mounted) {
    return;
  }
  if (controller.usernameRequired) {
    await ensureUsername(context, runtime);
  }
}

/// Claims a username, re-prompting with the server's actionable message until
/// it succeeds or the user cancels. Uniqueness is owned by the backend.
Future<bool> ensureUsername(
  BuildContext context,
  AccountRuntime runtime,
) async {
  final controller = runtime.controller;
  String? message;
  var attempts = 0;
  while (controller.usernameRequired) {
    if (attempts >= 4) {
      return false;
    }
    attempts += 1;
    if (!context.mounted) {
      return false;
    }
    final raw = await showUsernameClaimSheet(context, message: message);
    if (raw == null || !context.mounted) {
      return false;
    }
    try {
      await controller.claimUsername(raw);
      message = null;
    } on AccountException catch (error) {
      message = error.message;
    }
  }
  return true;
}

/// Real prompt adapter used by the challenge sign-in route.
class NavigatorChallengeAuthPrompts implements ChallengeAuthPrompts {
  const NavigatorChallengeAuthPrompts(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  BuildContext? get _context {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return null;
    }
    return context;
  }

  @override
  Future<String?> requestEmail() async {
    final context = _context;
    if (context == null) {
      return null;
    }
    return showEmailPromptSheet(context);
  }

  @override
  Future<String?> requestCode(String email) async {
    final context = _context;
    if (context == null) {
      return null;
    }
    return showCodePromptSheet(context);
  }

  @override
  Future<String?> requestUsername({String? message}) async {
    final context = _context;
    if (context == null) {
      return null;
    }
    return showUsernameClaimSheet(context, message: message);
  }
}

/// Email entry sheet. Returns the trimmed address or null on cancel.
Future<String?> showEmailPromptSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ArenaColors.graphite,
    builder: (context) => const _EmailPromptSheet(),
  );
}

/// Code entry sheet. Returns the trimmed code or null on cancel.
Future<String?> showCodePromptSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ArenaColors.graphite,
    builder: (context) => const _CodePromptSheet(),
  );
}

/// Username claim sheet. Returns the raw entry or null on cancel.
Future<String?> showUsernameClaimSheet(
  BuildContext context, {
  String? message,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ArenaColors.graphite,
    builder: (context) => _UsernameClaimSheet(message: message),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.body,
    required this.field,
    required this.actionLabel,
    required this.onAction,
    this.error,
    this.kicker = 'Sign in',
  });

  final String kicker;
  final String title;
  final String body;
  final Widget field;
  final String actionLabel;
  final VoidCallback onAction;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Padding(
        padding: ArenaBattleSpace.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kicker,
              style: ArenaBattleText.micro.copyWith(color: ArenaColors.lime),
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
            Text(
              title,
              style: ArenaBattleText.h2.copyWith(color: ArenaColors.softWhite),
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
            Text(
              body,
              style: ArenaBattleText.small.copyWith(
                color: ArenaColors.secondary,
              ),
            ),
            const SizedBox(height: ArenaBattleSpace.s4),
            field,
            if (error != null) ...[
              const SizedBox(height: ArenaBattleSpace.s2),
              Text(
                error!,
                key: const ValueKey('sign-in-error'),
                style: ArenaBattleText.small.copyWith(
                  color: ArenaColors.danger,
                ),
              ),
            ],
            const SizedBox(height: ArenaBattleSpace.s4),
            BattlePrimaryButton(
              label: actionLabel,
              block: true,
              onPressed: onAction,
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
            BattleQuietButton(
              key: const ValueKey('sign-in-cancel'),
              label: 'Cancel',
              block: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailPromptSheet extends StatefulWidget {
  const _EmailPromptSheet();

  @override
  State<_EmailPromptSheet> createState() => _EmailPromptSheetState();
}

class _EmailPromptSheetState extends State<_EmailPromptSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final invalid = ArenaEmail.validationMessage(_controller.text);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    Navigator.of(context).pop(ArenaEmail.normalize(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Continue with email',
      body: 'We send a one-time code to this address. It is only used for '
          'this sign-in.',
      field: TextField(
        key: const ValueKey('sign-in-email-field'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: ArenaBattleText.body.copyWith(color: ArenaColors.softWhite),
        decoration: _fieldDecoration('Email address'),
      ),
      error: _error,
      actionLabel: 'Send code',
      onAction: _submit,
    );
  }
}

class _CodePromptSheet extends StatefulWidget {
  const _CodePromptSheet();

  @override
  State<_CodePromptSheet> createState() => _CodePromptSheetState();
}

class _CodePromptSheetState extends State<_CodePromptSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Enter the code from the email.');
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Enter the code',
      body: 'Type the code from the email. It expires quickly; request a new '
          'one by starting again.',
      field: TextField(
        key: const ValueKey('sign-in-code-field'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: ArenaBattleText.body.copyWith(color: ArenaColors.softWhite),
        decoration: _fieldDecoration('One-time code'),
      ),
      error: _error,
      actionLabel: 'Sign in',
      onAction: _submit,
    );
  }
}

class _UsernameClaimSheet extends StatefulWidget {
  const _UsernameClaimSheet({this.message});

  final String? message;

  @override
  State<_UsernameClaimSheet> createState() => _UsernameClaimSheetState();
}

class _UsernameClaimSheetState extends State<_UsernameClaimSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.message;
    _controller.addListener(() {
      if (_error != null) {
        setState(() => _error = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final invalid = ArenaUsername.validationMessage(_controller.text);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    Navigator.of(context).pop(ArenaUsername.normalize(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      kicker: 'First sign-in',
      title: 'Choose a username',
      body: 'This is how other players see you. 3–20 letters, digits or '
          'underscore. It must be unique.',
      field: TextField(
        key: const ValueKey('sign-in-username-field'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: ArenaBattleText.body.copyWith(color: ArenaColors.softWhite),
        decoration: _fieldDecoration('Username'),
      ),
      error: _error,
      actionLabel: 'Save username',
      onAction: _submit,
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
    filled: true,
    fillColor: ArenaColors.raised,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
      borderSide: const BorderSide(color: ArenaColors.lineStrong),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
      borderSide: const BorderSide(color: ArenaColors.lime, width: 2),
    ),
  );
}
