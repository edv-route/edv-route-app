import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../domain/entities/enrollment_cost.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../theme/app_colors.dart';

/// Everything the affiliate needs to know about being part of EDV, in one place.
///
/// Replaces the "Beneficios" tile on the home screen. That tile promised one
/// third of this and delivered a "próximamente"; the questions a driver
/// actually has — what do I get, what do I pay, what happens if I fall behind,
/// what is expected of me — were spread across screens or nowhere at all.
///
/// The numbers that can change are NOT written here: the benefits come from the
/// membership the office publishes, and the arrears tolerance comes from the
/// account. Anything hardcoded would eventually be a lie told with confidence.
class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key, this.capWeeks});

  /// Weeks of arrears tolerated before penalising, as the backend reports it.
  final int? capWeeks;

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  MembershipInfo? _membership;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final membership = await Dependencies.instance.catalogsRepository.loadMembership();
      if (!mounted) return;
      setState(() {
        _membership = membership;
        _loading = false;
      });
    } catch (_) {
      // The rest of the screen is static and still useful without the benefits.
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            showBack: true,
            title: 'Información',
            subtitle: 'Lo que debes saber como afiliado',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                _benefits(),
                const SizedBox(height: 28),
                _section(
                  icon: Icons.event_repeat,
                  title: 'Tu tarifa',
                  children: const [
                    _Line('La tarifa se cobra por semanas. Cada semana que trabajas se te emite su cobro.'),
                    _Line('Puedes adelantar semanas cuando quieras. Pagar por adelantado no te da descuento, pero te evita quedar debiendo.'),
                    _Line('El monto y la fecha del próximo cobro los ves en tu perfil, en Estado de cuenta.'),
                  ],
                ),
                const SizedBox(height: 24),
                _section(
                  icon: Icons.warning_amber_rounded,
                  title: 'Si te atrasas',
                  children: [
                    _Line(
                      widget.capWeeks != null
                          ? 'Puedes deber hasta ${widget.capWeeks} ${widget.capWeeks == 1 ? "semana" : "semanas"} y seguir trabajando. Tu estado pasa a "En mora", pero sigues recibiendo viajes.'
                          : 'Puedes deber unas semanas y seguir trabajando. Tu estado pasa a "En mora", pero sigues recibiendo viajes.',
                    ),
                    const _Line(
                      'Si pasas de ese límite quedas "Penalizado": dejas de recibir viajes hasta ponerte al día, y se te suma una semana de multa.',
                      emphasis: true,
                    ),
                    const _Line('Ponerte al día te devuelve a trabajar. La app es donde pagas y donde ves cuánto debes.'),
                    const _Line('Ponerte inactivo NO detiene el cobro: la tarifa corre igual.', emphasis: true),
                  ],
                ),
                const SizedBox(height: 24),
                _section(
                  icon: Icons.rule,
                  title: 'Lo que se espera de ti',
                  children: const [
                    _Line('Mantén tu estado en Activo mientras trabajas. Inactivo significa que no se te asignan viajes.'),
                    _Line('Comparte tu ubicación mientras estés activo. Es lo que permite asignarte los viajes que tienes cerca.'),
                    _Line('Durante un viaje, deja la app abierta. Con la app cerrada tu ubicación sigue llegando, pero un viaje nuevo puede tardar en avisarte.'),
                    _Line('Mantén tus documentos y los de tu vehículo al día. Un documento vencido puede dejarte fuera de operación.'),
                    _Line('Tus datos y tu cuenta son personales. No prestes tu sesión: lo que se haga desde tu cuenta cuenta como tuyo.'),
                  ],
                ),
                const SizedBox(height: 24),
                _section(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Tu ubicación',
                  children: const [
                    _Line('Solo se recibe mientras estás activo. Al ponerte inactivo deja de enviarse, de inmediato.'),
                    _Line('Mientras se comparte verás siempre un aviso fijo de EDV Route en la barra de tu teléfono. Nunca se hace a escondidas.'),
                    _Line('Se guarda un tiempo limitado y luego se borra sola.'),
                    _Line('La usa la oficina para asignar viajes y resolver reclamos, para nada más.'),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '¿Alguna duda con tu cuenta, un cobro o un documento? Escribe a la oficina: ellos ven lo mismo que tú.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.primary900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The benefits the office actually published for the current membership.
  Widget _benefits() {
    final membership = _membership;
    final benefits = membership?.benefits ?? const <MembershipBenefit>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.card_giftcard_outlined, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            // The membership name goes UNDER the heading, not inside it: names
            // like "Membresía Profesionales del Volante" turned the title into
            // a line that ran off the screen.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Beneficios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  if (membership != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      membership.name,
                      style: const TextStyle(fontSize: 13, height: 1.3, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (benefits.isEmpty)
          const Text(
            'La oficina todavía no ha publicado los beneficios de tu membresía. Aparecerán aquí en cuanto lo haga.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
          )
        else
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle, size: 18, color: Color(0xFF22C55E)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (b.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            b.description!,
                            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

/// One bullet. `emphasis` is for the ones that cost money if ignored.
class _Line extends StatelessWidget {
  const _Line(this.text, {this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7, right: 10),
            height: 5,
            width: 5,
            decoration: BoxDecoration(
              color: emphasis ? AppColors.primary : AppColors.muted,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: emphasis ? AppColors.ink : AppColors.muted,
                fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
