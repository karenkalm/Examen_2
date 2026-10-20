import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/ui_helpers.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/animations.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/loading_button.dart';

/// UI "Registro". Al terminar regresa al login con el usuario ya escrito.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _shakeCount = 0;
  String? _errorMessage;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    // Actualiza el medidor de seguridad mientras se escribe.
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() => setState(() {});

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isBusy) return;
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        _shakeCount++;
      });
      HapticFeedback.mediumImpact();
      return;
    }

    try {
      final user = await auth.register(
        name: _nameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(user.username);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('No se pudo crear la cuenta. Inténtalo de nuevo.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _shakeCount++;
    });
    HapticFeedback.mediumImpact();
  }

  Widget _visibilityToggle(bool obscured, VoidCallback onPressed) {
    return IconButton(
      tooltip: obscured ? 'Mostrar contraseña' : 'Ocultar contraseña',
      onPressed: onPressed,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isBusy = context.select<AuthProvider, bool>((auth) => auth.isBusy);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          const AuthBackground(heightFactor: 0.36),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, kToolbarHeight, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: FadeSlideIn(
                    child: Column(
                      children: [
                        const AuthHeader(
                          title: 'Crea tu cuenta',
                          subtitle: 'Regístrate para administrar el catálogo',
                        ),
                        const SizedBox(height: 24),
                        Shake(
                          trigger: _shakeCount,
                          child: AuthCard(
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _autovalidateMode,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    textInputAction: TextInputAction.next,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    autofillHints: const [AutofillHints.name],
                                    decoration: appInputDecoration(
                                      context,
                                      label: 'Nombre completo',
                                      icon: Icons.badge_outlined,
                                    ),
                                    validator: Validators.name,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _usernameController,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.newUsername,
                                    ],
                                    decoration: appInputDecoration(
                                      context,
                                      label: 'Usuario',
                                      hint: 'Ej. jorge_pizano',
                                      icon: Icons.alternate_email_rounded,
                                    ),
                                    validator: Validators.username,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _emailController,
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: appInputDecoration(
                                      context,
                                      label: 'Correo electrónico',
                                      icon: Icons.mail_outline_rounded,
                                    ),
                                    validator: Validators.email,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    decoration: appInputDecoration(
                                      context,
                                      label: 'Contraseña',
                                      icon: Icons.lock_outline_rounded,
                                      suffixIcon: _visibilityToggle(
                                        _obscurePassword,
                                        () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                    validator: Validators.password,
                                  ),
                                  PasswordStrengthMeter(
                                    password: _passwordController.text,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _confirmController,
                                    obscureText: _obscureConfirm,
                                    textInputAction: TextInputAction.done,
                                    decoration: appInputDecoration(
                                      context,
                                      label: 'Confirmar contraseña',
                                      icon: Icons.lock_reset_rounded,
                                      suffixIcon: _visibilityToggle(
                                        _obscureConfirm,
                                        () => setState(
                                          () => _obscureConfirm =
                                              !_obscureConfirm,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        Validators.confirmPassword(
                                      value,
                                      _passwordController.text,
                                    ),
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                    child: _errorMessage == null
                                        ? const SizedBox(
                                            width: double.infinity,
                                          )
                                        : Padding(
                                            padding:
                                                const EdgeInsets.only(top: 16),
                                            child: FormErrorBanner(
                                              message: _errorMessage!,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 24),
                                  LoadingButton(
                                    label: 'Crear cuenta',
                                    icon: Icons.person_add_alt_1_rounded,
                                    isLoading: isBusy,
                                    onPressed: _submit,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '¿Ya tienes cuenta?',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: isBusy
                                            ? null
                                            : () => Navigator.of(context).pop(),
                                        child: const Text(
                                          'Inicia sesión',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
