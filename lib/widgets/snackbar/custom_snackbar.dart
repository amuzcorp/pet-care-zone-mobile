import 'package:flutter/material.dart';

void CustomSnackBar(String message, {BuildContext? context}) {
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
