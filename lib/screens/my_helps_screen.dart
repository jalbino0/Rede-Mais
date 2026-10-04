import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/help_request.dart';
import '../services/auth_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'request_details_screen.dart';

class MyHelpsScreen extends StatelessWidget {
  const MyHelpsScreen({super.key});

  void _openRequest(
    BuildContext context,
    HelpRequest request,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RequestDetailsScreen(
          request: request,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: user == null
            ? const _SessionUnavailable()
            : StreamBuilder<List<HelpRequest>>(
                stream: RequestService.watchAcceptedRequests(
                  user.uid,
                ),
                builder: (context, snapshot) {
                  final isLoading =
                      snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData;

                  if (isLoading) {
                    return const _MyHelpsContent(
                      requests: [],
                      isLoading: true,
                      hasError: false,
                    );
                  }

                  if (snapshot.hasError) {
                    return const _MyHelpsContent(
                      requests: [],
                      isLoading: false,
                      hasError: true,
                    );
                  }

                  return _MyHelpsContent(
                    requests: snapshot.data ?? [],
                    isLoading: false,
                    hasError: false,
                    onRequestTap: (request) {
                      _openRequest(
                        context,
                        request,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _MyHelpsContent extends StatelessWidget {
  final List<HelpRequest> requests;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<HelpRequest>? onRequestTap;

  const _MyHelpsContent({
    required this.requests,
    required this.isLoading,
    required this.hasError,
    this.onRequestTap,
  });

  int get _inProgressCount {
    return requests
        .where(
          (request) =>
              request.status == 'Em andamento',
        )
        .length;
  }

  int get _completedCount {
    return requests
        .where(
          (request) =>
              request.status == 'Finalizado',
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: _MyHelpsHeader(),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            24,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                if (!isLoading && !hasError)
                  _SummaryCard(
                    total: requests.length,
                    inProgress:
                        _inProgressCount,
                    completed:
                        _completedCount,
                  ),
                if (!isLoading && !hasError)
                  const SizedBox(height: 22),
                if (isLoading)
                  const _LoadingState()
                else if (hasError)
                  const _ErrorState()
                else if (requests.isEmpty)
                  const _EmptyState()
                else ...[
                  Text(
                    'Ajudas que você acompanha',
                    style:
                        AppTextStyles.h3.copyWith(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Veja os pedidos em que sua ajuda foi aceita.',
                    style:
                        AppTextStyles.small.copyWith(
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...requests.map(
                    (request) => Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: _HelpCard(
                        request: request,
                        onTap: () {
                          onRequestTap?.call(
                            request,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MyHelpsHeader extends StatelessWidget {
  const _MyHelpsHeader();

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.paddingOf(context).top;

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
            'Minhas ajudas',
            style:
                AppTextStyles.small.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Acompanhe onde você está ajudando',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.surface,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Veja os pedidos em andamento e as ajudas que já foram concluídas.',
            style:
                AppTextStyles.small.copyWith(
              color: AppColors.primaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int inProgress;
  final int completed;

  const _SummaryCard({
    required this.total,
    required this.inProgress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary
              .withValues(
            alpha: 0.24,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              icon: Icons
                  .volunteer_activism_outlined,
              value: total,
              label: 'Total',
            ),
          ),
          Container(
            width: 1,
            height: 42,
            color: AppColors.border,
          ),
          Expanded(
            child: _SummaryItem(
              icon: Icons.sync_rounded,
              value: inProgress,
              label: 'Em andamento',
            ),
          ),
          Container(
            width: 1,
            height: 42,
            color: AppColors.border,
          ),
          Expanded(
            child: _SummaryItem(
              icon: Icons
                  .check_circle_outline_rounded,
              value: completed,
              label: 'Finalizadas',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.secondaryDark,
        ),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.secondaryDark,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style:
              AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _HelpCard extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onTap;

  const _HelpCard({
    required this.request,
    required this.onTap,
  });

  bool get _isCompleted {
    return request.status == 'Finalizado';
  }

  @override
  Widget build(BuildContext context) {
    final ownerName =
        request.userName.trim().isEmpty
            ? 'Usuário'
            : request.userName.trim();

    final initial =
        ownerName.substring(0, 1).toUpperCase();

    final statusColor = _isCompleted
        ? AppColors.secondaryDark
        : AppColors.primaryDark;

    final statusBackground = _isCompleted
        ? AppColors.secondaryLight
        : AppColors.primaryLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(17),
        child: Ink(
          width: double.infinity,
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(17),
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
                  Expanded(
                    child: Text(
                      request.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          AppTextStyles.h3.copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          _isCompleted
                              ? Icons
                                  .check_circle_outline_rounded
                              : Icons.sync_rounded,
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          request.status,
                          style:
                              AppTextStyles
                                  .caption
                                  .copyWith(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                request.description,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    AppTextStyles.small.copyWith(
                  color:
                      AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(
                height: 1,
                color: AppColors.border,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment:
                        Alignment.center,
                    decoration:
                        const BoxDecoration(
                      color: AppColors
                          .secondaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initial,
                      style:
                          AppTextStyles
                              .caption
                              .copyWith(
                        color: AppColors
                            .secondaryDark,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          ownerName,
                          style:
                              AppTextStyles
                                  .caption
                                  .copyWith(
                            color:
                                AppColors.text,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          request.neighborhood,
                          style:
                              AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 14,
                    color:
                        AppColors.textSecondary,
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 32,
      ),
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
          Container(
            width: 48,
            height: 48,
            decoration:
                const BoxDecoration(
              color: AppColors.dangerLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 34,
      ),
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
          Container(
            width: 52,
            height: 52,
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
              size: 25,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Nenhuma ajuda por aqui',
            style:
                AppTextStyles.h3.copyWith(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quando alguém aceitar sua ajuda, o pedido aparecerá aqui para você acompanhar.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}

class _SessionUnavailable extends StatelessWidget {
  const _SessionUnavailable();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: _MyHelpsHeader(),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            28,
            16,
            24,
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 30,
              ),
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
                      Icons.person_off_outlined,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sessão indisponível',
                    style:
                        AppTextStyles.h3.copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Entre novamente para acompanhar suas ajudas.',
                    textAlign:
                        TextAlign.center,
                    style:
                        AppTextStyles.small,
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