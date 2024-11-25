import 'package:first_bus_project/driver/auth/driver_signin_screen.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class DriverVerificationPendingScreen extends StatelessWidget {
  const DriverVerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: screenHeight * 0.15,
                color: const Color(0XFF419A95),
              ),
              SizedBox(height: screenHeight * 0.04),
              Text(
                "Verification Pending",
                style: TextStyle(
                  fontSize: screenHeight * 0.03,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                "Your account is being verified. It will take up to 1 business day to verify your account.",
                style: TextStyle(
                  fontSize: screenHeight * 0.02,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.06),
              CustomButton(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriverSignInScreen(),
                    ),
                    (route) => false,
                  );
                },
                text: 'Go to Sign In',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 