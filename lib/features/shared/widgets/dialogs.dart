import 'package:flutter/material.dart';

/// Asks the user to confirm something. Returns true if they did.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Asks for a single line of text. Returns the trimmed text, or null if the
/// dialog was cancelled or left empty.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialValue = '',
  String? hint,
}) async {
  final controller = TextEditingController(text: initialValue);
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (value) => Navigator.pop(dialogContext, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  final trimmed = result?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
