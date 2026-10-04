import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _TermsHeader(
              onBack: () {
                Navigator.of(context).pop();
              },
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  22,
                  18,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IntroCard(),
                    SizedBox(height: 24),
                    _TermsSection(
                      number: '1',
                      title: 'Sobre o Rede+',
                      text:
                          'O Rede+ é uma plataforma comunitária criada para aproximar pessoas da mesma região e facilitar pequenas ajudas do dia a dia. O aplicativo permite publicar pedidos, encontrar solicitações próximas e se oferecer para ajudar outros usuários.',
                    ),
                    _TermsSection(
                      number: '2',
                      title: 'Uso da plataforma',
                      text:
                          'Ao utilizar o Rede+, você concorda em usar a plataforma de forma responsável, respeitosa e compatível com sua finalidade comunitária. O aplicativo não deve ser utilizado para atividades ilegais, fraudulentas, perigosas ou que possam causar danos a outras pessoas.',
                    ),
                    _TermsSection(
                      number: '3',
                      title: 'Conta do usuário',
                      text:
                          'Você é responsável pelas informações fornecidas durante o cadastro e pela segurança de sua conta. Os dados informados devem ser verdadeiros e atualizados. Sua senha é pessoal e não deve ser compartilhada com terceiros.',
                    ),
                    _TermsSection(
                      number: '4',
                      title: 'Pedidos de ajuda',
                      text:
                          'Os pedidos publicados devem representar necessidades reais e ser descritos de maneira clara e respeitosa. O usuário que publica um pedido é responsável pelas informações apresentadas e deve evitar divulgar dados pessoais desnecessários, endereços completos ou informações sensíveis.',
                    ),
                    _TermsSection(
                      number: '5',
                      title: 'Ofertas de ajuda',
                      text:
                          'Ao selecionar a opção de ajudar em um pedido, você demonstra disponibilidade para colaborar. Essa manifestação não constitui obrigação contratual e pode depender da confirmação e comunicação entre os usuários envolvidos.',
                    ),
                    _TermsSection(
                      number: '6',
                      title: 'Segurança e convivência',
                      text:
                          'Os usuários devem agir com respeito e bom senso em todas as interações. Não são permitidos comportamentos ofensivos, discriminatórios, ameaçadores, abusivos ou que coloquem outras pessoas em risco.',
                    ),
                    _TermsSection(
                      number: '7',
                      title: 'Localização',
                      text:
                          'O Rede+ utiliza informações de região para aproximar pedidos e pessoas próximas. A plataforma prioriza a exibição de localização aproximada e não deve tornar público o endereço exato do usuário.',
                    ),
                    _TermsSection(
                      number: '8',
                      title: 'Responsabilidade entre usuários',
                      text:
                          'O Rede+ funciona como um meio de conexão entre pessoas da comunidade. Cada usuário é responsável por avaliar suas próprias interações, combinar os detalhes da ajuda e tomar cuidados adequados antes de encontros ou outras atividades realizadas fora da plataforma.',
                    ),
                    _TermsSection(
                      number: '9',
                      title: 'Conteúdo inadequado',
                      text:
                          'Pedidos ou conteúdos que violem estes termos poderão ser removidos. Contas que utilizem a plataforma de maneira abusiva ou incompatível com a proposta do Rede+ também poderão ter seu acesso restringido.',
                    ),
                    _TermsSection(
                      number: '10',
                      title: 'Alterações no serviço',
                      text:
                          'O Rede+ poderá receber novas funcionalidades, ajustes de funcionamento e melhorias de segurança. Estes Termos de Uso também poderão ser atualizados quando necessário para acompanhar mudanças no aplicativo.',
                    ),
                    _TermsSection(
                      number: '11',
                      title: 'Encerramento da conta',
                      text:
                          'O usuário poderá deixar de utilizar o Rede+ e, quando a funcionalidade estiver disponível, solicitar a exclusão de sua conta e dos dados vinculados a ela, observadas eventuais obrigações legais de conservação.',
                    ),
                    _TermsSection(
                      number: '12',
                      title: 'Aceite',
                      text:
                          'Ao criar uma conta e marcar a opção de aceite, você declara que leu e concorda com estes Termos de Uso e com a Política de Privacidade do Rede+.',
                      showDivider: false,
                    ),
                    SizedBox(height: 12),
                    _LastUpdated(),
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

class _TermsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _TermsHeader({
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
            'Termos de Uso',
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

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primaryDark,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Estes termos explicam as regras básicas para utilizar o Rede+ de forma segura e responsável.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.primaryDark,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String number;
  final String title;
  final String text;
  final bool showDivider;

  const _TermsSection({
    required this.number,
    required this.title,
    required this.text,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.secondaryLight,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          text,
          style: AppTextStyles.small.copyWith(
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 20),
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _LastUpdated extends StatelessWidget {
  const _LastUpdated();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Última atualização: outubro de 2026',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}