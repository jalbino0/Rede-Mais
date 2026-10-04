import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?>
      _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _getProfile();
  }

  Future<Map<String, dynamic>?>
      _getProfile() {
    final user = AuthService.currentUser;

    if (user == null) {
      return Future.value(null);
    }

    return UserService.getUserProfile(
      user.uid,
    );
  }

  Future<void> _openEditProfile() async {
    final updated =
        await Navigator.of(context)
            .push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            const EditProfileScreen(),
      ),
    );

    if (updated != true || !mounted) {
      return;
    }

    setState(() {
      _profileFuture = _getProfile();
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Perfil atualizado com sucesso.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout(
    BuildContext context,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppColors.surface,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
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
            12,
            20,
            4,
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            12,
            4,
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
                      AppColors.dangerLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                  size: 21,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child: Text(
                  'Sair da conta?',
                  style: AppTextStyles.h3
                      .copyWith(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Você poderá entrar novamente a qualquer momento.',
            style: AppTextStyles.small
                .copyWith(
              color:
                  AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: Text(
                'Cancelar',
                style: AppTextStyles
                    .small
                    .copyWith(
                  color: AppColors
                      .textSecondary,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    AppColors.danger,
                foregroundColor:
                    AppColors.surface,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: Text(
                'Sair',
                style: AppTextStyles
                    .small
                    .copyWith(
                  color:
                      AppColors.surface,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !context.mounted) {
      return;
    }

    try {
      await AuthService.signOut();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível sair da conta. Tente novamente.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openTerms(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const TermsOfUseScreen(),
      ),
    );
  }

  void _openPrivacyPolicy(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const PrivacyPolicyScreen(),
      ),
    );
  }

  void _showHelp(
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppColors.surface,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
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
            6,
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            12,
            4,
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
                  color: AppColors
                      .secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .help_outline_rounded,
                  color: AppColors
                      .secondaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child: Text(
                  'Ajuda e suporte',
                  style: AppTextStyles.h3
                      .copyWith(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'No Rede+ você pode publicar pedidos de pequenas ajudas, encontrar solicitações da comunidade e se oferecer para ajudar outras pessoas.\n\nSe encontrar algum problema durante o uso, evite compartilhar informações pessoais ou endereço completo nas descrições dos pedidos.',
            style: AppTextStyles.small
                .copyWith(
              color:
                  AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    AppColors
                        .secondaryDark,
                foregroundColor:
                    AppColors.surface,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: Text(
                'Entendi',
                style: AppTextStyles
                    .small
                    .copyWith(
                  color:
                      AppColors.surface,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAbout(
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppColors.surface,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
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
            6,
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            12,
            4,
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
                  Icons
                      .info_outline_rounded,
                  color:
                      AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child: Text(
                  'Sobre o Rede+',
                  style: AppTextStyles.h3
                      .copyWith(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'O Rede+ conecta vizinhos e facilita pequenas ajudas do dia a dia.\n\nA proposta é aproximar pessoas da mesma região de forma simples, segura e colaborativa, fortalecendo os laços entre quem precisa de ajuda e quem pode ajudar.',
            style: AppTextStyles.small
                .copyWith(
              color:
                  AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
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
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: Text(
                'Fechar',
                style: AppTextStyles
                    .small
                    .copyWith(
                  color:
                      AppColors.surface,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getName(
    Map<String, dynamic>? profile,
  ) {
    final name = profile?['name'];

    if (name is String &&
        name.trim().isNotEmpty) {
      return name.trim();
    }

    return 'Usuário';
  }

  String _getEmail(
    Map<String, dynamic>? profile,
  ) {
    final profileEmail =
        profile?['email'];

    if (profileEmail is String &&
        profileEmail
            .trim()
            .isNotEmpty) {
      return profileEmail.trim();
    }

    final authEmail =
        AuthService.currentUser?.email;

    if (authEmail != null &&
        authEmail.trim().isNotEmpty) {
      return authEmail.trim();
    }

    return 'E-mail não disponível';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
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
            const _ProfileHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  28,
                ),
                child: Column(
                  children: [
                    FutureBuilder<
                        Map<String,
                            dynamic>?>(
                      future:
                          _profileFuture,
                      builder:
                          (context,
                              snapshot) {
                        if (snapshot
                                .connectionState ==
                            ConnectionState
                                .waiting) {
                          return const _ProfileLoadingCard();
                        }

                        final profile =
                            snapshot.data;

                        return _ProfileCard(
                          name:
                              _getName(
                            profile,
                          ),
                          email:
                              _getEmail(
                            profile,
                          ),
                        );
                      },
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    _ProfileMenu(
                      onEditProfile:
                          _openEditProfile,
                      onHelp: () {
                        _showHelp(
                          context,
                        );
                      },
                      onAbout: () {
                        _showAbout(
                          context,
                        );
                      },
                      onTerms: () {
                        _openTerms(
                          context,
                        );
                      },
                      onPrivacy: () {
                        _openPrivacyPolicy(
                          context,
                        );
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    _LogoutButton(
                      onPressed: () {
                        _logout(
                          context,
                        );
                      },
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    const _CommunityMessage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader
    extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(
    BuildContext context,
  ) {
    final topPadding =
        MediaQuery.paddingOf(context)
            .top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        topPadding + 14,
        18,
        20,
      ),
      decoration:
          const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius:
            BorderRadius.only(
          bottomLeft:
              Radius.circular(24),
          bottomRight:
              Radius.circular(24),
        ),
      ),
      child: Text(
        'Perfil',
        style:
            AppTextStyles.h2.copyWith(
          color: AppColors.surface,
        ),
      ),
    );
  }
}

class _ProfileCard
    extends StatelessWidget {
  final String name;
  final String email;

  const _ProfileCard({
    required this.name,
    required this.email,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final initial =
        name.trim().isEmpty
            ? '?'
            : name
                .trim()
                .substring(
                  0,
                  1,
                )
                .toUpperCase();

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            AppColors.secondaryLight,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary
              .withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration:
                const BoxDecoration(
              color:
                  AppColors.secondaryDark,
              shape: BoxShape.circle,
            ),
            alignment:
                Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.h2
                  .copyWith(
                color:
                    AppColors.surface,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppTextStyles.h3
                          .copyWith(
                    color:
                        AppColors.text,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons
                          .mail_outline_rounded,
                      size: 16,
                      color: AppColors
                          .secondaryDark,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Text(
                        email,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            AppTextStyles
                                .small
                                .copyWith(
                          color: AppColors
                              .secondaryDark,
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadingCard
    extends StatelessWidget {
  const _ProfileLoadingCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      height: 94,
      decoration: BoxDecoration(
        color:
            AppColors.secondaryLight,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary
              .withValues(
            alpha: 0.22,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child:
            CircularProgressIndicator(
          strokeWidth: 2.2,
          color:
              AppColors.secondaryDark,
        ),
      ),
    );
  }
}

class _ProfileMenu
    extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onHelp;
  final VoidCallback onAbout;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  const _ProfileMenu({
    required this.onEditProfile,
    required this.onHelp,
    required this.onAbout,
    required this.onTerms,
    required this.onPrivacy,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _ProfileMenuItem(
            icon:
                Icons.edit_outlined,
            title: 'Editar perfil',
            useGreen: false,
            onTap: onEditProfile,
          ),
          const _MenuDivider(),
          _ProfileMenuItem(
            icon: Icons
                .help_outline_rounded,
            title: 'Ajuda e suporte',
            useGreen: true,
            onTap: onHelp,
          ),
          const _MenuDivider(),
          _ProfileMenuItem(
            icon: Icons
                .info_outline_rounded,
            title: 'Sobre o Rede+',
            useGreen: false,
            onTap: onAbout,
          ),
          const _MenuDivider(),
          _ProfileMenuItem(
            icon:
                Icons.description_outlined,
            title: 'Termos de Uso',
            useGreen: true,
            onTap: onTerms,
          ),
          const _MenuDivider(),
          _ProfileMenuItem(
            icon:
                Icons.shield_outlined,
            title:
                'Política de Privacidade',
            useGreen: false,
            onTap: onPrivacy,
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool useGreen;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.useGreen,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final backgroundColor =
        useGreen
            ? AppColors.secondaryLight
            : AppColors.primaryLight;

    final iconColor = useGreen
        ? AppColors.secondaryDark
        : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(
                  color:
                      backgroundColor,
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: iconColor,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  title,
                  style:
                      AppTextStyles
                          .small
                          .copyWith(
                    color:
                        AppColors.text,
                    fontWeight:
                        FontWeight
                            .w500,
                  ),
                ),
              ),
              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 14,
                color: AppColors
                    .textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDivider
    extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Divider(
      height: 1,
      indent: 62,
      color: AppColors.border,
    );
  }
}

class _LogoutButton
    extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({
    required this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              AppColors.danger,
          side: BorderSide(
            color: AppColors.danger
                .withValues(
              alpha: 0.35,
            ),
          ),
          backgroundColor:
              AppColors.surface,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),
        ),
        icon: const Icon(
          Icons.logout_rounded,
          size: 18,
        ),
        label: Text(
          'Sair',
          style:
              AppTextStyles.small
                  .copyWith(
            color: AppColors.danger,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CommunityMessage
    extends StatelessWidget {
  const _CommunityMessage();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration:
              const BoxDecoration(
            color:
                AppColors.secondaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons
                .favorite_border_rounded,
            color:
                AppColors.secondaryDark,
            size: 20,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Uma comunidade feita por pessoas como você.',
          textAlign: TextAlign.center,
          style:
              AppTextStyles.caption
                  .copyWith(
            color: AppColors
                .textSecondary,
          ),
        ),
      ],
    );
  }
}