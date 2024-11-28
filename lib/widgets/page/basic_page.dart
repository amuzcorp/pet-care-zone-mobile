import 'package:flutter/material.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/widgets/box/box.dart';
import '../appbars/basic_appbar.dart';

class BasicPage extends StatelessWidget {
  BasicPage({
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

  static bool devMode = false;

  ConnectSdkService connectSdkService = ConnectSdkService();

  @override
  Widget build(BuildContext context) {
    int tapCount = 0;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    Widget pageContent = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        boxH(leadingHeight ?? 0),
        if (!isKeyboardVisible)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  description ?? '',
                  style: TextStyle(
                    fontSize: FontConstants.descriptionTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                  softWrap: true,
                ),
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
        if (devMode)
          StreamBuilder<String>(
            stream: connectSdkService.logStream, // Still subscribe to logStream for new updates
            builder: (context, logSnapshot) {
              if (logSnapshot.hasData) {
                // Only add the log if it's not already in collectedLogs
                if (!connectSdkService.collectedLogs.contains(logSnapshot.data)) {
                  connectSdkService.collectedLogs.add(logSnapshot.data!);
                }
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: connectSdkService.collectedLogs.length, // Use the full collectedLogs list
                  itemBuilder: (context, index) {
                    return SelectableText('${connectSdkService.collectedLogs[index]}\n'); // Display the full log history
                  },
                ),
              );
            },
          ),
        bottomButton ?? Container()
      ],
    );

    return GestureDetector(
      onTap: () {
        tapCount++; // 탭 카운트 증가
        if (tapCount >= 7) {
          tapCount = 0;
          devMode = !devMode;

          final message = devMode ? 'Dev Mode Activated!' : 'Dev Mode Deactivated!'; // 메시지 선택
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }

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
        body: SafeArea(
          child: backgroundImage != null
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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: pageContent,
          ),
        )
      ),
    );
  }
}
