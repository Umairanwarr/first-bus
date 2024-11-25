// ignore_for_file: use_build_context_synchronously

import 'package:first_bus_project/services/auth_service.dart';
import 'package:first_bus_project/student/auth/student_signin_screen.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:first_bus_project/widgets/custom_textfield.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ValidationIndicator extends StatelessWidget {
  final bool isValid;
  final String text;

  const ValidationIndicator({
    Key? key,
    required this.isValid,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isValid ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isValid ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentSignUpScreen extends StatefulWidget {
  const StudentSignUpScreen({super.key});

  @override
  State<StudentSignUpScreen> createState() => _StudentSignUpScreenState();
}

class _StudentSignUpScreenState extends State<StudentSignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  String _selectedUniversity = 'Comsats Wah';
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _hasUpperCase = false;
  bool _hasSpecialChar = false;
  bool _hasNumber = false;
  bool _hasMinLength = false;

  @override
  void initState() {
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword(String value) {
    setState(() {
      _hasUpperCase = value.contains(RegExp(r'[A-Z]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasMinLength = value.length >= 8;
    });
  }

  void _signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      if (_passwordController.text == _confirmPasswordController.text) {
        await _authService.signUp(
          context: context,
          name: name,
          email: email,
          phone: '',
          userType: 'Student',
          busNumber: '',
          busStop: '',
          password: password,
          selectedUniversity: _selectedUniversity,
          profileImage: '',
          licenseImage: null,
        );

        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentSignInScreen(),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password doesn't match"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.03,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.08),
                IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_outlined,
                    color: const Color(0XFF419A95),
                    size: screenWidth * 0.08,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Text(
                  "Welcome Student",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: screenHeight * 0.04,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.03),
                    CustomFields(
                      icon: const Icon(
                        Icons.person,
                        color: Colors.grey,
                      ),
                      isPassword: false,
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      text: 'Full Name',
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    CustomFields(
                      icon: const Icon(
                        Icons.email,
                        color: Colors.grey,
                      ),
                      isPassword: false,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      text: 'Email',
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your email';
                        }
                        bool isValidEmail =
                            RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(value);
                        if (!isValidEmail) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    CustomFields(
                      icon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                      isPassword: !_showPassword,
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      text: 'Password',
                      onChanged: _validatePassword,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (!_hasUpperCase ||
                            !_hasSpecialChar ||
                            !_hasNumber ||
                            !_hasMinLength) {
                          return 'Please meet all password requirements';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValidationIndicator(
                            isValid: _hasMinLength,
                            text: 'At least 8 characters',
                          ),
                          ValidationIndicator(
                            isValid: _hasUpperCase,
                            text: 'At least one uppercase letter',
                          ),
                          ValidationIndicator(
                            isValid: _hasNumber,
                            text: 'At least one number',
                          ),
                          ValidationIndicator(
                            isValid: _hasSpecialChar,
                            text: 'At least one special character',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    CustomFields(
                      icon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                      isPassword: !_showPassword,
                      controller: _confirmPasswordController,
                      keyboardType: TextInputType.visiblePassword,
                      text: 'Confirm Password',
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please confirm your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    DropdownButtonFormField<String>(
                      value: _selectedUniversity,
                      items: ['Comsats Wah', 'UET Taxila', 'HiTech Taxila']
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUniversity = value!;
                        });
                      },
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth * 0.04,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(screenWidth * 0.02),
                          ),
                          borderSide: BorderSide(
                            width: screenWidth * 0.02,
                            color: const Color(0XFF800080),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : CustomButton(
                            onTap: () {
                              _signUp(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                                name: _fullNameController.text,
                              );
                            },
                            text: 'Sign Up',
                          ),
                    SizedBox(height: screenHeight * 0.05),
                    Align(
                      alignment: Alignment.center,
                      child: Text.rich(
                        TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: screenWidth * 0.045,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign In",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.05,
                                color: const Color(0XFF419A95),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const StudentSignInScreen(),
                                    ),
                                  );
                                },
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
