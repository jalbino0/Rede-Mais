import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/cep_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _cepController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final user = AuthService.currentUser;

      if (user == null) {
        throw StateError(
          'Usuário não autenticado.',
        );
      }

      final profile =
          await UserService.getUserProfile(
        user.uid,
      );

      if (profile == null) {
        throw StateError(
          'Perfil não encontrado.',
        );
      }

      final storedName =
          profile['name']?.toString().trim() ??
              '';

      final storedEmail =
          profile['email']
                  ?.toString()
                  .trim() ??
              '';

      final storedCep =
          profile['cep']?.toString().trim() ??
              '';

      if (!mounted) {
        return;
      }

      _nameController.text = storedName;

      _emailController.text =
          storedEmail.isNotEmpty
              ? storedEmail
              : user.email ?? '';

      _cepController.text =
          storedCep.replaceAll(
        RegExp(r'\D'),
        '',
      );

      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError =
            'Não foi possível carregar seus dados. Tente novamente.';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    final name =
        _nameController.text.trim();

    final cep = _cepController.text
        .replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (name.isEmpty) {
      _showMessage(
        'Informe seu nome.',
      );
      return;
    }

    if (name.length < 2) {
      _showMessage(
        'Informe um nome válido.',
      );
      return;
    }

    if (cep.length != 8) {
      _showMessage(
        'Informe um CEP válido com 8 números.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final user = AuthService.currentUser;

      if (user == null) {
        throw StateError(
          'Usuário não autenticado.',
        );
      }

      final location =
          await CepService.getLocation(
        cep,
      );

      if (!location.hasCoordinates) {
        throw StateError(
          'Coordenadas não encontradas.',
        );
      }

      await UserService.updateUserProfile(
        uid: user.uid,
        name: name,
        cep: cep,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on FormatException {
      if (!mounted) {
        return;
      }

      _showMessage(
        'O CEP informado é inválido ou não foi encontrado.',
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      if (error.message
          .toString()
          .contains(
            'Coordenadas não encontradas',
          )) {
        _showMessage(
          'Encontramos seu CEP, mas não foi possível obter uma localização aproximada para ele.',
        );
        return;
      }

      _showMessage(
        'Não foi possível validar seus dados. Tente novamente.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível atualizar seu perfil. Verifique sua conexão e tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    super.dispose();
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
            AppColors.surface,
        systemNavigationBarIconBrightness:
            Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            AppColors.background,
        body: Column(
          children: [
            _EditProfileHeader(
              onBack: () {
                Navigator.of(context)
                    .maybePop();
              },
            ),
            Expanded(
              child: _buildContent(),
            ),
            if (!_isLoading &&
                _loadError == null)
              _SaveButton(
                isSaving: _isSaving,
                onPressed: _saveProfile,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _LoadingContent();
    }

    if (_loadError != null) {
      return _ErrorContent(
        message: _loadError!,
        onRetry: _loadProfile,
      );
    }

    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        28,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Seus dados',
            style:
                AppTextStyles.h1.copyWith(
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Mantenha seu nome e sua região atualizados.',
            style: AppTextStyles.small
                .copyWith(
              color:
                  AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel(
            label: 'Nome',
          ),
          const SizedBox(height: 8),
          TextField(
            controller:
                _nameController,
            enabled: !_isSaving,
            textCapitalization:
                TextCapitalization.words,
            textInputAction:
                TextInputAction.next,
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
          const SizedBox(height: 22),
          const _SectionLabel(
            label: 'E-mail',
          ),
          const SizedBox(height: 8),
          TextField(
            controller:
                _emailController,
            readOnly: true,
            enableInteractiveSelection:
                false,
            decoration:
                const InputDecoration(
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                size: 20,
              ),
              suffixIcon: Icon(
                Icons
                    .lock_outline_rounded,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O e-mail da conta não pode ser alterado por esta tela.',
            style: AppTextStyles.caption
                .copyWith(
              color:
                  AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel(
            label: 'CEP',
          ),
          const SizedBox(height: 8),
          TextField(
            controller:
                _cepController,
            enabled: !_isSaving,
            keyboardType:
                TextInputType.number,
            textInputAction:
                TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter
                  .digitsOnly,
              LengthLimitingTextInputFormatter(
                8,
              ),
            ],
            onSubmitted: (_) {
              _saveProfile();
            },
            decoration:
                const InputDecoration(
              hintText: '00000000',
              prefixIcon: Icon(
                Icons
                    .location_on_outlined,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _LocationPrivacyCard(),
        ],
      ),
    );
  }
}

class _EditProfileHeader
    extends StatelessWidget {
  final VoidCallback onBack;

  const _EditProfileHeader({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.paddingOf(context)
            .top;

    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: EdgeInsets.fromLTRB(
        10,
        topPadding + 6,
        18,
        14,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              color: AppColors.surface,
              size: 19,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'Editar perfil',
            style:
                AppTextStyles.h3.copyWith(
              color: AppColors.surface,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel
    extends StatelessWidget {
  final String label;

  const _SectionLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style:
          AppTextStyles.small.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LocationPrivacyCard
    extends StatelessWidget {
  const _LocationPrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            AppColors.primaryLight,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary
              .withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.primaryDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Usamos seu CEP para identificar sua região aproximada e mostrar pedidos em até 3 km. O CEP e seu endereço exato não são exibidos publicamente.',
              style: AppTextStyles.caption
                  .copyWith(
                color:
                    AppColors.primaryDark,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingContent
    extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child:
            CircularProgressIndicator(
          strokeWidth: 2.6,
          color:
              AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _ErrorContent
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorContent({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration:
                    const BoxDecoration(
                  color:
                      AppColors.dangerLight,
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .error_outline_rounded,
                  color:
                      AppColors.danger,
                  size: 28,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                'Não foi possível carregar',
                textAlign:
                    TextAlign.center,
                style: AppTextStyles.h3
                    .copyWith(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign:
                    TextAlign.center,
                style: AppTextStyles
                    .small
                    .copyWith(
                  color: AppColors
                      .textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              SizedBox(
                width:
                    double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton
                      .styleFrom(
                    backgroundColor:
                        AppColors
                            .primaryDark,
                    foregroundColor:
                        AppColors.surface,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons
                        .refresh_rounded,
                    size: 18,
                  ),
                  label: Text(
                    'Tentar novamente',
                    style: AppTextStyles
                        .small
                        .copyWith(
                      color: AppColors
                          .surface,
                      fontWeight:
                          FontWeight.w600,
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

class _SaveButton
    extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.paddingOf(context)
            .bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        bottomPadding + 12,
      ),
      decoration:
          const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SizedBox(
        height: 50,
        child: FilledButton.icon(
          onPressed:
              isSaving ? null : onPressed,
          style:
              FilledButton.styleFrom(
            backgroundColor:
                AppColors.primaryDark,
            foregroundColor:
                AppColors.surface,
            disabledBackgroundColor:
                AppColors.primaryDark
                    .withValues(
              alpha: 0.6,
            ),
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
          ),
          icon: isSaving
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
              : const Icon(
                  Icons.check_rounded,
                  size: 19,
                ),
          label: Text(
            isSaving
                ? 'Salvando...'
                : 'Salvar alterações',
            style: AppTextStyles.small
                .copyWith(
              color: AppColors.surface,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}