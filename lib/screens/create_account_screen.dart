import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/cep_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/main_navigation.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState
    extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _cepController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cepController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pop();
  }

  Future<void> _deleteCreatedUser(
    UserCredential? credential,
  ) async {
    try {
      await credential?.user?.delete();
    } catch (error) {
      debugPrint(
        'Não foi possível remover o usuário criado: $error',
      );
    }
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    final isValid =
        _formKey.currentState?.validate() ??
            false;

    if (!isValid ||
        !_acceptedTerms ||
        _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    UserCredential? credential;

    try {
      final normalizedCep =
          _cepController.text.replaceAll(
        RegExp(r'\D'),
        '',
      );

      final location =
          await CepService.getLocation(
        normalizedCep,
      );

      final latitude = location.latitude;
      final longitude = location.longitude;

      if (latitude == null ||
          longitude == null) {
        throw StateError(
          'Coordenadas não encontradas.',
        );
      }

      credential =
          await AuthService.createAccount(
        email: _emailController.text,
        password:
            _passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw StateError(
          'Usuário não criado.',
        );
      }

      await UserService.createUserProfile(
        uid: user.uid,
        name: _nameController.text,
        email: _emailController.text,
        cep: normalizedCep,
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              const MainNavigation(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (credential != null &&
          error is! FirebaseAuthException) {
        await _deleteCreatedUser(
          credential,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      String message;

      if (error is FirebaseAuthException) {
        message =
            AuthService.getErrorMessage(
          error,
        );
      } else if (error is FormatException) {
        message =
            'O CEP informado é inválido ou não foi encontrado.';
      } else if (error is StateError &&
          error.message
              .toString()
              .contains(
                'Coordenadas não encontradas',
              )) {
        message =
            'Encontramos o CEP, mas não foi possível obter uma localização aproximada para ele.';
      } else {
        message =
            'Não foi possível salvar seus dados. Verifique sua conexão e tente novamente.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openTermsOfUse() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const TermsOfUseScreen(),
      ),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const PrivacyPolicyScreen(),
      ),
    );
  }

  String? _validateName(
    String? value,
  ) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Informe seu nome.';
    }

    if (name.length < 2) {
      return 'Informe um nome válido.';
    }

    return null;
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
      return 'Crie uma senha.';
    }

    if (password.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }

    return null;
  }

  String? _validateCep(
    String? value,
  ) {
    final cep = (value ?? '')
        .replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (cep.isEmpty) {
      return 'Informe seu CEP.';
    }

    if (cep.length != 8) {
      return 'O CEP deve ter 8 dígitos.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<
        SystemUiOverlayStyle>(
      value:
          const SystemUiOverlayStyle(
        statusBarColor:
            Colors.transparent,
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
              const _CreateAccountHero(),
              Transform.translate(
                offset:
                    const Offset(0, -28),
                child: Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 18,
                  ),
                  child: Form(
                    key: _formKey,
                    child:
                        _CreateAccountCard(
                      nameController:
                          _nameController,
                      emailController:
                          _emailController,
                      passwordController:
                          _passwordController,
                      cepController:
                          _cepController,
                      obscurePassword:
                          _obscurePassword,
                      acceptedTerms:
                          _acceptedTerms,
                      isLoading:
                          _isLoading,
                      validateName:
                          _validateName,
                      validateEmail:
                          _validateEmail,
                      validatePassword:
                          _validatePassword,
                      validateCep:
                          _validateCep,
                      onTogglePassword:
                          () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                      onTermsChanged:
                          (value) {
                        setState(() {
                          _acceptedTerms =
                              value ??
                                  false;
                        });
                      },
                      onLogin:
                          _goToLogin,
                      onCreateAccount:
                          _createAccount,
                      onOpenTerms:
                          _openTermsOfUse,
                      onOpenPrivacy:
                          _openPrivacyPolicy,
                    ),
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

class _CreateAccountHero
    extends StatelessWidget {
  const _CreateAccountHero();

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.paddingOf(context)
            .top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        topPadding + 16,
        24,
        60,
      ),
      decoration:
          const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius:
            BorderRadius.only(
          bottomLeft:
              Radius.circular(32),
          bottomRight:
              Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            padding:
                const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(
                19,
              ),
            ),
            child: Image.asset(
              'assets/images/logo_simplificada.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'Rede+',
            style:
                AppTextStyles.h1.copyWith(
              color: AppColors.surface,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Conectando vizinhos. Facilitando ajudas.',
            textAlign:
                TextAlign.center,
            style:
                AppTextStyles.caption
                    .copyWith(
              color:
                  AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Criar conta',
            style:
                AppTextStyles.h2.copyWith(
              color: AppColors.surface,
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Faça parte da rede de vizinhos que se ajudam nas pequenas coisas do dia a dia.',
            textAlign:
                TextAlign.center,
            style: AppTextStyles.small
                .copyWith(
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

class _CreateAccountCard
    extends StatelessWidget {
  final TextEditingController
      nameController;

  final TextEditingController
      emailController;

  final TextEditingController
      passwordController;

  final TextEditingController
      cepController;

  final bool obscurePassword;
  final bool acceptedTerms;
  final bool isLoading;

  final String? Function(String?)
      validateName;

  final String? Function(String?)
      validateEmail;

  final String? Function(String?)
      validatePassword;

  final String? Function(String?)
      validateCep;

  final VoidCallback
      onTogglePassword;

  final ValueChanged<bool?>
      onTermsChanged;

  final VoidCallback onLogin;
  final VoidCallback onCreateAccount;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  const _CreateAccountCard({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.cepController,
    required this.obscurePassword,
    required this.acceptedTerms,
    required this.isLoading,
    required this.validateName,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateCep,
    required this.onTogglePassword,
    required this.onTermsChanged,
    required this.onLogin,
    required this.onCreateAccount,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
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
            color: Colors.black
                .withValues(
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
            'Seus dados',
            style:
                AppTextStyles.h3.copyWith(
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 18),
          const _FieldLabel(
            label: 'Nome',
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller:
                nameController,
            enabled: !isLoading,
            textCapitalization:
                TextCapitalization.words,
            textInputAction:
                TextInputAction.next,
            validator: validateName,
            decoration:
                const InputDecoration(
              hintText:
                  'Como você se chama?',
              prefixIcon: Icon(
                Icons
                    .person_outline_rounded,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 15),
          const _FieldLabel(
            label: 'E-mail',
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller:
                emailController,
            enabled: !isLoading,
            keyboardType:
                TextInputType
                    .emailAddress,
            textInputAction:
                TextInputAction.next,
            autocorrect: false,
            validator: validateEmail,
            decoration:
                const InputDecoration(
              hintText: 'Seu e-mail',
              prefixIcon: Icon(
                Icons
                    .mail_outline_rounded,
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
            controller:
                passwordController,
            enabled: !isLoading,
            obscureText:
                obscurePassword,
            textInputAction:
                TextInputAction.next,
            validator:
                validatePassword,
            decoration:
                InputDecoration(
              hintText:
                  'Crie uma senha',
              prefixIcon: const Icon(
                Icons
                    .lock_outline_rounded,
                size: 20,
              ),
              suffixIcon:
                  IconButton(
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
          const SizedBox(height: 6),
          const Padding(
            padding:
                EdgeInsets.only(
              left: 3,
            ),
            child: Text(
              'Prefira uma senha com letras, números e símbolos.',
              style:
                  AppTextStyles.caption,
            ),
          ),
          const SizedBox(height: 15),
          const _FieldLabel(
            label: 'CEP',
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller:
                cepController,
            enabled: !isLoading,
            keyboardType:
                TextInputType.number,
            textInputAction:
                TextInputAction.done,
            maxLength: 8,
            validator: validateCep,
            inputFormatters: [
              FilteringTextInputFormatter
                  .digitsOnly,
            ],
            onFieldSubmitted: (_) {
              if (acceptedTerms &&
                  !isLoading) {
                onCreateAccount();
              }
            },
            decoration:
                const InputDecoration(
              hintText: '00000-000',
              counterText: '',
              prefixIcon: Icon(
                Icons
                    .location_on_outlined,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding:
                EdgeInsets.only(
              left: 3,
            ),
            child: Text(
              'Usaremos seu CEP para identificar sua região aproximada e mostrar pedidos em até 3 km. Ele não será exibido publicamente.',
              style:
                  AppTextStyles.caption,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset:
                    const Offset(-4, -5),
                child: Checkbox(
                  value:
                      acceptedTerms,
                  activeColor:
                      AppColors.primary,
                  side:
                      const BorderSide(
                    color:
                        AppColors.border,
                    width: 1.5,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(4),
                  ),
                  onChanged: isLoading
                      ? null
                      : onTermsChanged,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    top: 3,
                  ),
                  child: Wrap(
                    crossAxisAlignment:
                        WrapCrossAlignment
                            .center,
                    children: [
                      Text(
                        'Li e aceito os ',
                        style:
                            AppTextStyles
                                .caption
                                .copyWith(
                          color: AppColors
                              .textSecondary,
                          height: 1.4,
                        ),
                      ),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : onOpenTerms,
                        child: Text(
                          'Termos de uso',
                          style:
                              AppTextStyles
                                  .caption
                                  .copyWith(
                            color: AppColors
                                .primary,
                            fontWeight:
                                FontWeight
                                    .w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Text(
                        ' e a ',
                        style:
                            AppTextStyles
                                .caption
                                .copyWith(
                          color: AppColors
                              .textSecondary,
                          height: 1.4,
                        ),
                      ),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : onOpenPrivacy,
                        child: Text(
                          'Política de privacidade',
                          style:
                              AppTextStyles
                                  .caption
                                  .copyWith(
                            color: AppColors
                                .primary,
                            fontWeight:
                                FontWeight
                                    .w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Text(
                        '.',
                        style:
                            AppTextStyles
                                .caption
                                .copyWith(
                          color: AppColors
                              .textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed:
                  acceptedTerms &&
                          !isLoading
                      ? onCreateAccount
                      : null,
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    AppColors.primaryDark,
                disabledBackgroundColor:
                    AppColors.border,
                foregroundColor:
                    AppColors.surface,
                disabledForegroundColor:
                    AppColors
                        .textSecondary,
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
                        color: AppColors
                            .surface,
                      ),
                    )
                  : Text(
                      'Criar conta',
                      style:
                          AppTextStyles
                              .small
                              .copyWith(
                        color: AppColors
                            .surface,
                        fontWeight:
                            FontWeight
                                .w600,
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
                'Já tem uma conta?',
                style: AppTextStyles
                    .caption
                    .copyWith(
                  color: AppColors
                      .textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : onLogin,
                child: Text(
                  'Entrar',
                  style: AppTextStyles
                      .caption
                      .copyWith(
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

class _FieldLabel
    extends StatelessWidget {
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