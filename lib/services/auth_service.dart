// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_bus_project/driver/home/driver_map_screen.dart';
import 'package:first_bus_project/helper/common_fucntions.dart';
import 'package:first_bus_project/helper/constants.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/onboarding/onbording_screen.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:first_bus_project/student/home/student_map_screen.dart';
import 'package:flutter/material.dart';

User? firebaseUser = auth.FirebaseAuth.instance.currentUser;

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoutesService _routesService = RoutesService();

  Future<bool> isUserRegistered(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkUserAndNavigate(
      {required BuildContext context, required mounted}) async {
    await Future.delayed(const Duration(seconds: 2));

    if (firebaseUser != null) {
      UserModel? userModel = await _getUserModel(firebaseUser!.uid, context);
      if (mounted) {
        if (userModel != null) {
          _navigateToDashboard(context: context, userModel: userModel);
        } else {
          _navigateToOnboarding(context: context);
        }
      }
    } else {
      if (mounted) {
        _navigateToOnboarding(context: context);
      }
    }
  }

  Future<UserModel?> _getUserModel(String uid, BuildContext context) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(uid).get();

      if (userSnapshot.exists) {
        Map<String, dynamic>? userDataMap =
            userSnapshot.data() as Map<String, dynamic>?;
        if (userDataMap != null) {
          return UserModel.fromJson(userDataMap);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User data is null or not in the expected format.')),
      );
    }
    return null;
  }

  void _navigateToDashboard(
      {required UserModel userModel, required BuildContext context}) async {
    if (userModel.userType == 'Student') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentMapScreen(
            userModel: userModel,
          ),
        ),
      );
    } else if (userModel.userType == 'Driver') {
      final BusRouteModel busRouteModel =
          await _routesService.getBusRoute(context, firebaseUser!.uid);
      print("---------------------------${busRouteModel.startLocation}");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DriverMapScreen(
            userModel: userModel,
            busRouteModel: busRouteModel,
          ),
        ),
      );
    } else {
      _navigateToOnboarding(context: context);
    }
  }

  void _navigateToOnboarding({required BuildContext context}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const OnbordingScreen(),
      ),
    );
  }

  Future<UserModel?> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      auth.UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        DocumentSnapshot userSnapshot =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userSnapshot.exists) {
          Map<String, dynamic>? userDataMap =
              userSnapshot.data() as Map<String, dynamic>?;

          if (userDataMap != null) {
            UserModel userData = UserModel.fromJson(userDataMap);
            
            if (userData.userType == 'Student') {
              // Check email verification for students
              if (!firebaseUser.emailVerified) {
                await _firebaseAuth.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please verify your email before logging in. Check your inbox.'),
                  ),
                );
                return null;
              }
            } else if (userData.userType == 'Driver' && userData.role == 0) {
              // Check role approval for drivers
              await _firebaseAuth.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your account is pending approval. Please wait for admin verification.'),
                ),
              );
              return null;
            }
            
            return userData;
          }
        }
      }
      return null;
    } on auth.FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to login: $e')),
      );
      return null;
    }
  }

  Future<void> updateUserRecord({
    required BuildContext context,
    required UserModel updatedUser,
    File? newProfileImage,
    File? newLicenseImage,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      String? profileImageUrl = updatedUser.profileImageUrl;
      String? licenseImageUrl =
          updatedUser.licenseImageUrl; // Assuming this is a field in UserModel

      if (newProfileImage != null) {
        profileImageUrl = await CommonFunctions.uploadImageToFirebase(
          path: constProfileImageCollection,
          imageFile: newProfileImage,
          context: context,
        );
      }

      if (newLicenseImage != null) {
        licenseImageUrl = await CommonFunctions.uploadImageToFirebase(
          path: constLicenseImageCollection,
          imageFile: newLicenseImage,
          context: context,
        );
      }

      if (firebaseUser != null) {
        final userToUpdate = updatedUser.copyWith(
          profileImageUrl: profileImageUrl,
          licenseImageUrl: licenseImageUrl, 
          role:1// Update license image URL
        );
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .update(userToUpdate.toJson());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User record updated successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user record: $e')),
      );
    }
  }

  Future<void> logout({
    required BuildContext context,
  }) async {
    try {
      await _firebaseAuth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User logged out successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e')),
      );
    }
  }

  Future<void> signUp({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    required String userType,
    required String busNumber,
    required String busStop,
    required String password,
    required String selectedUniversity,
    required String profileImage,
    required File? licenseImage,
  }) async {
    try {
      auth.UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        if (userType == 'Student') {
          // Send email verification for students
          await firebaseUser.sendEmailVerification();
          
          UserModel newUser = UserModel(
            name: name,
            email: email,
            phone: phone,
            userType: userType,
            busNumber: busNumber,
            busColor: busStop,
            universityName: selectedUniversity,
            profileImageUrl: profileImage,
          );

          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(newUser.toJson());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please check your email for verification.'),
            ),
          );
        } else if (userType == 'Driver') {

          // Handle driver signup with role-based approval
          String? licenseImageUrl;
          if (licenseImage != null) {
            
            licenseImageUrl = await CommonFunctions.uploadImageToFirebase(
              path: constLicenseImageCollection,
              imageFile: licenseImage,
              context: context,
            );
            await firebaseUser.sendEmailVerification();
          }

          UserModel newUser = UserModel(
            name: name,
            email: email,
            phone: phone,
            userType: userType,
            busNumber: busNumber,
            busColor: busStop,
            universityName: selectedUniversity,
            profileImageUrl: profileImage,
            licenseImageUrl: licenseImageUrl,
            role: 0, // Default role for unapproved drivers
          );

          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(newUser.toJson());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait for admin approval to login.'),
            ),
          );
        }
      }
    } on auth.FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign up: $e')),
      );
    }
  }

  Future<void> studentSignUp({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String busStop,
    required String selectedUniversity,
    String profileImage = '',
  }) async {
    // Implementation for student signup without license
  }
}
