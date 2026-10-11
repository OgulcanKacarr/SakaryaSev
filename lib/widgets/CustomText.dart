import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const CustomText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: style ?? theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
