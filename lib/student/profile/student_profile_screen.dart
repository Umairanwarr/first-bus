// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/auth_service.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:first_bus_project/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StudentProfileScreen extends StatefulWidget {
  final UserModel userModel;
  const StudentProfileScreen({super.key, required this.userModel});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameConroller;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _busPlateController;
  late TextEditingController _busStopController;
  final AuthService _authService = AuthService();
  File? _profileImage;

  @override
  void initState() {
    _nameConroller = TextEditingController(text: widget.userModel.name);
    _phoneController = TextEditingController(text: widget.userModel.phone);
    _emailController = TextEditingController(text: widget.userModel.email);
    _busPlateController =
        TextEditingController(text: widget.userModel.busNumber);
    _busStopController = TextEditingController(text: widget.userModel.busColor);
    super.initState();
  }

  @override
  void dispose() {
    _nameConroller.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _busStopController.dispose();
    _busPlateController.dispose();

    super.dispose();
  }

  void _updateData({required UserModel user}) async {
    if (_formKey.currentState!.validate()) {
      _authService.updateUserRecord(
        updatedUser: user,
        context: context,
        newProfileImage: _profileImage,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.08),
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: const Color(0XFF419A95),
                      size: screenWidth * 0.08,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.08,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : widget.userModel.profileImageUrl.isNotEmpty
                              ? NetworkImage(widget.userModel.profileImageUrl)
                              : const AssetImage('assets/logo.png'),
                      maxRadius: screenHeight * 0.08,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SizedBox(
                                height: screenHeight * 0.22,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _pickImage(ImageSource.gallery);
                                      },
                                      child: SizedBox(
                                        height: screenHeight * 0.1,
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.photo_library),
                                            SizedBox(width: 10),
                                            Text('From Gallery'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _pickImage(ImageSource.camera);
                                      },
                                      child: SizedBox(
                                        height: screenHeight * 0.1,
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt),
                                            SizedBox(width: 10),
                                            Text('From Camera'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: screenHeight * 0.02,
                          child: Icon(
                            Icons.edit,
                            size: screenHeight * 0.02,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.025),
                CustomFields(
                  icon: const Icon(
                    Icons.person,
                    color: Colors.grey,
                  ),
                  isPassword: false,
                  controller: _nameConroller,
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
                    Icons.person,
                    color: Colors.grey,
                  ),
                  isPassword: false,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  text: 'Phone',
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your phone number';
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
                SizedBox(height: screenHeight * 0.05),
                CustomButton(
                  onTap: () {
                    UserModel user = UserModel(
                      profileImageUrl: widget.userModel.profileImageUrl,
                      userType: widget.userModel.userType,
                      name: _nameConroller.text,
                      busNumber: "",
                      phone: _phoneController.text,
                      busColor: "",
                      email: _emailController.text,
                      universityName: widget.userModel.universityName,
                    );
                    _updateData(user: user);
                    setState(() {});
                  },
                  text: 'Update',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
