import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _Header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'O que você precisa hoje?',
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Escolha uma opção para começar.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _ActionCard(
                      title: 'Preciso de ajuda',
                      description: 'Publique um pedido para pessoas próximas.',
                      icon: Icons.add_circle_outline,
                      backgroundColor: AppColors.primaryLight,
                      iconColor: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    const _ActionCard(
                      title: 'Quero ajudar',
                      description:
                          'Veja pedidos de ajuda disponíveis na sua região.',
                      icon: Icons.volunteer_activism_outlined,
                      backgroundColor: AppColors.secondaryLight,
                      iconColor: AppColors.secondary,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Categorias',
                          style: AppTextStyles.h2,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Encontre ajuda',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _CategoriesGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/logo_simplificada.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rede+',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Conectando vizinhos. Facilitando ajudas.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    color: AppColors.primaryDark,
                    size: 23,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              'Olá, vizinho!',
              style: AppTextStyles.small.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Como podemos ajudar hoje?',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Peça uma pequena ajuda ou ajude alguém da sua região.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.small.copyWith(
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 17,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid();

  @override
  Widget build(BuildContext context) {
    const categories = [
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
        icon: Icons.add_circle_outline,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];

        return _CategoryItem(
          label: category.label,
          icon: category.icon,
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

class _CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CategoryItem({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.secondary,
              size: 23,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}