import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:petcarezone/pages/product_connection/0_login_page.dart';
import 'package:petcarezone/pages/product_connection/1-1_initial_device_home_page.dart';
import 'package:petcarezone/services/api_service.dart';
import 'package:petcarezone/data/models/user_model.dart';
import 'package:petcarezone/services/message_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';

class UserService {
  final ApiService apiService = ApiService();
  final MessageService messageService = MessageService();

  Future<Widget> initializeApp() async {
    if (await isTokenValid()) {
      return const InitialDeviceHomePage();
    } else {
      return const LoginPage();
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    final loginInfo = await apiService.postLogin(
      email: email,
      password: password,
      context: context,
    );

    if (loginInfo!['message'].contains('Invalid')) {
      messageService.addMessage("비밀번호가 일치하지 않습니다.");
    } else {
      messageService.addMessage("");
      await saveUserInfo(loginInfo);
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const InitialDeviceHomePage(),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> regMobileToken(mobileId, mobileType, mobileToken) async {
    logD.i('[POST] regMobileToken - $mobileId/$mobileType/$mobileToken');
    try {
      await apiService.regMobileToken(
        mobileId: mobileId,
        mobileType: mobileType,
        mobileToken: mobileToken,
      );
    } catch (e) {
      throw "FCM 정보가 올바르지 않아요.";
    }
  }

  Future<void> saveUserInfo(Map<String, dynamic> loginInfo) async {
    Uuid uuid = const Uuid();

    final prefs = await SharedPreferences.getInstance();
    UserModel user = UserModel.fromJson(loginInfo);

    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('user', jsonEncode(loginInfo));
    await prefs.setString('uuid', uuid.v4());

    await prefs.setInt('tokenTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenTime = prefs.getInt('tokenTime');
    if (tokenTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final tokenAge = currentTime - tokenTime;
      // if (tokenAge > 0) {
      //   await prefs.remove('accessToken');
      //   await prefs.remove('user');
      //   return false;
      // }
      return true;
    }
    return false;
  }

  Future<bool?> getUserPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionStatus = prefs.getBool('permission');
    return permissionStatus;
  }

  Future<UserModel?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final user = UserModel.fromJson(jsonDecode(userJson));
      logD.i('user info : ${jsonEncode(user)}');
      return user;
    }
    return null;
  }

  Future<void> saveLocalPetInfo(Map<String, dynamic> petInfo) async {
    final prefs = await SharedPreferences.getInstance();
    dynamic userData = prefs.getString('user');

    if (userData != null) {
      try {
        Map<String, dynamic> userMap = jsonDecode(userData);
        userMap['petList'].add(petInfo);

        String updatedUserData = jsonEncode(userMap);
        await prefs.setString('user', updatedUserData);
      } catch (e) {
        logD.e('Error decoding or updating user data: $e');
      }
    } else {
      logD.w('No existing user data found in SharedPreferences.');
    }
  }

  Future<void> deleteUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    dynamic userData = prefs.getString('user');

    if (userData != null) {
      try {
        Map<String, dynamic> userMap = jsonDecode(userData);

        userMap['petList'] = [];
        userMap['deviceList'] = [];

        String updatedUserData = jsonEncode(userMap);
        print('updatedUserData $updatedUserData');
        await prefs.setString('user', updatedUserData);
      } catch (e) {
        logD.e('Error decoding or updating user data: $e');
      }
    }

    await Future.wait([
      prefs.remove('userId'),
      prefs.remove('deviceId'),
      prefs.remove('petId'),
      prefs.remove('webos_device_info'),
    ]);
  }

}
