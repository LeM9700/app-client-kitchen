import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';

class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 0,
      children: [
        TextButton(
          onPressed: () => context.push(AppRoutes.generalConditions),
          child: const Text('Conditions'),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.cgv),
          child: const Text('CGV'),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.cgu),
          child: const Text('CGU'),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.privacy),
          child: const Text('Confidentialite'),
        ),
      ],
    );
  }
}
