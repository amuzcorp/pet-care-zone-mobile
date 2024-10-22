import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/icon_constants.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/widgets/box/box.dart';
import '../../constants/image_constants.dart';
import '../../constants/size_constants.dart';

class InitialDeviceRegisterCard extends StatefulWidget {
  final String iconUrl;
  final String text;
  final Color? textColor;
  final Color? iconColor;
  final Color? bgColor;
  final Widget? destinationPage;
  final Function(String)? onTextChanged;
  final bool isRegistered;

  const InitialDeviceRegisterCard({
    super.key,
    required this.iconUrl,
    required this.text,
    required this.isRegistered,
    this.textColor,
    this.iconColor,
    this.bgColor,
    this.destinationPage,
    this.onTextChanged,
  });

  @override
  _InitialDeviceRegisterCardState createState() =>
      _InitialDeviceRegisterCardState();
}

class _InitialDeviceRegisterCardState extends State<InitialDeviceRegisterCard> {
  DeviceService deviceService = DeviceService();
  ConnectSdkService connectSdkService = ConnectSdkService();
  LunaService lunaService = LunaService();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.destinationPage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => widget.destinationPage!),
          );
        }
      },
      child: Stack(
        children: [
            Opacity(
              opacity: widget.isRegistered ? 1.0 : 0.5,
              child: Container(
                width: SizeConstants.cardWidth,
                height: SizeConstants.cardHeight,
                decoration: BoxDecoration(
                  color: widget.bgColor ?? ColorConstants.white,
                  borderRadius: BorderRadius.circular(SizeConstants.borderRadius),
                ),
              ),
            ),

          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: !widget.isRegistered ?
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(IconConstants.devicePlusIcon,
                      colorFilter: ColorFilter.mode(
                        ColorConstants.teal,
                        BlendMode.srcATop,
                      )),
                  boxH(10),
                  const Text("Pet Care Zone\n등록"),
                ],
              ) :
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    ImageConstants.productConnectionGuide8,
                    height: 40,
                  ),
                  boxH(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.text),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
