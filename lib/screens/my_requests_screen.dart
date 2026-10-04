import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/help_request.dart';
import '../services/auth_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'create_request_screen.dart';
import 'request_details_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  final VoidCallback? onGoHomeRequested;

  const MyRequestsScreen({
    super.key,
    this.onGoHomeRequested,
  });

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String _selectedTab = 'Ativos';

  List<_MyRequestItem> _buildRequests(
    List<HelpRequest> requests,
  ) {
    return requests
        .map(
          (request) => _MyRequestItem(
            request: request,
            status: _statusLabel(request.status),
            group: _statusGroup(request.status),
            publishedAt: _formatPublishedAt(
              request.time,
            ),
          ),
        )
        .toList();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Em andamento':
        return 'Em andamento';
      case 'Finalizado':
        return 'Finalizado';
      default:
        return 'Ativo';
    }
  }

  String _statusGroup(String status) {
    switch (status) {
      case 'Em andamento':
        return 'Em andamento';
      case 'Finalizado':
        return 'Finalizados';
      default:
        return 'Ativos';
    }
  }

  List<_MyRequestItem> _filterRequests(
    List<_MyRequestItem> requests,
  ) {
    return requests
        .where(
          (item) => item.group == _selectedTab,
        )
        .toList();
  }

  String _formatPublishedAt(String time) {
    if (time == 'Agora') {
      return 'Publicado agora';
    }

    if (time.startsWith('Há ')) {
      return 'Publicado ${time.toLowerCase()}';
    }

    return 'Publicado $time';
  }

  void _openCreateRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateRequestScreen(
          onGoHomeRequested: widget.onGoHomeRequested,
        ),
      ),
    );
  }

  Future<void> _openRequestDetails(
    _MyRequestItem item,
  ) async {
    final updatedRequest =
        await Navigator.of(context).push<HelpRequest>(
      MaterialPageRoute(
        builder: (context) => RequestDetailsScreen(
          request: item.request,
          isOwnRequest: true,
        ),
      ),
    );

    if (updatedRequest == null || !mounted) {
      return;
    }

    try {
      await RequestService.updateRequest(
        updatedRequest,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível atualizar o pedido. Tente novamente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                stream: RequestService.watchUserRequests(
                  user.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _RequestsContent(
                      selectedTab: _selectedTab,
                      requests: const [],
                      isLoading: false,
                      hasError: true,
                      onTabSelected: (tab) {
                        setState(() {
                          _selectedTab = tab;
                        });
                      },
                      onCreateRequest: _openCreateRequest,
                      onViewDetails: _openRequestDetails,
                    );
                  }

                  final allRequests = _buildRequests(
                    snapshot.data ?? [],
                  );

                  final filteredRequests = _filterRequests(
                    allRequests,
                  );

                  return _RequestsContent(
                    selectedTab: _selectedTab,
                    requests: filteredRequests,
                    isLoading:
                        snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData,
                    hasError: false,
                    onTabSelected: (tab) {
                      setState(() {
                        _selectedTab = tab;
                      });
                    },
                    onCreateRequest: _openCreateRequest,
                    onViewDetails: _openRequestDetails,
                  );
                },
              ),
      ),
    );
  }
}

class _RequestsContent extends StatelessWidget {
  final String selectedTab;
  final List<_MyRequestItem> requests;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<String> onTabSelected;
  final VoidCallback onCreateRequest;
  final ValueChanged<_MyRequestItem> onViewDetails;

  const _RequestsContent({
    required this.selectedTab,
    required this.requests,
    required this.isLoading,
    required this.hasError,
    required this.onTabSelected,
    required this.onCreateRequest,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: _MyRequestsHeader(),
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
                _StatusTabs(
                  selectedTab: selectedTab,
                  onSelected: onTabSelected,
                ),
                const SizedBox(height: 22),
                _SectionHeader(
                  selectedTab: selectedTab,
                  count: requests.length,
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const _LoadingState()
                else if (hasError)
                  const _ErrorState()
                else if (requests.isEmpty)
                  const _EmptyState()
                else
                  ...requests.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: _RequestCard(
                        item: item,
                        onViewDetails: () {
                          onViewDetails(item);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _NewRequestButton(
                  onPressed: onCreateRequest,
                ),
              ],
            ),
          ),
        ),
      ],
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
          child: _MyRequestsHeader(),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 30,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.dangerLight,
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
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Entre novamente para acessar seus pedidos.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small,
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

class _MyRequestsHeader extends StatelessWidget {
  const _MyRequestsHeader();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        topPadding + 14,
        18,
        20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meus pedidos',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.surface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Acompanhe seus pedidos e as ajudas que chegam.',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onSelected;

  const _StatusTabs({
    required this.selectedTab,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = [
      'Ativos',
      'Em andamento',
      'Finalizados',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: tabs.map(
          (tab) {
            final selected = tab == selectedTab;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(tab),
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryDark
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tab,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? AppColors.surface
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String selectedTab;
  final int count;

  const _SectionHeader({
    required this.selectedTab,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    String title;

    switch (selectedTab) {
      case 'Em andamento':
        title = 'Pedidos em andamento';
        break;
      case 'Finalizados':
        title = 'Pedidos finalizados';
        break;
      default:
        title = 'Seus pedidos ativos';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.h3,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$count ${count == 1 ? 'pedido' : 'pedidos'}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final _MyRequestItem item;
  final VoidCallback onViewDetails;

  const _RequestCard({
    required this.item,
    required this.onViewDetails,
  });

  bool get _isCompleted {
    return item.status == 'Finalizado';
  }

  bool get _isInProgress {
    return item.status == 'Em andamento';
  }

  IconData get _categoryIcon {
    switch (item.request.category) {
      case 'Mercado':
        return Icons.shopping_cart_outlined;
      case 'Pet':
        return Icons.pets_outlined;
      case 'Transporte':
        return Icons.directions_car_outlined;
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

  bool get _useGreen {
    return item.request.category == 'Mercado' ||
        item.request.category == 'Pet' ||
        item.request.category == 'Casa' ||
        item.request.category == 'Companhia';
  }

  Color get _statusBackground {
    if (_isCompleted) {
      return AppColors.secondaryLight;
    }

    if (_isInProgress) {
      return AppColors.primaryLight;
    }

    return AppColors.primaryLight;
  }

  Color get _statusColor {
    if (_isCompleted) {
      return AppColors.secondaryDark;
    }

    return AppColors.primaryDark;
  }

  IconData get _statusIcon {
    if (_isCompleted) {
      return Icons.check_circle_outline_rounded;
    }

    if (_isInProgress) {
      return Icons.sync_rounded;
    }

    return Icons.circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final categoryBackground =
        _useGreen ? AppColors.secondaryLight : AppColors.primaryLight;

    final categoryColor =
        _useGreen ? AppColors.secondaryDark : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: categoryBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _categoryIcon,
                  size: 16,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.request.category,
                style: AppTextStyles.caption.copyWith(
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.request.isUrgent) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'URGENTE',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.danger,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                item.publishedAt,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            item.request.title,
            style: AppTextStyles.h3.copyWith(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _statusBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _statusIcon,
                  size: 14,
                  color: _statusColor,
                ),
                const SizedBox(width: 5),
                Text(
                  item.status,
                  style: AppTextStyles.caption.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onViewDetails,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
              ),
              child: Row(
                children: [
                  Text(
                    'Ver detalhes',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewRequestButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NewRequestButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondaryDark,
          foregroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(
          Icons.add_rounded,
          size: 20,
        ),
        label: Text(
          'Novo pedido',
          style: AppTextStyles.small.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
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
            style: AppTextStyles.h3.copyWith(
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
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum pedido por aqui',
            style: AppTextStyles.h3.copyWith(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Quando houver pedidos nessa etapa, eles aparecerão aqui.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}

class _MyRequestItem {
  final HelpRequest request;
  final String status;
  final String group;
  final String publishedAt;

  const _MyRequestItem({
    required this.request,
    required this.status,
    required this.group,
    required this.publishedAt,
  });
}