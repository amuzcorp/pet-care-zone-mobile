import 'package:flutter/material.dart';
import 'package:petcarezone/constants/size_constants.dart';

import '../../constants/color_constants.dart';

Widget guideImageWidget({
  required final String? imagePath,
  final double? height,
}) {
  return Container(
      decoration: BoxDecoration(
        color: ColorConstants.imageBG,
        borderRadius: BorderRadius.circular(SizeConstants.borderSize),
      ),
      child: Image.asset(
          imagePath!,
      )
  );
}
