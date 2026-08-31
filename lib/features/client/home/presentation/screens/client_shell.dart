import 'package:flutter/material.dart';

import '../../../../../domain/entities/client.dart';
import '../../../../../shared/widgets/floating_nav.dart';
import '../../../profile/presentation/screens/client_profile_screen.dart';
import '../../../trips/presentation/screens/client_trips_screen.dart';
import './client_home_screen.dart';

/// Authenticated passenger container: three tabs (Inicio · Viajes · Perfil)
/// behind the same floating island the affiliate uses. Viajes is a declared
/// placeholder until the trips module exists — an honest "coming soon", never
/// a dead button.
class ClientShell extends StatefulWidget {
  final Client client;

  const ClientShell({super.key, required this.client});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  /// The shell owns the client so every tab reads the SAME one: editing his
  /// data or his photo in Perfil must repaint the greeting in Inicio too —
  /// the exact lesson the driver shell already learned.
  late Client _client = widget.client;

  void _onClientChanged(Client updated) => setState(() => _client = updated);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ClientHomeScreen(client: _client),
          const ClientTripsScreen(),
          ClientProfileScreen(client: _client, onClientChanged: _onClientChanged),
        ],
      ),
      bottomNavigationBar: FloatingNav(
        index: _index,
        onSelected: (i) => setState(() => _index = i),
        tabs: const [
          (icon: Icons.home_rounded, label: 'Inicio'),
          (icon: Icons.local_taxi_outlined, label: 'Viajes'),
          (icon: Icons.person_rounded, label: 'Perfil'),
        ],
      ),
    );
  }
}
