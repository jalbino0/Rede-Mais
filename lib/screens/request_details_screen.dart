import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/help_request.dart';
import '../services/auth_service.dart';
import '../services/help_offer_service.dart';
import '../services/request_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'create_request_screen.dart';

class RequestDetailsScreen extends StatefulWidget {
  final HelpRequest request;
  final bool isOwnRequest;

  const RequestDetailsScreen({
    super.key,
    required this.request,
    this.isOwnRequest = false,
  });

  @override
  State<RequestDetailsScreen> createState() =>
      _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  late HelpRequest _request;

  bool _hasOfferedHelp = false;
  bool _isLoadingOfferStatus = false;
  bool _isSubmittingHelp = false;
  bool _isAcceptingHelper = false;
  bool _isCompletingRequest = false;

  bool get _isCurrentUserAcceptedHelper {
    final user = AuthService.currentUser;

    if (user == null) {
      return false;
    }

    return _request.acceptedHelperId == user.uid;
  }

  bool get _canOfferHelp {
    return !widget.isOwnRequest &&
        _request.status == 'Ativo' &&
        !_isCurrentUserAcceptedHelper;
  }

  @override
  void initState() {
    super.initState();

    _request = widget.request;

    if (!widget.isOwnRequest && _request.status == 'Ativo') {
      _isLoadingOfferStatus = true;
      _loadHelpStatus();
    }
  }

  Future<void> _loadHelpStatus() async {
    final user = AuthService.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingOfferStatus = false;
      });

      return;
    }

    try {
      final hasOfferedHelp =
          await HelpOfferService.hasOfferedHelp(
        requestId: _request.id,
        helperId: user.uid,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _hasOfferedHelp = hasOfferedHelp;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _hasOfferedHelp = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOfferStatus = false;
        });
      }
    }
  }

  Future<void> _editRequest() async {
    final updatedRequest =
        await Navigator.of(context).push<HelpRequest>(
      MaterialPageRoute(
        builder: (context) => CreateRequestScreen(
          requestToEdit: _request,
        ),
      ),
    );

    if (updatedRequest == null || !mounted) {
      return;
    }

    setState(() {
      _request = updatedRequest;
    });
  }

  Future<void> _confirmHelp() async {
    if (_isSubmittingHelp ||
        _isLoadingOfferStatus ||
        !_canOfferHelp) {
      return;
    }

    final user = AuthService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Entre novamente para oferecer ajuda.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            0,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            4,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
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
                decoration: const BoxDecoration(
                  color: AppColors.secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volunteer_activism_outlined,
                  color: AppColors.secondaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Quer ajudar?',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Ao confirmar, ${_request.userName} saberá que você está disponível para ajudar com este pedido.',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancelar',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryDark,
                foregroundColor: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirmar ajuda',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmittingHelp = true;
    });

    try {
      final profile = await UserService.getUserProfile(
        user.uid,
      );

      final storedName =
          profile?['name']?.toString().trim() ?? '';

      final email = user.email?.trim() ?? '';

      final fallbackName = email.contains('@')
          ? email.split('@').first
          : 'Usuário';

      final helperName =
          storedName.isNotEmpty ? storedName : fallbackName;

      await HelpOfferService.offerHelp(
        requestId: _request.id,
        helperId: user.uid,
        helperName: helperName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _hasOfferedHelp = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sua disponibilidade para ajudar foi registrada.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível registrar sua ajuda. Tente novamente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingHelp = false;
        });
      }
    }
  }

  Future<void> _acceptHelper({
    required String helperId,
    required String helperName,
  }) async {
    if (_isAcceptingHelper) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            0,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            4,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
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
                decoration: const BoxDecoration(
                  color: AppColors.secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  color: AppColors.secondaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Aceitar ajuda?',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Ao aceitar a ajuda de $helperName, este pedido passará para Em andamento.',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancelar',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryDark,
                foregroundColor: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Aceitar ajuda',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isAcceptingHelper = true;
    });

    try {
      await RequestService.acceptHelper(
        requestId: _request.id,
        helperId: helperId,
        helperName: helperName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _request = HelpRequest(
          id: _request.id,
          userId: _request.userId,
          title: _request.title,
          description: _request.description,
          category: _request.category,
          userName: _request.userName,
          neighborhood: _request.neighborhood,
          latitude: _request.latitude,
          longitude: _request.longitude,
          time: _request.time,
          isUrgent: _request.isUrgent,
          status: 'Em andamento',
          acceptedHelperId: helperId,
          acceptedHelperName: helperName,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ajuda de $helperName aceita. O pedido está em andamento.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível aceitar a ajuda. Tente novamente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAcceptingHelper = false;
        });
      }
    }
  }

  Future<void> _completeRequest() async {
    if (_isCompletingRequest) {
      return;
    }

    final helperName =
        _request.acceptedHelperName?.trim().isNotEmpty == true
            ? _request.acceptedHelperName!
            : 'a pessoa que ajudou';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            0,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            4,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
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
                decoration: const BoxDecoration(
                  color: AppColors.secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.secondaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Finalizar pedido?',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Confirme que a ajuda de $helperName foi concluída. O pedido será movido para Finalizados.',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancelar',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryDark,
                foregroundColor: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Finalizar pedido',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isCompletingRequest = true;
    });

    try {
      await RequestService.completeRequest(
        requestId: _request.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _request = HelpRequest(
          id: _request.id,
          userId: _request.userId,
          title: _request.title,
          description: _request.description,
          category: _request.category,
          userName: _request.userName,
          neighborhood: _request.neighborhood,
          latitude: _request.latitude,
          longitude: _request.longitude,
          time: _request.time,
          isUrgent: _request.isUrgent,
          status: 'Finalizado',
          acceptedHelperId: _request.acceptedHelperId,
          acceptedHelperName: _request.acceptedHelperName,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pedido finalizado com sucesso.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível finalizar o pedido. Tente novamente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingRequest = false;
        });
      }
    }
  }

  void _goBack() {
    Navigator.of(context).pop(_request);
  }

  Widget _buildRequestStatusMessage() {
    if (widget.isOwnRequest) {
      return _OwnerHelpSection(
        request: _request,
        isAcceptingHelper: _isAcceptingHelper,
        onAcceptHelper: _acceptHelper,
      );
    }

    if (_isCurrentUserAcceptedHelper &&
        _request.status == 'Em andamento') {
      return _AcceptedHelpMessage(
        ownerName: _request.userName,
      );
    }

    if (_isCurrentUserAcceptedHelper &&
        _request.status == 'Finalizado') {
      return _FinishedHelpMessage(
        ownerName: _request.userName,
      );
    }

    if (_request.status != 'Ativo') {
      return const _UnavailableRequestMessage();
    }

    if (_hasOfferedHelp) {
      return _HelpOfferedMessage(
        userName: _request.userName,
      );
    }

    return const _AvailabilityMessage();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _DetailsHeader(
                onBack: _goBack,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    20,
                    18,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryHeader(
                        request: _request,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _request.title,
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _request.description,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _UserCard(
                        request: _request,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Localização aproximada',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 12),
                      _LocationCard(
                        neighborhood: _request.neighborhood,
                      ),
                      const SizedBox(height: 14),
                      const _PrivacyNotice(),
                      const SizedBox(height: 26),
                      _buildRequestStatusMessage(),
                    ],
                  ),
                ),
              ),
              if (widget.isOwnRequest &&
                  _request.status == 'Ativo')
                _EditButton(
                  onPressed: _editRequest,
                )
              else if (widget.isOwnRequest &&
                  _request.status == 'Em andamento')
                _CompleteButton(
                  isLoading: _isCompletingRequest,
                  onPressed: _completeRequest,
                )
              else if (_canOfferHelp)
                _HelpButton(
                  hasOfferedHelp: _hasOfferedHelp,
                  isLoading:
                      _isLoadingOfferStatus ||
                      _isSubmittingHelp,
                  onPressed: _confirmHelp,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _DetailsHeader({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

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
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.surface,
              size: 19,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'Detalhes do pedido',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.surface,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final HelpRequest request;

  const _CategoryHeader({
    required this.request,
  });

  bool get useGreen {
    return request.category == 'Mercado' ||
        request.category == 'Pet' ||
        request.category == 'Casa' ||
        request.category == 'Companhia';
  }

  IconData get categoryIcon {
    switch (request.category) {
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

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        useGreen ? AppColors.secondaryLight : AppColors.primaryLight;

    final foregroundColor =
        useGreen ? AppColors.secondaryDark : AppColors.primary;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            categoryIcon,
            color: foregroundColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          request.category,
          style: AppTextStyles.small.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (request.isUrgent) ...[
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'URGENTE',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.danger,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final HelpRequest request;

  const _UserCard({
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final initial = request.userName.isNotEmpty
        ? request.userName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.secondaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.userName,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.secondaryDark,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      request.neighborhood,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 17,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                request.time,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String neighborhood;

  const _LocationCard({
    required this.neighborhood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 20,
            child: Container(
              width: 76,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(
                  alpha: 0.75,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 18,
            child: Container(
              width: 92,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: Container(
              width: 104,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(
                  alpha: 0.75,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.surface,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    neighborhood,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Para sua segurança, mostramos apenas a região do pedido, nunca o endereço exato.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerHelpSection extends StatelessWidget {
  final HelpRequest request;
  final bool isAcceptingHelper;
  final Future<void> Function({
    required String helperId,
    required String helperName,
  }) onAcceptHelper;

  const _OwnerHelpSection({
    required this.request,
    required this.isAcceptingHelper,
    required this.onAcceptHelper,
  });

  @override
  Widget build(BuildContext context) {
    if (request.status == 'Em andamento') {
      return _AcceptedHelperCard(
        helperName:
            request.acceptedHelperName?.trim().isNotEmpty == true
                ? request.acceptedHelperName!
                : 'Usuário',
      );
    }

    if (request.status == 'Finalizado') {
      return _CompletedRequestMessage(
        helperName: request.acceptedHelperName,
      );
    }

    final user = AuthService.currentUser;

    if (user == null) {
      return const _OwnRequestMessage();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: HelpOfferService.watchOffersForRequest(
        requestId: request.id,
        requestOwnerId: user.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _OwnerOffersLoading();
        }

        if (snapshot.hasError) {
          return const _OwnRequestMessage();
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return const _OwnRequestMessage();
        }

        return _OffersReceivedCard(
          offers: offers,
          isAcceptingHelper: isAcceptingHelper,
          onAcceptHelper: onAcceptHelper,
        );
      },
    );
  }
}

class _OffersReceivedCard extends StatelessWidget {
  final List<Map<String, dynamic>> offers;
  final bool isAcceptingHelper;
  final Future<void> Function({
    required String helperId,
    required String helperName,
  }) onAcceptHelper;

  const _OffersReceivedCard({
    required this.offers,
    required this.isAcceptingHelper,
    required this.onAcceptHelper,
  });

  @override
  Widget build(BuildContext context) {
    final count = offers.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volunteer_activism_outlined,
                  size: 20,
                  color: AppColors.secondaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count == 1
                      ? 'Alguém quer ajudar'
                      : '$count pessoas querem ajudar',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.secondaryDark,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...offers.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final offer = entry.value;

              final helperId =
                  offer['helperId']?.toString().trim() ?? '';

              final rawName =
                  offer['helperName']?.toString().trim() ?? '';

              final helperName =
                  rawName.isEmpty ? 'Usuário' : rawName;

              final initial = helperName.isNotEmpty
                  ? helperName.substring(0, 1).toUpperCase()
                  : '?';

              return Column(
                children: [
                  if (index > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      child: Divider(
                        height: 1,
                        color: AppColors.border,
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          initial,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.secondaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              helperName,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Se ofereceu para ajudar com este pedido.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton.icon(
                      onPressed:
                          isAcceptingHelper || helperId.isEmpty
                              ? null
                              : () {
                                  onAcceptHelper(
                                    helperId: helperId,
                                    helperName: helperName,
                                  );
                                },
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppColors.secondaryDark,
                        foregroundColor: AppColors.surface,
                        disabledBackgroundColor:
                            AppColors.secondaryLight,
                        disabledForegroundColor:
                            AppColors.secondaryDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                      ),
                      icon: isAcceptingHelper
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.secondaryDark,
                              ),
                            )
                          : const Icon(
                              Icons.handshake_outlined,
                              size: 18,
                            ),
                      label: Text(
                        isAcceptingHelper
                            ? 'Aceitando...'
                            : 'Aceitar ajuda',
                        style: AppTextStyles.small.copyWith(
                          color: isAcceptingHelper
                              ? AppColors.secondaryDark
                              : AppColors.surface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AcceptedHelperCard extends StatelessWidget {
  final String helperName;

  const _AcceptedHelperCard({
    required this.helperName,
  });

  @override
  Widget build(BuildContext context) {
    final initial = helperName.isNotEmpty
        ? helperName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  color: AppColors.secondaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ajuda aceita',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.secondaryDark,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Em andamento',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      helperName,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Está ajudando você com este pedido.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.secondaryDark,
                size: 21,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcceptedHelpMessage extends StatelessWidget {
  final String ownerName;

  const _AcceptedHelpMessage({
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final name = ownerName.trim().isEmpty
        ? 'o responsável pelo pedido'
        : ownerName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  color: AppColors.secondaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sua ajuda foi aceita',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.secondaryDark,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Em andamento',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            '$name escolheu você para ajudar com este pedido.',
            style: AppTextStyles.small.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quando a ajuda for concluída, o responsável poderá finalizar o pedido.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishedHelpMessage extends StatelessWidget {
  final String ownerName;

  const _FinishedHelpMessage({
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final name = ownerName.trim().isEmpty
        ? 'O responsável pelo pedido'
        : ownerName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.secondaryDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pedido finalizado',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.secondaryDark,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Finalizado',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            '$name marcou esta ajuda como concluída.',
            style: AppTextStyles.small.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Obrigado por fazer parte da comunidade e ajudar alguém.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableRequestMessage extends StatelessWidget {
  const _UnavailableRequestMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este pedido não está mais disponível para novas ofertas de ajuda.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerOffersLoading extends StatelessWidget {
  const _OwnerOffersLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verificando ofertas de ajuda...',
              style: AppTextStyles.small,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityMessage extends StatelessWidget {
  const _AvailabilityMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.secondaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sua disponibilidade faz a diferença.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpOfferedMessage extends StatelessWidget {
  final String userName;

  const _HelpOfferedMessage({
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.secondaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Você se ofereceu para ajudar. Agora é só aguardar o retorno de $userName.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnRequestMessage extends StatelessWidget {
  const _OwnRequestMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: AppColors.primaryDark,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este pedido é seu. Quando alguém se oferecer para ajudar, aparecerá aqui.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedRequestMessage extends StatelessWidget {
  final String? helperName;

  const _CompletedRequestMessage({
    this.helperName,
  });

  @override
  Widget build(BuildContext context) {
    final name = helperName?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.secondaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name.isEmpty
                  ? 'Este pedido foi finalizado.'
                  : 'Este pedido foi finalizado com a ajuda de $name.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool hasOfferedHelp;
  final bool isLoading;

  const _HelpButton({
    required this.onPressed,
    required this.hasOfferedHelp,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        bottomPadding + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed:
              hasOfferedHelp || isLoading
                  ? null
                  : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.secondaryDark,
            foregroundColor: AppColors.surface,
            disabledBackgroundColor:
                AppColors.secondaryLight,
            disabledForegroundColor:
                AppColors.secondaryDark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondaryDark,
                  ),
                )
              : Icon(
                  hasOfferedHelp
                      ? Icons.check_circle_outline_rounded
                      : Icons.volunteer_activism_outlined,
                  size: 20,
                ),
          label: Text(
            isLoading
                ? 'Aguarde...'
                : hasOfferedHelp
                    ? 'Ajuda oferecida'
                    : 'Quero ajudar',
            style: AppTextStyles.small.copyWith(
              color:
                  hasOfferedHelp || isLoading
                      ? AppColors.secondaryDark
                      : AppColors.surface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        bottomPadding + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          icon: const Icon(
            Icons.edit_outlined,
            size: 19,
          ),
          label: Text(
            'Editar pedido',
            style: AppTextStyles.small.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _CompleteButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        bottomPadding + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.secondaryDark,
            foregroundColor: AppColors.surface,
            disabledBackgroundColor:
                AppColors.secondaryLight,
            disabledForegroundColor:
                AppColors.secondaryDark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondaryDark,
                  ),
                )
              : const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                ),
          label: Text(
            isLoading
                ? 'Finalizando...'
                : 'Finalizar pedido',
            style: AppTextStyles.small.copyWith(
              color: isLoading
                  ? AppColors.secondaryDark
                  : AppColors.surface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}