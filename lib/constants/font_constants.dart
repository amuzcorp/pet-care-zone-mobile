import 'package:flutter/cupertino.dart';
import 'package:petcarezone/constants/color_constants.dart';

class FontConstants {
  ///  Regular weight : 400
  ///  Bold weight : 600
  static TextStyle fontFamily = const TextStyle(fontFamily: "LG");

  static double titleTextSize = 14.0;
  static double descriptionTextSize = 21.0;
  static double buttonTextSize = 16.0;
  static double cardTextSize = 15.0;

  static Text inputLabelText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 15.0, color: ColorConstants.inputLabelColor),
    );
  }
}
