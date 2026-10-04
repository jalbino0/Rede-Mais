import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
            _PrivacyHeader(
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
                    _PrivacySection(
                      number: '1',
                      title: 'Nossa proposta de privacidade',
                      text:
                          'O Rede+ foi pensado para aproximar pessoas da mesma comunidade sem expor informações pessoais além do necessário. Buscamos utilizar os dados dos usuários de forma transparente e compatível com as funcionalidades oferecidas pelo aplicativo.',
                    ),
                    _PrivacySection(
                      number: '2',
                      title: 'Dados fornecidos no cadastro',
                      text:
                          'Durante a criação da conta, poderão ser solicitadas informações como nome, e-mail, senha e CEP. Esses dados são utilizados para identificar a conta, permitir o acesso ao aplicativo e determinar a região aproximada do usuário.',
                    ),
                    _PrivacySection(
                      number: '3',
                      title: 'CEP e localização',
                      text:
                          'O CEP é utilizado para identificar a região do usuário e ajudar a apresentar pedidos próximos. O Rede+ não pretende exibir publicamente o CEP completo nem o endereço exato informado pelo usuário.',
                    ),
                    _PrivacySection(
                      number: '4',
                      title: 'Dados exibidos publicamente',
                      text:
                          'Ao publicar um pedido, algumas informações poderão ser exibidas para outros usuários, como nome, categoria do pedido, descrição, região aproximada, horário da publicação e indicação de urgência quando selecionada.',
                    ),
                    _PrivacySection(
                      number: '5',
                      title: 'Pedidos e interações',
                      text:
                          'As informações inseridas em pedidos de ajuda e as manifestações de interesse em ajudar poderão ser utilizadas para viabilizar as interações entre usuários e organizar o funcionamento da plataforma.',
                    ),
                    _PrivacySection(
                      number: '6',
                      title: 'Como os dados são utilizados',
                      text:
                          'Os dados poderão ser utilizados para permitir autenticação, identificar pedidos próximos, manter informações do perfil, registrar pedidos e ofertas de ajuda, melhorar a experiência de uso e apoiar recursos de segurança e funcionamento do aplicativo.',
                    ),
                    _PrivacySection(
                      number: '7',
                      title: 'Compartilhamento de dados',
                      text:
                          'O Rede+ não tem como objetivo vender dados pessoais dos usuários. Informações poderão ser processadas por serviços necessários ao funcionamento do aplicativo, como autenticação, banco de dados e infraestrutura técnica.',
                    ),
                    _PrivacySection(
                      number: '8',
                      title: 'Segurança das informações',
                      text:
                          'São adotadas medidas técnicas e organizacionais compatíveis com o projeto para reduzir riscos de acesso indevido, perda ou alteração de informações. Ainda assim, nenhum sistema digital pode garantir segurança absoluta.',
                    ),
                    _PrivacySection(
                      number: '9',
                      title: 'Responsabilidade do usuário',
                      text:
                          'O usuário deve evitar inserir em descrições públicas informações sensíveis ou desnecessárias, como endereço completo, documentos, senhas, dados bancários ou outras informações que não sejam necessárias para solicitar ajuda.',
                    ),
                    _PrivacySection(
                      number: '10',
                      title: 'Armazenamento e conservação',
                      text:
                          'Os dados poderão ser mantidos enquanto a conta estiver ativa ou enquanto forem necessários para oferecer as funcionalidades do Rede+, observadas necessidades técnicas, de segurança e eventuais obrigações legais.',
                    ),
                    _PrivacySection(
                      number: '11',
                      title: 'Acesso, correção e exclusão',
                      text:
                          'O usuário poderá solicitar a atualização de informações pessoais e, quando a funcionalidade estiver disponível, a exclusão de sua conta e dos dados vinculados a ela, respeitados os casos em que alguma informação precise ser conservada por obrigação legal ou motivo legítimo.',
                    ),
                    _PrivacySection(
                      number: '12',
                      title: 'Serviços de terceiros',
                      text:
                          'Algumas funcionalidades do Rede+ poderão utilizar serviços externos, como soluções de autenticação, armazenamento em nuvem, banco de dados ou localização. Esses serviços poderão processar informações necessárias para executar suas funções.',
                    ),
                    _PrivacySection(
                      number: '13',
                      title: 'Alterações nesta política',
                      text:
                          'Esta Política de Privacidade poderá ser atualizada para acompanhar novas funcionalidades, alterações técnicas ou mudanças na forma como os dados são tratados. Quando necessário, a versão atualizada será disponibilizada no aplicativo.',
                    ),
                    _PrivacySection(
                      number: '14',
                      title: 'Aceite da política',
                      text:
                          'Ao criar uma conta e marcar a opção de aceite, você declara que leu esta Política de Privacidade e os Termos de Uso do Rede+.',
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

class _PrivacyHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _PrivacyHeader({
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
            'Política de Privacidade',
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
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.18),
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
              Icons.shield_outlined,
              color: AppColors.secondaryDark,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Sua privacidade importa. Aqui explicamos quais informações o Rede+ utiliza e como elas ajudam o aplicativo a funcionar.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark,
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

class _PrivacySection extends StatelessWidget {
  final String number;
  final String title;
  final String text;
  final bool showDivider;

  const _PrivacySection({
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
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryDark,
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