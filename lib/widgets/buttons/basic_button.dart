import 'package:flutter/material.dart';
import 'package:petcarezone/widgets/snackbar/custom_snackbar.dart';

import '../../constants/color_constants.dart';
import '../../constants/font_constants.dart';

class BasicButton extends StatefulWidget {
  const BasicButton({
    super.key,
    this.text,
    this.onPressed,
    this.radius,
    this.height,
    this.width,
    this.fontSize,
    this.fontColor,
    this.backgroundColor,
    this.destinationPage,
    this.apiCall,
  });

  final String? text;
  final Future<void> Function(BuildContext context)? apiCall;
  final Function()? onPressed;
  final double? radius;
  final double? height;
  final double? width;
  final double? fontSize;
  final Color? fontColor;
  final Color? backgroundColor;
  final Widget? destinationPage;

  @override
  State<BasicButton> createState() => _BasicButtonState();
}

class _BasicButtonState extends State<BasicButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? ColorConstants.teal,
        borderRadius: BorderRadius.circular(widget.radius ?? 10),
      ),
      height: widget.height,
      width: widget.width ?? double.infinity,
      child: TextButton(
          onPressed: () async {
            if (widget.apiCall != null) {
              try {
                await widget.apiCall!(context);
              } catch (error) {
                print('error $error');
              }
            }
            if (widget.destinationPage != null) {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => widget.destinationPage!),
                );
              }
            }
            if (widget.onPressed != null) {
              widget.onPressed?.call();
            }
          },
          child: Text(
            widget.text ?? '',
            style: TextStyle(
              fontSize: widget.fontSize ?? FontConstants.buttonTextSize,
              color: widget.fontColor ?? ColorConstants.white,
            ),
          )),
    );
  }
}
