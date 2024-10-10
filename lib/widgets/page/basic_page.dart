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
    this.backgroundImage,
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
  final Widget? backgroundImage;

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // 배경 이미지가 있을 때만 Stack을 사용
    Widget pageContent = Column(
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
        Flexible(
          fit: FlexFit.loose,
          child: Center(
            child: contentWidget ?? Container(),
          ),
        ),
        bottomButton ?? Container()
      ],
    );

    // 배경 이미지가 있으면 Stack을 사용해서 배경을 넣고, 없으면 일반적인 Column 레이아웃 사용
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
        body: backgroundImage != null
            ? Stack(
                children: [
                  Positioned.fill(child: backgroundImage!),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: pageContent,
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: pageContent,
              ),
      ),
    );
  }
}
