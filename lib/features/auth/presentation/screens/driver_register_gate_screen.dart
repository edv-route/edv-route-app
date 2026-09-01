import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../enrollment/presentation/screens/checklist_hub_screen.dart';
import './attach_register_screen.dart';
import './cedula_gate_screen.dart';
import './driver_register_screen.dart';

/// The affiliate's registration entrance (cédula-first, Luis 2026-09-01):
/// step 0 asks the cédula and routes to the full solicitud form (new person),
/// the short form (a client gaining the driver hat) or back to the login
/// (already an affiliate).
class DriverRegisterGateScreen extends StatelessWidget {
  const DriverRegisterGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = Dependencies.instance.enrollmentRepository;
    return CedulaGateScreen(
      title: 'Crea tu solicitud',
      subtitle: 'Modo conductor · empieza con tu cédula',
      check: repository.checkCedula,
      existsMessage:
          'Esta cédula ya tiene cuenta de afiliado. Vuelve atrás y entra con tu cédula y tu clave '
          '(o recupera tu clave desde ahí).',
      onNew: (context, nationalId) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DriverRegisterScreen(nationalId: nationalId)),
        );
      },
      onAttachable: (context, nationalId) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AttachRegisterScreen(
              title: 'Ya te conocemos',
              subtitle: 'Solo faltan tus datos de conductor',
              nationalId: nationalId,
              currentPasswordLabel: 'Tu clave de pasajero',
              submit: ({
                required String currentPassword,
                required String email,
                required String phone,
                required String password,
              }) async {
                await repository.attach(
                  nationalId: nationalId,
                  currentPassword: currentPassword,
                  email: email,
                  phone: phone,
                  password: password,
                );
              },
              onSuccess: (context) {
                // Born an applicant like anybody: straight to his checklist.
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ChecklistHubScreen()),
                  (route) => route.isFirst,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
