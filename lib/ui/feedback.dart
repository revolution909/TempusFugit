import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Short tactile confirmation of a completed action.
void haptic() => HapticFeedback.lightImpact();

/// Confirms an action that can be reverted, instead of asking "are you sure?"
/// before it. Replaces any snackbar already showing.
void showUndoSnackBar(
  ScaffoldMessengerState messenger,
  String message,
  VoidCallback onUndo,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'Annulla', onPressed: onUndo),
      ),
    );
}
