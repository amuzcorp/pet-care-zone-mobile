import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/services/message_service.dart';
import 'package:petcarezone/widgets/box/box.dart';
import '../../constants/font_constants.dart';
import '../form/text_form_field.dart';

class LoginInput extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;

  const LoginInput({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
  });

  @override
  State<LoginInput> createState() => _LoginInputState();
}

class _LoginInputState extends State<LoginInput> {
  final MessageService messageService = MessageService();
  String loginError = "";
  late StreamSubscription<String> messageSubscription;

  @override
  void initState() {
    super.initState();
    messageSubscription = messageService.messageController.stream.listen((message) {
      setState(() {
        loginError = message;
      });
      widget.formKey.currentState?.validate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          textFormFieldWidget(
            textAlign: TextAlign.start,
            label: FontConstants.inputLabelText("first_use.login.id".tr()),
            controller: widget.emailController,
            obscureText: false,
            validator: (value) {
              if (value!.isEmpty) {
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
            label: FontConstants.inputLabelText("first_use.login.password".tr()),
            controller: widget.passwordController,
            obscureText: true,
            validator: (value) {
              if (value!.isEmpty) {
                return '비밀번호를 입력해 주세요.';
              }
              if (loginError.isNotEmpty) {
                return loginError;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
