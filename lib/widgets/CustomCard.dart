import 'package:flutter/material.dart';

import '../constants/AppSizes.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  const CustomCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(7),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: theme.cardColor,
        elevation: 10,
        shadowColor: Colors.tealAccent,
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingMedium),
          child: child,
        ),
      ),
    );
  }
}
