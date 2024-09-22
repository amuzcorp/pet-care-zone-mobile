import 'package:flutter/material.dart';

import '../../constants/color_constants.dart';
import '../../constants/font_constants.dart';
import '../../constants/size_constants.dart';
import '../../services/wifi_service.dart';
import '../box/box.dart';
import '../form/text_form_field.dart';

class WifiInput extends StatefulWidget {
  const WifiInput({super.key});

  @override
  _WifiInputState createState() => _WifiInputState();
}

class _WifiInputState extends State<WifiInput> {
  final LayerLink layerLink = LayerLink();
  final WifiService wifiService = WifiService();
  final TextEditingController passwordController = TextEditingController();
  String selectedWifi = "";

  @override
  void initState() {
    super.initState();
    wifiService.initialize();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          widgetWifiDropdown(),
          boxH(20),
          widgetPasswordField(),
        ],
      ),
    );
  }

  Widget widgetWifiDropdown() {
    return StreamBuilder<List<Map<String, String>>>(
      stream: wifiService.wifiStream,
      builder: (context, snapshot) {
        List<Map<String, String>> wifiInfos = snapshot.data ?? [];

        if (wifiInfos.isNotEmpty) {
          final firstSsid = wifiInfos[0]['SSID'] ?? "";

          // Initialize selectedWifi if it's empty
          if (selectedWifi.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedWifi = firstSsid;
              });
            });
          }
        }

        return CompositedTransformTarget(
          link: layerLink,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: ColorConstants.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SizeConstants.borderSize),
                borderSide: BorderSide(
                  color: ColorConstants.border,
                  width: SizeConstants.borderWidth,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SizeConstants.borderSize),
                borderSide: BorderSide(
                  color: ColorConstants.activeBorder,
                  width: SizeConstants.borderWidth,
                ),
              ),
              counterText: "",
            ),
            value: wifiInfos.any((wifi) => wifi['SSID'] == selectedWifi) ? selectedWifi : null,
            hint: Text(wifiInfos.isNotEmpty ? wifiInfos[0]['SSID'] ?? "Wi-Fi Scanning..." : "Wi-Fi Scanning..."),
            items: wifiInfos.map((wifi) {
              return DropdownMenuItem<String>(
                value: wifi['SSID'],
                child: Text(wifi['SSID'] ?? ''),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedWifi = newValue ?? '';
              });
            },
          ),
        );
      },
    );
  }

  Widget widgetPasswordField() {
    return textFormFieldWidget(
      textAlign: TextAlign.start,
      label: FontConstants.inputLabelText("비밀번호"),
      controller: passwordController,
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '비밀번호를 입력해 주세요.';
        }
        return null;
      },
    );
  }
}
