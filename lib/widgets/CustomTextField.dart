import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Icon prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.onChanged,
    required this.keyboardType,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword ? _obscureText : false,
      onChanged: widget.onChanged,
      cursorColor: Colors.tealAccent,
      decoration: InputDecoration(
        labelText: widget.hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.isPassword
            ? IconButton(
          onPressed: () => setState(() => _obscureText = !_obscureText),
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
        )
            : null,
      ),
    );
  }
}
