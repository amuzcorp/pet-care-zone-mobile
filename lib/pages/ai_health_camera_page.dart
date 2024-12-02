import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/icon_constants.dart';

class AIHealthCameraPage extends StatefulWidget {
  const AIHealthCameraPage(
      {super.key,
      required this.type,
      required this.cameraShutFunction,
      required this.aiPresetImg});
  final String type;
  final Function(String) cameraShutFunction;
  final Uint8List? aiPresetImg;

  @override
  State<AIHealthCameraPage> createState() => _AIHealthCameraPageState();
}

class _AIHealthCameraPageState extends State<AIHealthCameraPage> {
  Map titles = {"patella": "슬개골", "oral": "구강", "bmi": "비만도"};

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
            "${titles[widget.type]} AI 건강 체크",
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.left,
          ),
          titleSpacing: 4,
          backgroundColor: Colors.black,
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
        extendBodyBehindAppBar: false,
        bottomNavigationBar: Container(
          width: MediaQuery.of(context).size.width,
          height: 188,
          color: Colors.black,
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
              if (widget.aiPresetImg != null)
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
                              fit: FlexFit.tight, // 모든 항목이 동일한 비율로 공간을 차지하도록 설정
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
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            _cameraPreviewWidget(),
            if (widget.aiPresetImg != null && currentMode == mode[0])
              Column(
                children: [
                  const SizedBox(
                    height: 20,
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
                    height: 8,
                  ),
                  Expanded(
                    child: Image.memory(
                      widget.aiPresetImg!,
                      fit: BoxFit.fill,
                      width: MediaQuery.of(context).size.width - 48,
                    ),
                  )
                ],
              ),
          ],
        ));
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return AspectRatio(
      aspectRatio: MediaQuery.of(context).size.width /
          (MediaQuery.of(context).size.height -
              188 -
              (MediaQuery.of(context).padding.top + kToolbarHeight)),
      child: ClipRect(
        child: Transform.scale(
          scale: controller!.value.aspectRatio,
          child: Center(
            child: CameraPreview(controller!),
          ),
        ),
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
      ImageProperties properties =
          await FlutterNativeImage.getImageProperties(xFile.path);

      var cropSize = min(properties.width!, properties.height!);

      int offsetX = (properties.width! - cropSize) ~/ 2;
      int offsetY = (properties.height! - cropSize) ~/ 2;

      File imageFile = await FlutterNativeImage.cropImage(
          xFile.path, offsetX, offsetY, cropSize, cropSize);

      List<int> bytes = await imageFile.readAsBytes();
      String base64String = base64Encode(bytes);
      return base64String;
    } on CameraException catch (e) {
      return null;
    }
  }
}
