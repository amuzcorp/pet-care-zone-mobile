import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/constants/icon_constants.dart';
import 'package:petcarezone/constants/size_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showCloseButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onClosePressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showCloseButton = false,
    this.onBackPressed,
    this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: ColorConstants.blackIcon,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: ColorConstants.pageBG,
      shadowColor: Colors.transparent,
      leading: showBackButton
          ? IconButton(
              icon: SvgPicture.asset(
                  IconConstants.arrowBack,
                  colorFilter: ColorFilter.mode(
                    ColorConstants.appBarIconColor,
                    BlendMode.srcATop,
                  )),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: [
        if (showCloseButton)
          IconButton(
            icon:
                SvgPicture.asset(IconConstants.close,
                    colorFilter: ColorFilter.mode(
                      ColorConstants.appBarIconColor,
                      BlendMode.srcATop,
                    )),
            onPressed: onClosePressed ?? () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(44);
}
