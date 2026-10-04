import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/help_request.dart';
import '../services/auth_service.dart';
import '../services/distance_service.dart';
import '../services/request_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'create_request_screen.dart';
import 'request_details_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onExploreTap;

  const HomeScreen({
    super.key,
    this.onExploreTap,
  });

  void _openCreateRequest(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const CreateRequestScreen(),
      ),
    );
  }

  void _openRequest(
    BuildContext context,
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

  Widget _buildCommunityRequests(
    BuildContext context,
    String userId,
  ) {
    return StreamBuilder<
        Map<String, dynamic>?>(
      stream: UserService.watchUserProfile(
        userId,
      ),
      builder: (
        context,
        profileSnapshot,
      ) {
        if (profileSnapshot.connectionState ==
                ConnectionState.waiting &&
            !profileSnapshot.hasData) {
          return _CommunityRequestsSection(
            requests: const [],
            isLoading: true,
            hasError: false,
            onViewAll: () {
              onExploreTap?.call();
            },
            onViewRequest: (request) {
              _openRequest(
                context,
                request,
              );
            },
          );
        }

        if (profileSnapshot.hasError ||
            profileSnapshot.data == null) {
          return _CommunityRequestsSection(
            requests: const [],
            isLoading: false,
            hasError: true,
            onViewAll: () {
              onExploreTap?.call();
            },
            onViewRequest: (request) {
              _openRequest(
                context,
                request,
              );
            },
          );
        }

        final profile =
            profileSnapshot.data!;

        final latitude =
            (profile['latitude'] as num?)
                ?.toDouble();

        final longitude =
            (profile['longitude'] as num?)
                ?.toDouble();

        if (!_hasValidCoordinates(
          latitude: latitude,
          longitude: longitude,
        )) {
          return _CommunityRequestsSection(
            requests: const [],
            isLoading: false,
            hasError: true,
            onViewAll: () {
              onExploreTap?.call();
            },
            onViewRequest: (request) {
              _openRequest(
                context,
                request,
              );
            },
          );
        }

        return StreamBuilder<
            List<HelpRequest>>(
          stream: RequestService
              .watchCommunityRequests(
            excludeUserId: userId,
            userLatitude: latitude,
            userLongitude: longitude,
            radiusKm:
                DistanceService.defaultRadiusKm,
          ),
          builder: (
            context,
            requestSnapshot,
          ) {
            final isLoading =
                requestSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !requestSnapshot.hasData;

            final requests =
                (requestSnapshot.data ?? [])
                    .take(2)
                    .toList();

            return _CommunityRequestsSection(
              requests: requests,
              isLoading: isLoading,
              hasError:
                  requestSnapshot.hasError,
              onViewAll: () {
                onExploreTap?.call();
              },
              onViewRequest: (request) {
                _openRequest(
                  context,
                  request,
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
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
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: _HomeHeader(),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24,
              ),
              sliver: SliverList(
                delegate:
                    SliverChildListDelegate(
                  [
                    _MainActions(
                      onCreateRequest: () {
                        _openCreateRequest(
                          context,
                        );
                      },
                      onExplore: () {
                        onExploreTap?.call();
                      },
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    _CategoriesSection(
                      onViewAll: () {
                        onExploreTap?.call();
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    if (user == null)
                      _CommunityRequestsSection(
                        requests:
                            const [],
                        isLoading: false,
                        hasError: true,
                        onViewAll: () {
                          onExploreTap
                              ?.call();
                        },
                        onViewRequest:
                            (request) {
                          _openRequest(
                            context,
                            request,
                          );
                        },
                      )
                    else
                      _buildCommunityRequests(
                        context,
                        user.uid,
                      ),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        topPadding + 14,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Rede+',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Olá, vizinho!',
            style:
                AppTextStyles.small.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Como podemos ajudar?',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.surface,
              fontSize: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainActions extends StatelessWidget {
  final VoidCallback onCreateRequest;
  final VoidCallback onExplore;

  const _MainActions({
    required this.onCreateRequest,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionCard(
          title: 'Preciso de ajuda',
          description: 'Publique um pedido',
          icon: Icons.add_circle_outline,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          iconBackgroundColor:
              AppColors.surface,
          iconColor: AppColors.primary,
          onTap: onCreateRequest,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          title: 'Quero ajudar',
          description:
              'Veja pedidos em até 3 km',
          icon:
              Icons.volunteer_activism_outlined,
          backgroundColor:
              AppColors.secondaryDark,
          foregroundColor: AppColors.surface,
          iconBackgroundColor:
              AppColors.surface,
          iconColor: AppColors.secondaryDark,
          onTap: onExplore,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      iconBackgroundColor,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles
                          .h3
                          .copyWith(
                        fontSize: 16,
                        color:
                            foregroundColor,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTextStyles
                          .small
                          .copyWith(
                        color:
                            foregroundColor
                                .withValues(
                          alpha: 0.82,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons
                    .arrow_forward_ios_rounded,
                color: foregroundColor
                    .withValues(
                  alpha: 0.88,
                ),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesSection
    extends StatelessWidget {
  final VoidCallback onViewAll;

  const _CategoriesSection({
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    const categories = [
      _CategoryData(
        label: 'Mercado',
        icon: Icons.shopping_cart_outlined,
        useGreen: true,
      ),
      _CategoryData(
        label: 'Pet',
        icon: Icons.pets_outlined,
        useGreen: true,
      ),
      _CategoryData(
        label: 'Transporte',
        icon: Icons.directions_car_outlined,
        useGreen: false,
      ),
      _CategoryData(
        label: 'Casa',
        icon: Icons.home_outlined,
        useGreen: true,
      ),
      _CategoryData(
        label: 'Tecnologia',
        icon: Icons.computer_outlined,
        useGreen: false,
      ),
      _CategoryData(
        label: 'Companhia',
        icon: Icons.groups_outlined,
        useGreen: true,
      ),
      _CategoryData(
        label: 'Outros',
        icon: Icons.more_horiz_rounded,
        useGreen: false,
      ),
    ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Categorias',
                style: AppTextStyles.h2,
              ),
            ),
            InkWell(
              onTap: onViewAll,
              borderRadius:
                  BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: Text(
                  'Ver todas',
                  style: AppTextStyles
                      .caption
                      .copyWith(
                    color:
                        AppColors.primary,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            const crossAxisSpacing =
                8.0;

            const runSpacing = 12.0;

            final itemWidth =
                (constraints.maxWidth -
                        (crossAxisSpacing *
                            3)) /
                    4;

            return Wrap(
              spacing: crossAxisSpacing,
              runSpacing: runSpacing,
              children: categories
                  .map(
                    (category) =>
                        SizedBox(
                      width: itemWidth,
                      child:
                          _CategoryItem(
                        label:
                            category.label,
                        icon:
                            category.icon,
                        useGreen:
                            category
                                .useGreen,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryData {
  final String label;
  final IconData icon;
  final bool useGreen;

  const _CategoryData({
    required this.label,
    required this.icon,
    required this.useGreen,
  });
}

class _CategoryItem
    extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool useGreen;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.useGreen,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = useGreen
        ? AppColors.secondaryLight
        : AppColors.primaryLight;

    final iconColor = useGreen
        ? AppColors.secondaryDark
        : AppColors.primary;

    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 21,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style:
              AppTextStyles.caption.copyWith(
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _CommunityRequestsSection
    extends StatelessWidget {
  final List<HelpRequest> requests;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onViewAll;
  final ValueChanged<HelpRequest>
      onViewRequest;

  const _CommunityRequestsSection({
    required this.requests,
    required this.isLoading,
    required this.hasError,
    required this.onViewAll,
    required this.onViewRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pedidos perto de você',
                style: AppTextStyles.h2,
              ),
            ),
            InkWell(
              onTap: onViewAll,
              borderRadius:
                  BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: Text(
                  'Ver todos',
                  style: AppTextStyles
                      .caption
                      .copyWith(
                    color:
                        AppColors.primary,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const _RequestsLoadingState()
        else if (hasError)
          const _RequestsErrorState()
        else if (requests.isEmpty)
          const _RequestsEmptyState()
        else
          ...requests.map(
            (request) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child:
                  _CommunityRequestCard(
                request: request,
                onTap: () {
                  onViewRequest(
                    request,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _CommunityRequestCard
    extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onTap;

  const _CommunityRequestCard({
    required this.request,
    required this.onTap,
  });

  IconData get icon {
    switch (request.category) {
      case 'Pet':
        return Icons.pets_outlined;
      case 'Tecnologia':
        return Icons.computer_outlined;
      case 'Mercado':
        return Icons.shopping_cart_outlined;
      case 'Transporte':
        return Icons.directions_car_outlined;
      case 'Casa':
        return Icons.home_outlined;
      case 'Companhia':
        return Icons.groups_outlined;
      default:
        return Icons
            .volunteer_activism_outlined;
    }
  }

  bool get useGreen {
    return request.category == 'Pet' ||
        request.category == 'Mercado' ||
        request.category == 'Casa' ||
        request.category ==
            'Companhia';
  }

  @override
  Widget build(BuildContext context) {
    final iconBackgroundColor = useGreen
        ? AppColors.secondaryLight
        : AppColors.primaryLight;

    final iconColor = useGreen
        ? AppColors.secondaryDark
        : AppColors.primary;

    final categoryColor = useGreen
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
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request
                                .category,
                            style:
                                AppTextStyles
                                    .caption
                                    .copyWith(
                              color:
                                  categoryColor,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                        Text(
                          request.time,
                          style:
                              AppTextStyles
                                  .caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.title,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: AppTextStyles
                          .small
                          .copyWith(
                        color:
                            AppColors.text,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.userName} · ${request.neighborhood}',
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppTextStyles
                              .caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 14,
                color:
                    AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestsLoadingState
    extends StatelessWidget {
  const _RequestsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 28,
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
          width: 24,
          height: 24,
          child:
              CircularProgressIndicator(
            strokeWidth: 2.2,
            color:
                AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _RequestsErrorState
    extends StatelessWidget {
  const _RequestsErrorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
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
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Não foi possível carregar os pedidos próximos.',
              style:
                  AppTextStyles.small.copyWith(
                color:
                    AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsEmptyState
    extends StatelessWidget {
  const _RequestsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                const BoxDecoration(
              color:
                  AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .volunteer_activism_outlined,
              color:
                  AppColors.secondaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Ainda não há pedidos ativos em até 3 km de você.',
              style:
                  AppTextStyles.small.copyWith(
                color:
                    AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}