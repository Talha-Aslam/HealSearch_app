import 'package:flutter/material.dart';

class CustomTextField2 extends StatelessWidget {
  final TextEditingController controller;
  final String name;
  final IconData prefixIcon;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final TextInputType inputType;
  final String? errorText;
  final int? maxLength;
  final Function(String)? onChanged;

  const CustomTextField2({
    super.key,
    required this.controller,
    required this.name,
    required this.prefixIcon,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    required this.inputType,
    this.errorText,
    this.maxLength = 32,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TextField(
        enabled: true,
        controller: controller,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
        maxLines: 1,
        obscureText: obscureText,
        keyboardType: inputType,
        onChanged: onChanged,
        textAlign: TextAlign.start,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon),
          isDense: true,
          labelText: name,
          counterText: "",
          labelStyle: TextStyle(
            color: errorText != null ? Colors.red : Colors.grey,
          ),
          errorText: errorText,
          errorMaxLines: 2,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: errorText != null ? Colors.red : Colors.grey),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: errorText != null ? Colors.red : Colors.blue, width: 1.5),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: errorText != null ? Colors.red : Colors.grey),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}