import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:petcarezone/pages/product_connection/0_login_page.dart';
import 'package:petcarezone/pages/product_connection/1-1_initial_device_home_page.dart';
import 'package:petcarezone/services/api_service.dart';
import 'package:petcarezone/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/product_connection/1-2_power_check_page.dart';
import '../utils/logger.dart';

class UserService {
  final ApiService apiService = ApiService();
  final StreamController<UserModel?> _userController = StreamController<UserModel?>.broadcast();

  Stream<UserModel?> get userStream => _userController.stream;

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

  Future<void> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      final loginInfo = await apiService.postLogin(
        email: email,
        password: password,
        context: context,
      );

      if (loginInfo != null) {
        await _saveUserInfo(loginInfo);
        UserModel user = UserModel.fromJson(loginInfo);

        _userController.add(user);

        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const InitialDeviceHomePage(),
            ),
          );
        }
      }
    } catch (e) {
      throw "비밀번호를 확인해주세요.";
    }
  }

  Future<void> _saveUserInfo(Map<String, dynamic> loginInfo) async {
    final prefs = await SharedPreferences.getInstance();
    UserModel user = UserModel.fromJson(loginInfo);

    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('user', jsonEncode(loginInfo));

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

  Future<UserModel?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final user = UserModel.fromJson(jsonDecode(userJson));
      _userController.add(user);
      logD.i('user info : ${jsonEncode(user)}');
      return user;
    }
    return null;
  }

  Future<void> deleteUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }
}
