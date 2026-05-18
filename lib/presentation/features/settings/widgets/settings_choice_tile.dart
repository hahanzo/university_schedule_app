import 'package:flutter/material.dart';

class SettingsChoiceTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const SettingsChoiceTile({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = groupValue == value;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(title),
      leading: GestureDetector(
        onTap: () => onChanged(value),
        child: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? colorScheme.primary : null,
        ),
      ),
      onTap: () => onChanged(value),
    );
  }
}
