import 'package:flutter/material.dart';

import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../widgets/user_mode_card.dart';

/// First screen: the user picks how to enter the app. Driver ("conductor") is
/// live; passenger ("pasajero") is disabled with a "Próximamente" badge until
/// that side of the product ships.
class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: '¿Qué modo deseas usar?',
            highlight: 'modo',
            subtitle: 'Puedes elegir el modo que se adapte a tus necesidades',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  UserModeCard(
                    modePrefix: 'Modo',
                    modeName: 'conductor',
                    description:
                        'Recibe viajes y gestiona tu jornada como chofer.',
                    icon: Icons.directions_car_filled_outlined,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.driverLogin),
                  ),
                  const SizedBox(height: 16),
                  const UserModeCard(
                    modePrefix: 'Modo',
                    modeName: 'pasajero',
                    description:
                        'Solicita viajes como cliente. Disponible muy pronto.',
                    icon: Icons.person_outline,
                    enabled: false,
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
