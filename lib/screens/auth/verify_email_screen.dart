import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'auth_messages.dart';
import 'auth_scaffold.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({required this.email, super.key});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await context.read<AuthProvider>().verifyEmail(
      email: widget.email,
      code: _codeController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      _showMessage(result.message ?? authErrorMessage(result.status));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Correo verificado correctamente.')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _resend() async {
    setState(() => _isLoading = true);
    final result = await context.read<AuthProvider>().resendVerificationCode(
      email: widget.email,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showMessage(
      result.message ??
          (result.isSuccess
              ? 'Si la cuenta existe, se ha enviado un nuevo código.'
              : authErrorMessage(result.status)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verifica tu correo',
      subtitle: 'Enviamos un código de 6 dígitos a ${widget.email}.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Código de verificación',
                prefixIcon: Icon(Icons.verified_outlined),
              ),
              validator: (value) {
                final code = value?.trim() ?? '';
                if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                  return 'Ingresa el código de 6 dígitos.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isLoading ? null : _verify,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verificar correo'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _resend,
              child: const Text('Reenviar código'),
            ),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
