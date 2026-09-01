import 'package:flutter/material.dart';

import '../../../../../core/di.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../auth/presentation/screens/attach_register_screen.dart';
import '../../../../auth/presentation/screens/cedula_gate_screen.dart';
import '../../../home/presentation/screens/client_shell.dart';
import './client_register_screen.dart';

/// The passenger's registration entrance (cédula-first, Luis 2026-09-01):
/// step 0 asks the cédula and routes to the full form (new person), the short
/// form (an affiliate gaining the client hat) or back to the login (already a
/// client).
class ClientRegisterGateScreen extends StatelessWidget {
  const ClientRegisterGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = Dependencies.instance.clientAuthRepository;
    return CedulaGateScreen(
      title: 'Crear mi cuenta',
      subtitle: 'Modo pasajero · empieza con tu cédula',
      check: repository.checkCedula,
      existsMessage:
          'Esta cédula ya tiene cuenta de pasajero. Vuelve atrás y entra con tu correo o tu teléfono '
          '(o recupera tu clave desde ahí).',
      onNew: (context, nationalId) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ClientRegisterScreen(nationalId: nationalId)),
        );
      },
      onAttachable: (context, nationalId) {
        Client? attached;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AttachRegisterScreen(
              title: 'Ya te conocemos',
              subtitle: 'Solo faltan tus datos de pasajero',
              nationalId: nationalId,
              currentPasswordLabel: 'Tu clave de afiliado',
              submit: ({
                required String currentPassword,
                required String email,
                required String phone,
                required String password,
              }) async {
                attached = await repository.attach(
                  nationalId: nationalId,
                  currentPassword: currentPassword,
                  email: email,
                  phone: phone,
                  password: password,
                );
              },
              onSuccess: (context) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => ClientShell(client: attached!)),
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
