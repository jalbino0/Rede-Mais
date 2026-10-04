import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/main_navigation.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const CreateAccountScreen(),
      ),
    );
  }

  Future<void> _openForgotPassword() async {
    FocusScope.of(context).unfocus();

    final sent = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _ForgotPasswordDialog(
          initialEmail:
              _emailController.text.trim(),
        );
      },
    );

    if (sent != true || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'E-mail de recuperação enviado. Verifique sua caixa de entrada.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _enterApp() async {
    FocusScope.of(context).unfocus();

    final isValid =
        _formKey.currentState?.validate() ??
            false;

    if (!isValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              const MainNavigation(),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      final message =
          error is FirebaseAuthException
              ? AuthService.getErrorMessage(
                  error,
                )
              : 'Não foi possível entrar. Tente novamente.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _validateEmail(
    String? value,
  ) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }

    return null;
  }

  String? _validatePassword(
    String? value,
  ) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Informe sua senha.';
    }

    if (password.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light,
        statusBarBrightness:
            Brightness.dark,
        systemNavigationBarColor:
            AppColors.background,
        systemNavigationBarIconBrightness:
            Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              const _LoginHero(),
              Transform.translate(
                offset:
                    const Offset(0, -28),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),
                  child: Form(
                    key: _formKey,
                    child: _LoginCard(
                      emailController:
                          _emailController,
                      passwordController:
                          _passwordController,
                      obscurePassword:
                          _obscurePassword,
                      isLoading:
                          _isLoading,
                      onTogglePassword: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                      onCreateAccount:
                          _openCreateAccount,
                      onForgotPassword:
                          _openForgotPassword,
                      onLogin: _enterApp,
                      validateEmail:
                          _validateEmail,
                      validatePassword:
                          _validatePassword,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset:
                    const Offset(0, -10),
                child: const Padding(
                  padding:
                      EdgeInsets.fromLTRB(
                    18,
                    0,
                    18,
                    28,
                  ),
                  child:
                      _CommunityMessage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        topPadding + 18,
        24,
        62,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            padding:
                const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/images/logo_simplificada.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Rede+',
            style:
                AppTextStyles.h1.copyWith(
              color: AppColors.surface,
              fontSize: 27,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Conectando vizinhos. Facilitando ajudas.',
            textAlign: TextAlign.center,
            style:
                AppTextStyles.caption.copyWith(
              color:
                  AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bem-vindo',
            textAlign: TextAlign.center,
            style:
                AppTextStyles.h2.copyWith(
              color: AppColors.surface,
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Entre para continuar fazendo parte da sua comunidade.',
            textAlign: TextAlign.center,
            style:
                AppTextStyles.small.copyWith(
              color:
                  AppColors.primaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController
      emailController;

  final TextEditingController
      passwordController;

  final bool obscurePassword;
  final bool isLoading;

  final VoidCallback onTogglePassword;
  final VoidCallback onCreateAccount;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;

  final String? Function(String?)
      validateEmail;

  final String? Function(String?)
      validatePassword;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onCreateAccount,
    required this.onForgotPassword,
    required this.onLogin,
    required this.validateEmail,
    required this.validatePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        18,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 20,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Entrar na sua conta',
            style:
                AppTextStyles.h3.copyWith(
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 18),
          const _FieldLabel(
            label: 'E-mail',
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: emailController,
            enabled: !isLoading,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.next,
            autocorrect: false,
            validator: validateEmail,
            decoration:
                const InputDecoration(
              hintText: 'Seu e-mail',
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 15),
          const _FieldLabel(
            label: 'Senha',
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: passwordController,
            enabled: !isLoading,
            obscureText: obscurePassword,
            textInputAction:
                TextInputAction.done,
            validator: validatePassword,
            onFieldSubmitted: (_) {
              onLogin();
            },
            decoration: InputDecoration(
              hintText: 'Sua senha',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                size: 20,
              ),
              suffixIcon: IconButton(
                onPressed: isLoading
                    ? null
                    : onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons
                          .visibility_outlined
                      : Icons
                          .visibility_off_outlined,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : onForgotPassword,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                tapTargetSize:
                    MaterialTapTargetSize
                        .shrinkWrap,
              ),
              child: Text(
                'Esqueci minha senha',
                style:
                    AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: isLoading
                  ? null
                  : onLogin,
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    AppColors.primaryDark,
                disabledBackgroundColor:
                    AppColors.border,
                foregroundColor:
                    AppColors.surface,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color:
                            AppColors.surface,
                      ),
                    )
                  : Text(
                      'Entrar',
                      style:
                          AppTextStyles.small.copyWith(
                        color:
                            AppColors.surface,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                'Ainda não tem uma conta?',
                style:
                    AppTextStyles.caption.copyWith(
                  color:
                      AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : onCreateAccount,
                child: Text(
                  'Criar conta',
                  style:
                      AppTextStyles.caption.copyWith(
                    color:
                        AppColors.primary,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordDialog
    extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({
    required this.initialEmail,
  });

  @override
  State<_ForgotPasswordDialog>
      createState() =>
          _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState
    extends State<_ForgotPasswordDialog> {
  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _emailController;

  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _emailController =
        TextEditingController(
      text: widget.initialEmail,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(
    String? value,
  ) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }

    return null;
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();

    final isValid =
        _formKey.currentState?.validate() ??
            false;

    if (!isValid || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await AuthService.sendPasswordResetEmail(
        email: _emailController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message =
          error is FirebaseAuthException
              ? AuthService.getErrorMessage(
                  error,
                )
              : 'Não foi possível enviar o e-mail. Tente novamente.';

      setState(() {
        _isSending = false;
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor:
          AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(22),
      ),
      titlePadding:
          const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        0,
      ),
      contentPadding:
          const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        4,
      ),
      actionsPadding:
          const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12,
      ),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                const BoxDecoration(
              color:
                  AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color:
                  AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Recuperar senha',
              style:
                  AppTextStyles.h3.copyWith(
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Informe o e-mail da sua conta. Enviaremos um link para você criar uma nova senha.',
              style:
                  AppTextStyles.small.copyWith(
                color:
                    AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller:
                  _emailController,
              enabled: !_isSending,
              keyboardType:
                  TextInputType.emailAddress,
              textInputAction:
                  TextInputAction.done,
              autocorrect: false,
              validator: _validateEmail,
              onFieldSubmitted: (_) {
                _sendResetEmail();
              },
              decoration:
                  const InputDecoration(
                hintText: 'Seu e-mail',
                prefixIcon: Icon(
                  Icons.mail_outline_rounded,
                  size: 20,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style:
                    AppTextStyles.caption.copyWith(
                  color: AppColors.danger,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending
              ? null
              : () {
                  Navigator.of(context)
                      .pop(false);
                },
          child: Text(
            'Cancelar',
            style:
                AppTextStyles.small.copyWith(
              color:
                  AppColors.textSecondary,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: _isSending
              ? null
              : _sendResetEmail,
          style:
              FilledButton.styleFrom(
            backgroundColor:
                AppColors.primaryDark,
            foregroundColor:
                AppColors.surface,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        AppColors.surface,
                  ),
                )
              : Text(
                  'Enviar link',
                  style:
                      AppTextStyles.small.copyWith(
                    color:
                        AppColors.surface,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style:
          AppTextStyles.caption.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CommunityMessage
    extends StatelessWidget {
  const _CommunityMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color:
            AppColors.secondaryLight,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color:
                  AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Pequenas ajudas. Grandes laços.',
                  style:
                      AppTextStyles.small.copyWith(
                    color: AppColors.text,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Uma comunidade feita por pessoas como você.',
                  style:
                      AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}