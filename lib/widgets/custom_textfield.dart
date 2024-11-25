import 'package:flutter/material.dart';

class CustomFields extends StatelessWidget {
  const CustomFields({
    super.key,
    required this.controller,
    required this.text,
    this.validator,
    required this.isPassword,
    required this.keyboardType,
     this.icon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String text;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType keyboardType;
  final Widget? icon;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextFormField(
      obscureText: isPassword,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        suffixIcon: icon,
        labelText: text,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: screenWidth * 0.045,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(screenWidth * 0.025),
          ),
        ),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
