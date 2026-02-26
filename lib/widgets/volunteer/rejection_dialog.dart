import 'package:flutter/material.dart';

void showRejectionDialog(BuildContext context, String reason) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Invalid Image"),
      content: Text(reason),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}