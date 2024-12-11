import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/widgets/buttons/basic_button.dart';
import 'package:petcarezone/services/user_service.dart';
import '../../constants/color_constants.dart';
import '../../widgets/page/basic_page.dart';
import '../../widgets/inputs/login_input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final UserService userService = UserService();
  String? loginError;

  Future<void> handleLogin(BuildContext context) async {
    setState(() {
      loginError = null;
    });

    if (formKey.currentState?.validate() ?? false) {
      try {
        await userService.login(
          context: context,
          email: emailController.text,
          password: passwordController.text,
        );
      } catch (error) {
        setState(() {
          loginError = error.toString();
        });
        formKey.currentState?.validate();
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: false,
      backgroundColor: ColorConstants.pageBG,
      leadingHeight: 180.0,
      contentWidget: LoginInput(
        emailController: emailController,
        passwordController: passwordController,
        formKey: formKey,
        loginError: loginError,
      ),
      bottomButton: BasicButton(
        text: "first_use.login.sign_in".tr(),
        fontColor: ColorConstants.white,
        width: double.infinity,
        backgroundColor: ColorConstants.teal,
        apiCall: handleLogin,
      ),
    );
  }
}
