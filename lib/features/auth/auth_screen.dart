import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth});
  final AuthController auth;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _register = false;
  bool _showPassword = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _identifierValidator(String? value) {
    final identifier = value?.trim() ?? '';
    final isEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(identifier);
    final isUsername = RegExp(r'^[a-zA-Z0-9_.-]{3,32}$').hasMatch(identifier);
    if (isEmail || isUsername) return null;
    return 'Enter a valid email or a username (3–32 letters/numbers).';
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_register) {
        await widget.auth.register(_identifier.text, _password.text);
      } else {
        await widget.auth.signIn(_identifier.text, _password.text);
      }
    } on LocalAuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not access local account storage.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.restaurant_menu, size: 46),
                  const SizedBox(height: 16),
                  Text(
                    _register
                        ? 'Create a local account'
                        : 'Welcome to MacroMate',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your account and nutrition records stay on this device. They are not backed up or synced online.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (widget.auth.error != null) ...[
                    Text(
                      widget.auth.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _identifier,
                          validator: _identifierValidator,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'Email or username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          validator: (value) => (value ?? '').length < 8
                              ? 'Use at least 8 characters.'
                              : null,
                          obscureText: !_showPassword,
                          textInputAction: _register
                              ? TextInputAction.next
                              : TextInputAction.done,
                          autofillHints: [
                            _register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _showPassword
                                  ? 'Hide password'
                                  : 'Show password',
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          onFieldSubmitted: (_) {
                            if (!_register) _submit();
                          },
                        ),
                        if (_register) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirm,
                            obscureText: true,
                            validator: (value) => value != _password.text
                                ? 'Passwords do not match.'
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(_message!, style: TextStyle(color: colors.error)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_register ? 'Create account' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _message = null;
                          }),
                    child: Text(
                      _register
                          ? 'Already have an account? Sign in'
                          : 'Create a local account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
