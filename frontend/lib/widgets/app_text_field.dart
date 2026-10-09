import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? labelText;
  final String? hint;
  final String? hintText;
  final dynamic prefixIcon; // Can be IconData or Widget
  final Widget? suffixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.labelText,
    this.hint,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  });

  String get effectiveLabel => labelText ?? label ?? '';
  String? get effectiveHint => hintText ?? hint;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    Widget? suffix;
    if (widget.isPassword) {
      suffix = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    } else {
      suffix = widget.suffixIcon;
    }

    Widget? prefixWidget;
    if (widget.prefixIcon != null) {
      if (widget.prefixIcon is IconData) {
        prefixWidget = Icon(widget.prefixIcon as IconData, size: 20);
      } else if (widget.prefixIcon is Widget) {
        prefixWidget = widget.prefixIcon as Widget;
      }
    }

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.effectiveLabel,
        hintText: widget.effectiveHint,
        prefixIcon: prefixWidget,
        suffixIcon: suffix,
      ),
    );
  }
}
