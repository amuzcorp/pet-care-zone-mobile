import 'package:flutter/material.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/widgets/box/box.dart';
import '../appbars/basic_appbar.dart';

class BasicPage extends StatelessWidget {
  const BasicPage({
    super.key,
    required this.showAppBar,
    this.title,
    this.description,
    this.guideImage,
    this.leadingHeight,
    this.topHeight = 0.0,
    this.backgroundColor,
    this.contentWidget,
    this.bottomButton,
  });

  final bool? showAppBar;
  final String? title;
  final String? description;
  final double? leadingHeight;
  final double? topHeight;
  final Color? backgroundColor;
  final Widget? guideImage;
  final Widget? contentWidget;
  final Widget? bottomButton;

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: showAppBar == true
              ? CustomAppBar(
                  title: title ?? '',
                  showBackButton: true,
                  showCloseButton: true,
                  onBackPressed: () {
                    Navigator.of(context).pop();
                  },
                  onClosePressed: () {
                    Navigator.of(context).pop();
                  },
                )
              : null,
          backgroundColor: backgroundColor ?? ColorConstants.pageBG,
          body: Container(
            height: double.infinity,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                boxH(leadingHeight ?? 0),
                if (!isKeyboardVisible)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        description ?? '',
                        style: TextStyle(
                            fontSize: FontConstants.descriptionTextSize,
                            fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                isKeyboardVisible ? boxH(0) : boxH(topHeight!),
                guideImage ?? Container(),
                /// Content Widget
                Flexible(
                  fit: FlexFit.loose,
                  child: Center(
                    child: contentWidget ?? Container(),
                  ),
                ),
                bottomButton ?? Container()
              ],
            ),
          ),
        ));
  }
}
