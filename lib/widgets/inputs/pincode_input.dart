import 'package:flutter/material.dart';

import '../form/text_form_field.dart';

class PincodeInput extends StatelessWidget {
  final TextEditingController pincodeController;

  const PincodeInput({
    super.key,
    required this.pincodeController,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          textFormFieldWidget(
            textAlign: TextAlign.center,
            maxLength: 8,
            controller: pincodeController,
            obscureText: false,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'PIN CODE를 입력해주세요.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
