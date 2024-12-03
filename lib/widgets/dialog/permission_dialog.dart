import 'package:flutter/material.dart';
import 'package:petcarezone/utils/check_permission.dart';

import '../../constants/color_constants.dart';
import '../../constants/font_constants.dart';
import '../../constants/size_constants.dart';

class PermissionCheckDialog {
  final PermissionCheck permissionCheck = PermissionCheck();

  Future<void> showPermissionAlertDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(
            "기기 등록을 위해 필요한 권한을 모두 허용해 주세요.",
            style: TextStyle(fontSize: FontConstants.cardTextSize),
            textAlign: TextAlign.center,
          ),
          contentPadding: const EdgeInsets.all(16),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 120, // 버튼의 고정 너비
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: ColorConstants.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SizeConstants.borderSize),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  permissionCheck.requestPermission();
                },
                child: const Text(
                  "확인",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
