import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/help_request.dart';
import '../services/auth_service.dart';
import '../services/cep_service.dart';
import '../services/request_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'request_details_screen.dart';

class RequestPublishedScreen extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final String neighborhood;
  final bool isUrgent;
  final VoidCallback? onGoHomeRequested;

  const RequestPublishedScreen({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.neighborhood,
    this.isUrgent = false,
    this.onGoHomeRequested,
  });

  @override
  State<RequestPublishedScreen> createState() =>
      _RequestPublishedScreenState();
}

class _RequestPublishedScreenState extends State<RequestPublishedScreen> {
  HelpRequest? _request;
  bool _isPublishing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _publishRequest();
  }

  Future<void> _publishRequest() async {
    try {
      final user = AuthService.currentUser;

      if (user == null) {
        throw StateError(
          'Usuário não autenticado.',
        );
      }

      final profile = await UserService.getUserProfile(
        user.uid,
      );

      if (profile == null) {
        throw StateError(
          'Perfil não encontrado.',
        );
      }

      final storedName = profile['name'];

      final userName =
          storedName is String &&
                  storedName.trim().isNotEmpty
              ? storedName.trim()
              : _fallbackUserName(user.email);

      final storedCep = profile['cep'];

      if (storedCep is! String ||
          storedCep.trim().isEmpty) {
        throw StateError(
          'CEP não encontrado no perfil.',
        );
      }

      final location =
          await CepService.getLocation(
        storedCep,
      );

      if (!location.hasCoordinates) {
        throw StateError(
          'Coordenadas não encontradas.',
        );
      }

      final latitude = location.latitude;
      final longitude = location.longitude;

      if (latitude == null ||
          longitude == null) {
        throw StateError(
          'Coordenadas não encontradas.',
        );
      }

      final request =
          await RequestService.createRequest(
        userId: user.uid,
        userName: userName,
        title: widget.title,
        description: widget.description,
        category: widget.category,
        neighborhood:
            location.neighborhood,
        latitude: latitude,
        longitude: longitude,
        isUrgent: widget.isUrgent,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _request = request;
        _isPublishing = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPublishing = false;
        _errorMessage =
            _getPublishErrorMessage(error);
      });
    }
  }

  String _getPublishErrorMessage(
    Object error,
  ) {
    if (error is FormatException) {
      return 'O CEP salvo no seu perfil é inválido ou não foi encontrado. Verifique seu CEP e tente novamente.';
    }

    if (error is StateError) {
      final message =
          error.message.toString();

      if (message.contains(
        'CEP não encontrado no perfil',
      )) {
        return 'Não encontramos um CEP no seu perfil. Atualize seus dados antes de publicar um pedido.';
      }

      if (message.contains(
        'Perfil não encontrado',
      )) {
        return 'Não foi possível encontrar seu perfil. Entre novamente e tente publicar o pedido.';
      }

      if (message.contains(
        'Usuário não autenticado',
      )) {
        return 'Sua sessão não está disponível. Entre novamente para publicar um pedido.';
      }

      if (message.contains(
        'Coordenadas não encontradas',
      )) {
        return 'Encontramos seu CEP, mas não foi possível obter uma localização aproximada para este pedido.';
      }

      if (message.contains(
            'Bairro não encontrado',
          ) ||
          message.contains(
            'consultar o CEP',
          )) {
        return 'Não foi possível identificar sua região pelo CEP salvo no perfil. Verifique sua conexão e tente novamente.';
      }
    }

    return 'Não foi possível publicar seu pedido. Verifique sua conexão e tente novamente.';
  }

  String _fallbackUserName(
    String? email,
  ) {
    if (email == null ||
        email.trim().isEmpty) {
      return 'Usuário';
    }

    final parts = email.split('@');

    if (parts.isEmpty ||
        parts.first.trim().isEmpty) {
      return 'Usuário';
    }

    return parts.first.trim();
  }

  void _viewRequest() {
    final request = _request;

    if (request == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            RequestDetailsScreen(
          request: request,
          isOwnRequest: true,
        ),
      ),
    );
  }

  void _goHome() {
    widget.onGoHomeRequested?.call();

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  String get _headerTitle {
    if (_isPublishing) {
      return 'Publicando pedido';
    }

    if (_request != null) {
      return 'Pedido publicado';
    }

    return 'Não foi possível publicar';
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
        body: Column(
          children: [
            _PublishedHeader(
              title: _headerTitle,
            ),
            Expanded(
              child:
                  _buildContent(request),
            ),
            if (request != null)
              _BottomActions(
                onViewRequest:
                    _viewRequest,
                onGoHome: _goHome,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    HelpRequest? request,
  ) {
    if (_isPublishing) {
      return const _PublishingContent();
    }

    if (request == null) {
      return _PublishErrorContent(
        message: _errorMessage ??
            'Não foi possível publicar seu pedido.',
        onBack: _goBack,
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
        children: [
          const _SuccessCard(),
          const SizedBox(height: 18),
          _RequestSummary(
            title: request.title,
            description:
                request.description,
            category:
                request.category,
            neighborhood:
                request.neighborhood,
            isUrgent:
                request.isUrgent,
          ),
          const SizedBox(height: 16),
          const _CommunityMessage(),
        ],
      ),
    );
  }
}

class _PublishedHeader
    extends StatelessWidget {
  final String title;

  const _PublishedHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.paddingOf(context)
            .top;

    return Container(
      width: double.infinity,
      color: AppColors.secondaryDark,
      padding: EdgeInsets.fromLTRB(
        18,
        topPadding + 14,
        18,
        16,
      ),
      child: Text(
        title,
        style:
            AppTextStyles.h3.copyWith(
          color: AppColors.surface,
          fontSize: 17,
        ),
      ),
    );
  }
}

class _PublishingContent
    extends StatelessWidget {
  const _PublishingContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child:
                  CircularProgressIndicator(
                strokeWidth: 3,
                color:
                    AppColors.secondaryDark,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Publicando seu pedido...',
              textAlign:
                  TextAlign.center,
              style:
                  AppTextStyles.h3.copyWith(
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Estamos identificando sua região e deixando tudo pronto para a comunidade.',
              textAlign:
                  TextAlign.center,
              style: AppTextStyles.small
                  .copyWith(
                color:
                    AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublishErrorContent
    extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _PublishErrorContent({
    required this.message,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        28,
        18,
        28,
      ),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.fromLTRB(
          22,
          26,
          22,
          22,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration:
                  const BoxDecoration(
                color:
                    AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .error_outline_rounded,
                color: AppColors.danger,
                size: 31,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pedido não publicado',
              textAlign:
                  TextAlign.center,
              style:
                  AppTextStyles.h2.copyWith(
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: AppTextStyles.small
                  .copyWith(
                color:
                    AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onBack,
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
                      15,
                    ),
                  ),
                ),
                child: Text(
                  'Voltar ao pedido',
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
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessCard
    extends StatelessWidget {
  const _SuccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        22,
        26,
        22,
        24,
      ),
      decoration: BoxDecoration(
        color:
            AppColors.secondaryLight,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.secondary
              .withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration:
                const BoxDecoration(
              color:
                  AppColors.secondaryDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.surface,
              size: 35,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pedido publicado!',
            textAlign: TextAlign.center,
            style:
                AppTextStyles.h2.copyWith(
              color:
                  AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Seu pedido já está disponível para outras pessoas da comunidade.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small
                .copyWith(
              color:
                  AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestSummary
    extends StatelessWidget {
  final String title;
  final String description;
  final String category;
  final String neighborhood;
  final bool isUrgent;

  const _RequestSummary({
    required this.title,
    required this.description,
    required this.category,
    required this.neighborhood,
    required this.isUrgent,
  });

  IconData get categoryIcon {
    switch (category) {
      case 'Mercado':
        return Icons
            .shopping_cart_outlined;
      case 'Pet':
        return Icons.pets_outlined;
      case 'Transporte':
        return Icons
            .directions_car_outlined;
      case 'Casa':
        return Icons.home_outlined;
      case 'Tecnologia':
        return Icons.computer_outlined;
      case 'Companhia':
        return Icons.groups_outlined;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  bool get useGreen {
    return category == 'Mercado' ||
        category == 'Pet' ||
        category == 'Casa' ||
        category == 'Companhia';
  }

  @override
  Widget build(BuildContext context) {
    final categoryBackground =
        useGreen
            ? AppColors.secondaryLight
            : AppColors.primaryLight;

    final categoryColor =
        useGreen
            ? AppColors.secondaryDark
            : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration:
                    BoxDecoration(
                  color:
                      categoryBackground,
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  categoryIcon,
                  size: 16,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: AppTextStyles
                    .caption
                    .copyWith(
                  color: categoryColor,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              if (isUrgent) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration:
                      BoxDecoration(
                    color: AppColors
                        .dangerLight,
                    borderRadius:
                        BorderRadius
                            .circular(12),
                  ),
                  child: Text(
                    'URGENTE',
                    style: AppTextStyles
                        .caption
                        .copyWith(
                      color:
                          AppColors.danger,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style:
                AppTextStyles.h3.copyWith(
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: AppTextStyles.small
                .copyWith(
              color:
                  AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons
                    .location_on_outlined,
                size: 17,
                color:
                    AppColors.secondaryDark,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  neighborhood,
                  style: AppTextStyles
                      .caption
                      .copyWith(
                    color:
                        AppColors.text,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'região aproximada',
                style: AppTextStyles
                    .caption
                    .copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
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
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color:
            AppColors.secondaryLight,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .favorite_border_rounded,
              color:
                  AppColors.secondaryDark,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Agora pessoas da comunidade podem encontrar e ajudar no seu pedido.',
              style: AppTextStyles
                  .caption
                  .copyWith(
                color:
                    AppColors.secondaryDark,
                fontWeight:
                    FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions
    extends StatelessWidget {
  final VoidCallback onViewRequest;
  final VoidCallback onGoHome;

  const _BottomActions({
    required this.onViewRequest,
    required this.onGoHome,
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
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed:
                  onViewRequest,
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
                    15,
                  ),
                ),
              ),
              child: Text(
                'Ver meu pedido',
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
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onGoHome,
              style: OutlinedButton
                  .styleFrom(
                foregroundColor:
                    AppColors.primaryDark,
                side:
                    const BorderSide(
                  color:
                      AppColors.border,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
              child: Text(
                'Voltar para Home',
                style: AppTextStyles
                    .small
                    .copyWith(
                  color: AppColors
                      .primaryDark,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}