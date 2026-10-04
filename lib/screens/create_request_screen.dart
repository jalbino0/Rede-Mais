import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/help_request.dart';
import '../services/auth_service.dart';
import '../services/cep_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'request_published_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  final HelpRequest? requestToEdit;
  final VoidCallback? onGoHomeRequested;

  const CreateRequestScreen({
    super.key,
    this.requestToEdit,
    this.onGoHomeRequested,
  });

  bool get isEditing => requestToEdit != null;

  @override
  State<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  String _selectedCategory = 'Mercado';
  bool _isUrgent = false;

  String? _neighborhood;
  bool _isLoadingNeighborhood = false;
  String? _locationError;

  final List<_CategoryData> _categories = const [
    _CategoryData(
      label: 'Mercado',
      icon: Icons.shopping_cart_outlined,
    ),
    _CategoryData(
      label: 'Pet',
      icon: Icons.pets_outlined,
    ),
    _CategoryData(
      label: 'Transporte',
      icon: Icons.directions_car_outlined,
    ),
    _CategoryData(
      label: 'Casa',
      icon: Icons.home_outlined,
    ),
    _CategoryData(
      label: 'Tecnologia',
      icon: Icons.computer_outlined,
    ),
    _CategoryData(
      label: 'Companhia',
      icon: Icons.groups_outlined,
    ),
    _CategoryData(
      label: 'Outros',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    final request = widget.requestToEdit;

    if (request != null) {
      _titleController.text = request.title;
      _descriptionController.text = request.description;
      _selectedCategory = request.category;
      _isUrgent = request.isUrgent;
      _neighborhood = request.neighborhood;
    } else {
      _isLoadingNeighborhood = true;
      _loadNeighborhood();
    }
  }

  Future<void> _loadNeighborhood() async {
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

      final storedCep = profile?['cep'];

      if (storedCep is! String ||
          storedCep.trim().isEmpty) {
        throw StateError(
          'CEP não encontrado.',
        );
      }

      final neighborhood =
          await CepService.getNeighborhood(
        storedCep,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _neighborhood = neighborhood;
        _locationError = null;
        _isLoadingNeighborhood = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _neighborhood = null;
        _locationError =
            'Não foi possível identificar seu bairro pelo CEP do perfil.';
        _isLoadingNeighborhood = false;
      });
    }
  }

  void _retryLocation() {
    if (_isLoadingNeighborhood ||
        widget.isEditing) {
      return;
    }

    setState(() {
      _isLoadingNeighborhood = true;
      _locationError = null;
    });

    _loadNeighborhood();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    final title =
        _titleController.text.trim();

    final description =
        _descriptionController.text.trim();

    if (title.isEmpty ||
        description.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha o título e a descrição do pedido.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (!widget.isEditing) {
      if (_isLoadingNeighborhood) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Aguarde enquanto identificamos seu bairro.',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );

        return;
      }

      final neighborhood =
          _neighborhood?.trim() ?? '';

      if (neighborhood.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível identificar seu bairro. Verifique o CEP do seu perfil e tente novamente.',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );

        return;
      }
    }

    FocusScope.of(context).unfocus();

    if (widget.isEditing) {
      final originalRequest =
          widget.requestToEdit!;

      final updatedRequest = HelpRequest(
        id: originalRequest.id,
        userId: originalRequest.userId,
        title: title,
        description: description,
        category: _selectedCategory,
        userName:
            originalRequest.userName,
        neighborhood:
            originalRequest.neighborhood,
        latitude:
            originalRequest.latitude,
        longitude:
            originalRequest.longitude,
        time: originalRequest.time,
        isUrgent: _isUrgent,
        status: originalRequest.status,
        acceptedHelperId:
            originalRequest
                .acceptedHelperId,
        acceptedHelperName:
            originalRequest
                .acceptedHelperName,
      );

      Navigator.of(context).pop(
        updatedRequest,
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            RequestPublishedScreen(
          title: title,
          description: description,
          category: _selectedCategory,
          neighborhood:
              _neighborhood!.trim(),
          isUrgent: _isUrgent,
          onGoHomeRequested:
              widget.onGoHomeRequested,
        ),
      ),
    );
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
            _CreateRequestHeader(
              title: widget.isEditing
                  ? 'Editar pedido'
                  : 'Novo pedido',
              onBack: () {
                Navigator.of(context)
                    .maybePop();
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  28,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      widget.isEditing
                          ? 'O que você quer alterar?'
                          : 'Do que você precisa?',
                      style: AppTextStyles.h1
                          .copyWith(
                        fontSize: 25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.isEditing
                          ? 'Atualize as informações do seu pedido.'
                          : 'Conte à vizinhança como ela pode ajudar.',
                      style: AppTextStyles
                          .small
                          .copyWith(
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    const _SectionLabel(
                      label:
                          'Título do pedido',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller:
                          _titleController,
                      textCapitalization:
                          TextCapitalization
                              .sentences,
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Ex: Preciso comprar um medicamento',
                        prefixIcon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    const _SectionLabel(
                      label: 'Categoria',
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    _CategorySelector(
                      categories:
                          _categories,
                      selectedCategory:
                          _selectedCategory,
                      onSelected:
                          (category) {
                        setState(() {
                          _selectedCategory =
                              category;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    const _SectionLabel(
                      label:
                          'Conte um pouco mais',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller:
                          _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      textCapitalization:
                          TextCapitalization
                              .sentences,
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Explique brevemente o que você precisa e como alguém pode ajudar.',
                        alignLabelWithHint:
                            true,
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    const _SectionLabel(
                      label: 'Localização',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _LocationCard(
                      neighborhood:
                          _neighborhood,
                      isLoading:
                          _isLoadingNeighborhood,
                      errorMessage:
                          _locationError,
                      isEditing:
                          widget.isEditing,
                      onRetry:
                          _retryLocation,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const _PrivacyMessage(),
                    const SizedBox(
                      height: 24,
                    ),
                    _UrgencyCard(
                      isUrgent:
                          _isUrgent,
                      onChanged: (value) {
                        setState(() {
                          _isUrgent =
                              value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            _PublishButton(
              label: widget.isEditing
                  ? 'Salvar alterações'
                  : 'Publicar pedido',
              icon: widget.isEditing
                  ? Icons.check_rounded
                  : Icons
                      .arrow_upward_rounded,
              onPressed:
                  _submitRequest,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateRequestHeader
    extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _CreateRequestHeader({
    required this.title,
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
            title,
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

class _CategorySelector
    extends StatelessWidget {
  final List<_CategoryData>
      categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        const spacing = 8.0;

        final itemWidth =
            (constraints.maxWidth -
                    (spacing * 3)) /
                4;

        return Wrap(
          spacing: spacing,
          runSpacing: 10,
          children:
              categories.map(
            (category) {
              final selected =
                  category.label ==
                      selectedCategory;

              return SizedBox(
                width: itemWidth,
                child: Material(
                  color:
                      Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      onSelected(
                        category.label,
                      );
                    },
                    borderRadius:
                        BorderRadius
                            .circular(14),
                    child: Ink(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 4,
                        vertical: 11,
                      ),
                      decoration:
                          BoxDecoration(
                        color: selected
                            ? AppColors
                                .primaryLight
                            : AppColors
                                .surface,
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        border:
                            Border.all(
                          color: selected
                              ? AppColors
                                  .primary
                              : AppColors
                                  .border,
                          width: selected
                              ? 1.5
                              : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            category
                                .icon,
                            size: 20,
                            color: selected
                                ? AppColors
                                    .primary
                                : AppColors
                                    .textSecondary,
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            category
                                .label,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                AppTextStyles
                                    .caption
                                    .copyWith(
                              fontSize: 10,
                              color: selected
                                  ? AppColors
                                      .primaryDark
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
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }
}

class _CategoryData {
  final String label;
  final IconData icon;

  const _CategoryData({
    required this.label,
    required this.icon,
  });
}

class _LocationCard
    extends StatelessWidget {
  final String? neighborhood;
  final bool isLoading;
  final String? errorMessage;
  final bool isEditing;
  final VoidCallback onRetry;

  const _LocationCard({
    required this.neighborhood,
    required this.isLoading,
    required this.errorMessage,
    required this.isEditing,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasError =
        errorMessage != null;

    final validNeighborhood =
        neighborhood?.trim() ?? '';

    final title = isLoading
        ? 'Identificando seu bairro...'
        : hasError
            ? 'Bairro não identificado'
            : validNeighborhood.isEmpty
                ? 'Bairro não identificado'
                : validNeighborhood;

    final subtitle = isLoading
        ? 'Consultando o CEP salvo no seu perfil'
        : hasError
            ? errorMessage!
            : isEditing
                ? 'Região cadastrada neste pedido'
                : 'Bairro obtido pelo CEP do seu perfil';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? AppColors.danger
                  .withValues(
                  alpha: 0.4,
                )
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: hasError
                  ? AppColors.dangerLight
                  : AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasError
                  ? Icons
                      .location_off_outlined
                  : Icons
                      .location_on_outlined,
              size: 18,
              color: hasError
                  ? AppColors.danger
                  : AppColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style: AppTextStyles
                      .small
                      .copyWith(
                    color: hasError
                        ? AppColors.danger
                        : AppColors.text,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles
                      .caption
                      .copyWith(
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    AppColors.primary,
              ),
            )
          else if (hasError &&
              !isEditing)
            IconButton(
              onPressed: onRetry,
              visualDensity:
                  VisualDensity.compact,
              icon: const Icon(
                Icons.refresh_rounded,
                color:
                    AppColors.primary,
                size: 20,
              ),
            )
          else
            const Icon(
              Icons
                  .check_circle_outline_rounded,
              color:
                  AppColors.secondaryDark,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _PrivacyMessage
    extends StatelessWidget {
  const _PrivacyMessage();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 17,
          color: AppColors.primary,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'O CEP é usado apenas para identificar sua região. Publicamente, mostramos somente o bairro, nunca seu endereço exato.',
            style: AppTextStyles.caption
                .copyWith(
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _UrgencyCard
    extends StatelessWidget {
  final bool isUrgent;
  final ValueChanged<bool> onChanged;

  const _UrgencyCard({
    required this.isUrgent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        14,
        12,
        10,
        12,
      ),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.dangerLight
            : AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? AppColors.danger
                  .withValues(
                  alpha: 0.3,
                )
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isUrgent
                  ? AppColors.dangerLight
                  : AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons
                  .priority_high_rounded,
              color: isUrgent
                  ? AppColors.danger
                  : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Este pedido é urgente',
                  style: AppTextStyles
                      .small
                      .copyWith(
                    color:
                        AppColors.text,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Use apenas quando a ajuda for necessária com prioridade.',
                  style:
                      AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: isUrgent,
            activeThumbColor:
                AppColors.surface,
            activeTrackColor:
                AppColors.danger,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PublishButton
    extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PublishButton({
    required this.label,
    required this.icon,
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
          onPressed: onPressed,
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
          icon: Icon(
            icon,
            size: 19,
          ),
          label: Text(
            label,
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