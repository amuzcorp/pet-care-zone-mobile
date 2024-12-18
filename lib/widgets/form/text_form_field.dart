import 'package:flutter/material.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/widgets/box/box.dart';

import '../../constants/color_constants.dart';
import '../../constants/size_constants.dart';

Widget textFormFieldWidget({
  required TextEditingController controller,
  required bool obscureText,
  required String? Function(String?) validator,
  Widget? label,
  int? maxLength,
  required TextAlign textAlign,
  ValueChanged<String>? onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      label ?? FontConstants.inputLabelText(""),
      boxH(8),
      TextFormField(
        maxLength: maxLength,
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: ColorConstants.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SizeConstants.borderSize),
            borderSide: BorderSide(color: ColorConstants.border, width: SizeConstants.borderWidth),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SizeConstants.borderSize),
            borderSide: BorderSide(color: ColorConstants.activeBorder, width: SizeConstants.borderWidth),
          ),
          counterText: "",
        ),
        obscureText: obscureText,
        validator: validator,
        textAlign: textAlign,
      )
    ],
  );

}
