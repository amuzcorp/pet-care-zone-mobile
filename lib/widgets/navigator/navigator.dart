import 'package:flutter/material.dart';

void navigator(BuildContext context, Widget Function() page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page()),
    );
}
