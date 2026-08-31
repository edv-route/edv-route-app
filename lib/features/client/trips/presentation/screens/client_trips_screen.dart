import 'package:flutter/material.dart';

import '../../../../../shared/widgets/gradient_header.dart';
import '../../../../../theme/app_colors.dart';

/// The Viajes tab while the trips module does not exist: a declared
/// placeholder, not a mock that could be mistaken for a working screen.
/// The tab is present because the island's shape is final (Inicio · Viajes ·
/// Perfil) and hiding it would make the app rearrange itself on an update.
class ClientTripsScreen extends StatelessWidget {
  const ClientTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradientHeader(
          height: GradientHeader.kStandardHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Image(
                  image: AssetImage('assets/images/edv_logo_gold.png'),
                  height: 34,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tus viajes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.local_taxi_outlined,
                        color: AppColors.primary, size: 34),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Aquí vivirán tus viajes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Todavía no se pueden pedir viajes desde la app. '
                    'Cuando se pueda, este es el lugar donde los verás.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
