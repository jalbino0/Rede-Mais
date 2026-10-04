import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/help_request.dart';
import '../services/auth_service.dart';
import '../services/distance_service.dart';
import '../services/request_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'request_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() =>
      _ExploreScreenState();
}

class _ExploreScreenState
    extends State<ExploreScreen> {
  String selectedCategory = 'Todos';

  final List<String> categories = const [
    'Todos',
    'Mercado',
    'Pet',
    'Transporte',
    'Casa',
    'Tecnologia',
    'Companhia',
    'Outros',
  ];

  List<HelpRequest> _filterRequests(
    List<HelpRequest> requests,
  ) {
    if (selectedCategory == 'Todos') {
      return requests;
    }

    return requests
        .where(
          (request) =>
              request.category ==
              selectedCategory,
        )
        .toList();
  }

  bool _hasValidCoordinates({
    required double? latitude,
    required double? longitude,
  }) {
    if (latitude == null ||
        longitude == null) {
      return false;
    }

    if (!latitude.isFinite ||
        !longitude.isFinite) {
      return false;
    }

    if (latitude < -90 ||
        latitude > 90) {
      return false;
    }

    if (longitude < -180 ||
        longitude > 180) {
      return false;
    }

    if (latitude == 0 &&
        longitude == 0) {
      return false;
    }

    return true;
  }

  void _openRequest(
    HelpRequest request,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            RequestDetailsScreen(
          request: request,
        ),
      ),
    );
  }

  Widget _buildExploreWithLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) {
    return StreamBuilder<List<HelpRequest>>(
      stream:
          RequestService.watchCommunityRequests(
        excludeUserId: userId,
        userLatitude: latitude,
        userLongitude: longitude,
        radiusKm:
            DistanceService.defaultRadiusKm,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ExploreContent(
            categories: categories,
            selectedCategory:
                selectedCategory,
            requests: const [],
            isLoading: false,
            hasError: true,
            onCategorySelected:
                (category) {
              setState(() {
                selectedCategory =
                    category;
              });
            },
            onRequestTap: _openRequest,
          );
        }

        final requests =
            _filterRequests(
          snapshot.data ?? [],
        );

        return _ExploreContent(
          categories: categories,
          selectedCategory:
              selectedCategory,
          requests: requests,
          isLoading:
              snapshot.connectionState ==
                      ConnectionState
                          .waiting &&
                  !snapshot.hasData,
          hasError: false,
          onCategorySelected:
              (category) {
            setState(() {
              selectedCategory =
                  category;
            });
          },
          onRequestTap: _openRequest,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

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
        body: user == null
            ? const _SessionUnavailable()
            : StreamBuilder<
                Map<String, dynamic>?>(
                stream:
                    UserService
                        .watchUserProfile(
                  user.uid,
                ),
                builder:
                    (context, snapshot) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return _ExploreContent(
                      categories:
                          categories,
                      selectedCategory:
                          selectedCategory,
                      requests:
                          const [],
                      isLoading: true,
                      hasError: false,
                      onCategorySelected:
                          (category) {
                        setState(() {
                          selectedCategory =
                              category;
                        });
                      },
                      onRequestTap:
                          _openRequest,
                    );
                  }

                  if (snapshot.hasError) {
                    return const _LocationUnavailable(
                      message:
                          'Não foi possível carregar sua localização. Verifique sua conexão e tente novamente.',
                    );
                  }

                  final profile =
                      snapshot.data;

                  if (profile == null) {
                    return const _LocationUnavailable(
                      message:
                          'Não encontramos seu perfil. Entre novamente para continuar.',
                    );
                  }

                  final latitude =
                      (profile['latitude']
                              as num?)
                          ?.toDouble();

                  final longitude =
                      (profile['longitude']
                              as num?)
                          ?.toDouble();

                  if (!_hasValidCoordinates(
                    latitude: latitude,
                    longitude:
                        longitude,
                  )) {
                    return const _LocationUnavailable(
                      message:
                          'Sua localização aproximada ainda não está disponível. Vá em Perfil, edite seu CEP e salve novamente.',
                    );
                  }

                  return _buildExploreWithLocation(
                    userId: user.uid,
                    latitude: latitude!,
                    longitude: longitude!,
                  );
                },
              ),
      ),
    );
  }
}

class _ExploreContent
    extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final List<HelpRequest> requests;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<String>
      onCategorySelected;
  final ValueChanged<HelpRequest>
      onRequestTap;

  const _ExploreContent({
    required this.categories,
    required this.selectedCategory,
    required this.requests,
    required this.isLoading,
    required this.hasError,
    required this.onCategorySelected,
    required this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: _ExploreHeader(),
        ),
        SliverPadding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            24,
          ),
          sliver: SliverList(
            delegate:
                SliverChildListDelegate(
              [
                Text(
                  'Pedidos disponíveis',
                  style: AppTextStyles.h3
                      .copyWith(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Encontre pedidos ativos em até 3 km da sua região.',
                  style: AppTextStyles.small
                      .copyWith(
                    color: AppColors
                        .textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                _CategoryFilters(
                  categories:
                      categories,
                  selectedCategory:
                      selectedCategory,
                  onSelected:
                      onCategorySelected,
                ),
                const SizedBox(
                  height: 16,
                ),
                const _CommunityIndicator(),
                const SizedBox(
                  height: 18,
                ),
                if (isLoading)
                  const _LoadingState()
                else if (hasError)
                  const _ErrorState()
                else if (requests.isEmpty)
                  const _EmptyState()
                else
                  ...requests.map(
                    (request) =>
                        Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        bottom: 10,
                      ),
                      child:
                          _RequestCard(
                        request:
                            request,
                        onTap: () {
                          onRequestTap(
                            request,
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(
                  height: 6,
                ),
                const _CommunityMessage(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionUnavailable
    extends StatelessWidget {
  const _SessionUnavailable();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: _ExploreHeader(),
        ),
        SliverPadding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            28,
            16,
            24,
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 22,
                vertical: 30,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.surface,
                borderRadius:
                    BorderRadius
                        .circular(18),
                border: Border.all(
                  color:
                      AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        const BoxDecoration(
                      color: AppColors
                          .dangerLight,
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons
                          .person_off_outlined,
                      color: AppColors
                          .danger,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    'Sessão indisponível',
                    style: AppTextStyles
                        .h3
                        .copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    'Entre novamente para explorar os pedidos.',
                    textAlign:
                        TextAlign.center,
                    style: AppTextStyles
                        .small,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationUnavailable
    extends StatelessWidget {
  final String message;

  const _LocationUnavailable({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: _ExploreHeader(),
        ),
        SliverPadding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            28,
            16,
            24,
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 22,
                vertical: 30,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.surface,
                borderRadius:
                    BorderRadius
                        .circular(18),
                border: Border.all(
                  color:
                      AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        const BoxDecoration(
                      color: AppColors
                          .primaryLight,
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons
                          .location_off_outlined,
                      color: AppColors
                          .primaryDark,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    'Localização indisponível',
                    style: AppTextStyles
                        .h3
                        .copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExploreHeader
    extends StatelessWidget {
  const _ExploreHeader();

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.paddingOf(context)
            .top;

    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: EdgeInsets.fromLTRB(
        18,
        topPadding + 12,
        18,
        20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Explorar pedidos',
            style: AppTextStyles.small
                .copyWith(
              color:
                  AppColors.primaryLight,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ajude alguém perto de você',
            style:
                AppTextStyles.h1.copyWith(
              color: AppColors.surface,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Veja pedidos ativos de outras pessoas em um raio de até 3 km.',
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

class _CategoryFilters
    extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String>
      onSelected;

  const _CategoryFilters({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 8,
      children: categories.map(
        (category) {
          final selected =
              category ==
                  selectedCategory;

          return Material(
            color:
                Colors.transparent,
            child: InkWell(
              onTap: () =>
                  onSelected(
                category,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              child: Ink(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration:
                    BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius:
                      BorderRadius
                          .circular(18),
                  border: Border.all(
                    color: selected
                        ? AppColors
                            .primary
                        : AppColors
                            .border,
                  ),
                ),
                child: Text(
                  category,
                  style: AppTextStyles
                      .caption
                      .copyWith(
                    color: selected
                        ? AppColors
                            .surface
                        : AppColors
                            .text,
                    fontWeight:
                        selected
                            ? FontWeight
                                .w600
                            : FontWeight
                                .w400,
                  ),
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }
}

class _CommunityIndicator
    extends StatelessWidget {
  const _CommunityIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.near_me_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pedidos ativos em até 3 km de você',
              style: AppTextStyles.small
                  .copyWith(
                color:
                    AppColors.primaryDark,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard
    extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.onTap,
  });

  bool get useGreen {
    return request.category ==
            'Mercado' ||
        request.category == 'Pet' ||
        request.category == 'Casa' ||
        request.category ==
            'Companhia';
  }

  IconData get categoryIcon {
    switch (request.category) {
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
        return Icons
            .computer_outlined;
      case 'Companhia':
        return Icons.groups_outlined;
      default:
        return Icons
            .more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        request.userName.trim();

    final userInitial =
        userName.isNotEmpty
            ? userName
                .substring(0, 1)
                .toUpperCase()
            : '?';

    final categoryBackground =
        useGreen
            ? AppColors.secondaryLight
            : AppColors.primaryLight;

    final categoryColor =
        useGreen
            ? AppColors.secondaryDark
            : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding:
              const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration:
                        BoxDecoration(
                      color:
                          categoryBackground,
                      shape:
                          BoxShape.circle,
                    ),
                    child: Icon(
                      categoryIcon,
                      size: 15,
                      color:
                          categoryColor,
                    ),
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Text(
                    request.category,
                    style: AppTextStyles
                        .caption
                        .copyWith(
                      color:
                          categoryColor,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  if (request
                      .isUrgent) ...[
                    const SizedBox(
                      width: 7,
                    ),
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
                                .circular(
                          12,
                        ),
                      ),
                      child: Text(
                        'URGENTE',
                        style:
                            AppTextStyles
                                .caption
                                .copyWith(
                          color:
                              AppColors
                                  .danger,
                          fontSize: 10,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    request.time,
                    style: AppTextStyles
                        .caption,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                request.title,
                style: AppTextStyles.h3
                    .copyWith(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                request.description,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: AppTextStyles.small
                    .copyWith(
                  height: 1.35,
                  color: AppColors
                      .textSecondary,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration:
                        const BoxDecoration(
                      color: AppColors
                          .secondaryLight,
                      shape:
                          BoxShape.circle,
                    ),
                    alignment:
                        Alignment.center,
                    child: Text(
                      userInitial,
                      style:
                          AppTextStyles
                              .caption
                              .copyWith(
                        color: AppColors
                            .secondaryDark,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          userName.isEmpty
                              ? 'Usuário'
                              : userName,
                          style:
                              AppTextStyles
                                  .caption
                                  .copyWith(
                            color: AppColors
                                .text,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                        const SizedBox(
                          height: 1,
                        ),
                        Text(
                          request
                              .neighborhood,
                          style:
                              AppTextStyles
                                  .caption,
                        ),
                      ],
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
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState
    extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child:
              CircularProgressIndicator(
            strokeWidth: 2.4,
            color:
                AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
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
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Não foi possível carregar',
            style:
                AppTextStyles.h3.copyWith(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Verifique sua conexão e tente novamente.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
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
            width: 34,
            height: 34,
            decoration:
                const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .favorite_border_rounded,
              size: 18,
              color:
                  AppColors.secondaryDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Uma pequena ajuda pode mudar o dia de alguém.',
              style: AppTextStyles
                  .caption
                  .copyWith(
                color:
                    AppColors.secondaryDark,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState
    extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 36,
            color:
                AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            'Nenhum pedido encontrado',
            style:
                AppTextStyles.h3.copyWith(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Não encontramos pedidos ativos em até 3 km para esta categoria.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}