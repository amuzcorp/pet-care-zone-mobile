import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/image_constants.dart';
import '../../constants/size_constants.dart';

class DeviceRegisterCard extends StatefulWidget {
  final String iconUrl;
  final String? text;
  final Color? textColor;
  final Color? iconColor;
  final Color? bgColor;
  final Widget? destinationPage;
  final Function(String)? onTextChanged;

  const DeviceRegisterCard({
    super.key,
    required this.iconUrl,
    this.text,
    this.textColor,
    this.iconColor,
    this.bgColor,
    this.destinationPage,
    this.onTextChanged,
  });

  @override
  _DeviceRegisterCardState createState() => _DeviceRegisterCardState();
}

class _DeviceRegisterCardState extends State<DeviceRegisterCard> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.text);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isEditing = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    } else {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleEditing,
      child: Container(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        width: SizeConstants.cardWidth,
        height: SizeConstants.cardHeight,
        decoration: BoxDecoration(
          color: widget.bgColor ?? ColorConstants.white,
          borderRadius: BorderRadius.circular(SizeConstants.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              ImageConstants.productConnectionGuide8,
              height: 40,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: TextStyle(
                      color: widget.textColor ?? ColorConstants.black,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '닉네임 입력...',
                      hintStyle: TextStyle(
                        color: ColorConstants.inputLabelColor,
                      ),
                    ),
                    onChanged: (value) {
                      widget.onTextChanged?.call(value);
                    },
                  ),
                ),
                SvgPicture.asset(
                  widget.iconUrl,
                  colorFilter: ColorFilter.mode(
                    widget.iconColor ?? ColorConstants.blackIcon!,
                    BlendMode.srcATop,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
