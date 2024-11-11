import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/icon_constants.dart';

class AIHealthCameraPage extends StatefulWidget {
  const AIHealthCameraPage(
      {super.key, required this.type, required this.cameraShutFunction});
  final String type;
  final Function(String) cameraShutFunction;

  @override
  State<AIHealthCameraPage> createState() => _AIHealthCameraPageState();
}

class _AIHealthCameraPageState extends State<AIHealthCameraPage> {
  final List<String> mode = ["가이드", "기본"];
  CameraController? controller;
  late List<CameraDescription> _cameras;
  String? base64String;
  String currentMode = '';

  @override
  void initState() {
    super.initState();
    currentMode = mode[0];
    initFunc();
  }

  @override
  void dispose() {
    if (controller != null) {
      controller!.dispose();
    }
    super.dispose();
  }

  Future<void> initFunc() async {
    _cameras = await availableCameras();
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 56.0,
          title: Text(
            "${widget.type} AI 건강 체크",
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.left,
          ),
          titleSpacing: 4,
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 0.0,
          leading: IconButton(
            icon: SvgPicture.asset(IconConstants.arrowBack,
                colorFilter: ColorFilter.mode(
                  ColorConstants.appBarIconColor,
                  BlendMode.srcATop,
                )),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: _cameraPreviewWidget()),
            if (currentMode == mode[0])
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top + 80,
                  ),
                  const Text(
                    "가이드에 맞춰 뒷모습을 촬영해주세요.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 9,
                  ),
                  Image.asset(
                    "assets/images/ai_preset_6.png",
                    fit: BoxFit.fill,
                    width: MediaQuery.of(context).size.width - 48,
                    height: 432,
                  )
                ],
              ),
            Positioned(
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 188,
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  children: [
                    Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            Center(
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 80, minHeight: 80), // constraints
                                icon: SvgPicture.asset(
                                  IconConstants.cameraShutter,
                                ),
                                onPressed: () async {
                                  String? base64 = await _takePicture();
                                  if (base64 != null && mounted) {
                                    Navigator.of(context).pop();
                                    widget.cameraShutFunction(base64);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32), // constraints
                              icon: SvgPicture.asset(
                                IconConstants.circleInfo,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        )),
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      width: 200,
                      height: 32,
                      decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(50)),
                      child: Stack(
                        children: [
                          Container(
                            height: 32,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1, color: const Color(0xff606C80)),
                                borderRadius: BorderRadius.circular(50)),
                          ),
                          AnimatedContainer(
                            width: 200,
                            height: 32,
                            alignment: currentMode == mode[0]
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(50)),
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: 100,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: const Color(0xff0A6CFF),
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                          ),
                          SizedBox(
                            height: 32,
                            child: Row(
                              children: mode.map<Widget>((e) {
                                return Flexible(
                                  fit: FlexFit
                                      .tight, // 모든 항목이 동일한 비율로 공간을 차지하도록 설정
                                  child: TextButton(
                                    style: ButtonStyle(
                                        overlayColor: MaterialStateProperty.all(
                                            Colors.transparent)),
                                    onPressed: () => {
                                      setState(() {
                                        currentMode = e;
                                      }),
                                    },
                                    child: Text(
                                      e,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center, // 텍스트를 중앙 정렬
                                    ),
                                  ),
                                );
                              }).toList(), // map을 리스트로 변환
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ));
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return Listener(
      child: CameraPreview(
        controller!,
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
          );
        }),
      ),
    );
  }

  Future<String?> _takePicture() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      return null;
    }

    try {
      final XFile xFile = await cameraController.takePicture();
      File file = File(xFile.path);
      List<int> bytes = await file.readAsBytes();
      String base64String = base64Encode(bytes);
      return base64String;
    } on CameraException catch (e) {
      return null;
    }
  }
}
