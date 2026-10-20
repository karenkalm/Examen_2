import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/ui_helpers.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/animations.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/loading_button.dart';
import 'register_screen.dart';

/// UI "Inicio de sesión".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  int _shakeCount = 0;
  String? _errorMessage;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Se ejecuta al presionar "Ingresar".
  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isBusy) return;
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    // 1) Validación: usuario y contraseña no pueden quedar vacíos.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        _shakeCount++;
      });
      HapticFeedback.mediumImpact();
      return;
    }

    // 2) Comparación de los datos ingresados con las variables
    //    (AuthService.login). Si coinciden, AuthGate abre "Productos".
    try {
      await auth.login(_usernameController.text, _passwordController.text);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      showAppSnackBar(context, '¡Bienvenido, ${auth.user?.firstName ?? ''}!');
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('No se pudo iniciar sesión. Inténtalo de nuevo.');
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

  Future<void> _openRegister() async {
    FocusScope.of(context).unfocus();
    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (!mounted) return;
    if (username == null) return;
    setState(() {
      _usernameController.text = username;
      _passwordController.clear();
      _errorMessage = null;
    });
    _passwordFocus.requestFocus();
    showAppSnackBar(context, 'Cuenta creada. Ahora inicia sesión.');
  }

  void _fillDemoCredentials() {
    HapticFeedback.selectionClick();
    setState(() {
      _usernameController.text = AuthService.demoUsername;
      _passwordController.text = AuthService.demoPassword;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isBusy = context.select<AuthProvider, bool>((auth) => auth.isBusy);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            const AuthBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: FadeSlideIn(
                      child: Column(
                        children: [
                          const AppLogo(),
                          const SizedBox(height: 16),
                          const AuthHeader(
                            title: AppInfo.name,
                            subtitle: AppInfo.tagline,
                          ),
                          const SizedBox(height: 28),
                          Shake(
                            trigger: _shakeCount,
                            child: AuthCard(
                              child: Form(
                                key: _formKey,
                                autovalidateMode: _autovalidateMode,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Iniciar sesión',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ingresa tus datos para continuar',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      controller: _usernameController,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      decoration: appInputDecoration(
                                        context,
                                        label: 'Usuario',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      validator: (value) =>
                                          Validators.requiredField(
                                        value,
                                        'Ingresa tu usuario',
                                      ),
                                      onFieldSubmitted: (_) =>
                                          _passwordFocus.requestFocus(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      decoration: appInputDecoration(
                                        context,
                                        label: 'Contraseña',
                                        icon: Icons.lock_outline_rounded,
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Mostrar contraseña'
                                              : 'Ocultar contraseña',
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (value) =>
                                          Validators.requiredField(
                                        value,
                                        'Ingresa tu contraseña',
                                      ),
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                    AnimatedSize(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeOut,
                                      child: _errorMessage == null
                                          ? const SizedBox(
                                              width: double.infinity,
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                top: 16,
                                              ),
                                              child: FormErrorBanner(
                                                message: _errorMessage!,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 24),
                                    LoadingButton(
                                      label: 'Ingresar',
                                      icon: Icons.login_rounded,
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
                                          '¿No tienes cuenta?',
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              isBusy ? null : _openRegister,
                                          child: const Text(
                                            'Regístrate',
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
                          const SizedBox(height: 18),
                          _DemoCredentialsHint(onTap: _fillDemoCredentials),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recordatorio del usuario de prueba; al tocarlo llena los campos.
class _DemoCredentialsHint extends StatelessWidget {
  const _DemoCredentialsHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Usuario de prueba: ${AuthService.demoUsername} · '
                  '${AuthService.demoPassword}  (toca para llenar)',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
