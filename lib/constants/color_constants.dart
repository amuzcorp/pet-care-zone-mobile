import 'dart:ui';

class ColorConstants {
  static Color white = hexToColor('#FFFFFF');
  static Color black = hexToColor('#000000');
  static Color grey = hexToColor('#dfe3e4');

  static Color red = hexToColor('#DC2900');
  static Color blackIcon = hexToColor('#111111');
  static Color teal = hexToColor('#23778E');
  static Color lightTeal = hexToColor('#2986a0');

  static Color pageBG = hexToColor('#EFF1F4');
  static Color imageBG = hexToColor('#E0E2E6');

  static Color border = hexToColor('#CAD0DD');
  static Color activeBorder = hexToColor('#23778E');

  static Color appBarIconColor = hexToColor('#606C80');
  static Color inputLabelColor = hexToColor('#606C80');

  static Color dividerColor = hexToColor('#CAD0DD');
}

Color hexToColor(String hex) {
  assert(RegExp(r'^#([0-9a-fA-F]{6})|([0-9a-fA-F]{8})$').hasMatch(hex));

  return Color(int.parse(hex.substring(1), radix: 16) +
      (hex.length == 7 ? 0xFF000000 : 0x00000000));
}
