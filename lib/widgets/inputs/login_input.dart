import 'package:flutter/material.dart';
import 'package:petcarezone/widgets/box/box.dart';
import '../../constants/font_constants.dart';
import '../form/text_form_field.dart';

class LoginInput extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final String? loginError;

  const LoginInput({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    this.loginError,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          textFormFieldWidget(
            textAlign: TextAlign.start,
            label: FontConstants.inputLabelText("아이디"),
            controller: emailController,
            obscureText: false,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '아이디를 입력해 주세요.';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return '올바른 이메일 양식을 입력해 주세요.';
              }
              return null;
            },
          ),
          boxH(20),
          textFormFieldWidget(
            textAlign: TextAlign.start,
            label: FontConstants.inputLabelText("비밀번호"),
            controller: passwordController,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력해 주세요.';
              }
              if (loginError != null) {
                return loginError; // 에러 메시지 반환
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
