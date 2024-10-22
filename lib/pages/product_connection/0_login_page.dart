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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService userService = UserService();
  String? _loginError;

  Future<void> _handleLogin(BuildContext context) async {
    setState(() {
      _loginError = null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      try {
        await userService.login(
          context: context,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } catch (error) {
        setState(() {
          _loginError = error.toString();
        });
        _formKey.currentState?.validate();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: false,
      backgroundColor: ColorConstants.pageBG,
      leadingHeight: 180.0,
      contentWidget: LoginInput(
        emailController: _emailController,
        passwordController: _passwordController,
        formKey: _formKey,
        loginError: _loginError,
      ),
      bottomButton: BasicButton(
        text: "로그인",
        fontColor: ColorConstants.white,
        width: double.infinity,
        backgroundColor: ColorConstants.teal,
        apiCall: _handleLogin,
      ),
    );
  }
}
