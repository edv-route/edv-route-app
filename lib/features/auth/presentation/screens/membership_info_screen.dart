import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/enrollment_cost.dart';
import '../controllers/membership_info_controller.dart';

/// Informational pre-screen of the join flow (solicitudes-app): shows the active
/// membership and its benefits + price before the applicant registers. Its CTA
/// starts the registration (step 1). Reached from the login "Registrarme" link.
class MembershipInfoScreen extends StatefulWidget {
  const MembershipInfoScreen({super.key});

  @override
  State<MembershipInfoScreen> createState() => _MembershipInfoScreenState();
}

class _MembershipInfoScreenState extends State<MembershipInfoScreen> {
  late final MembershipInfoController _controller =
      MembershipInfoController(Dependencies.instance.registrationRepository);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToRegister() => Navigator.of(context).pushNamed(AppRoutes.driverRegister);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            showBack: true,
            title: 'Únete a EDV Route',
            highlight: 'EDV Route',
            subtitle: 'Afíliate y empieza a recibir viajes',
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_controller.error != null) {
                  return _ErrorState(message: _controller.error!, onRetry: _controller.load);
                }
                return _content(_controller.membership);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(MembershipInfo? membership) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (membership != null) _MembershipCard(membership: membership),
          const SizedBox(height: 24),
          if (membership != null && membership.benefits.isNotEmpty) ...[
            const Text(
              'Beneficios de tu membresía',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 12),
            for (final b in membership.benefits) _BenefitTile(benefit: b),
            const SizedBox(height: 20),
          ],
          const _JoinNote(),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Registrarme', onPressed: _goToRegister),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Ya tengo cuenta · Iniciar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Membership name + one-off affiliation price, on a branded gold card.
class _MembershipCard extends StatelessWidget {
  final MembershipInfo membership;

  const _MembershipCard({required this.membership});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gold50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.gold700, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  membership.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${membership.priceUsd.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary700,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'afiliación (pago único)',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single benefit row: gold check + name and optional description.
class _BenefitTile extends StatelessWidget {
  final MembershipBenefit benefit;

  const _BenefitTile({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.check_circle, color: AppColors.gold600, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (benefit.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    benefit.description!,
                    style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains the process: registering creates a solicitud reviewed by an admin,
/// and the weekly tariff is charged separately after approval.
class _JoinNote extends StatelessWidget {
  const _JoinNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary700, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Al registrarte creas una solicitud que un administrador revisa. La '
              'tarifa semanal de la ruta se paga por separado; verás el detalle '
              'antes de pagar.',
              style: TextStyle(fontSize: 13, color: AppColors.primary900, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Load-failure state with a retry.
class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.muted, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
