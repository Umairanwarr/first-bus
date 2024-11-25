import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_bus_project/driver/home/driver_map_screen.dart';
import 'package:first_bus_project/driver/manage-stops/driver_manage_stops_screen.dart';
import 'package:first_bus_project/driver/profile/driver_profile_screen.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/auth_service.dart';
import 'package:first_bus_project/welcome/welcome_screen.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class DriverMenuScreen extends StatefulWidget {
  final String userId; 
  BusRouteModel? busRouteModel;

  DriverMenuScreen({
    super.key,
    required this.userId,
    required this.busRouteModel,
  });

  @override
  State<DriverMenuScreen> createState() => _DriverMenuScreenState();
}

class _DriverMenuScreenState extends State<DriverMenuScreen> {
  UserModel? userModel;
  final AuthService authService = AuthService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        setState(() {
          userModel = UserModel.fromFirestore(userData, userDoc.id);
        });
      } else {
        log('User document does not exist or data is null');
      }
    } catch (e, stackTrace) {
      log('Error fetching user data: $e');
      log('Stack trace: $stackTrace');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0XFF419A95),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    // Handle case when userModel is still null
    if (userModel == null) {
      return Scaffold(
        backgroundColor: const Color(0XFF419A95),
        body: Center(
          child: Text(
            'Unable to load user data. Please try again later.',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenHeight * 0.03,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0XFF419A95),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DriverMapScreen(userModel: userModel!, busRouteModel: widget.busRouteModel),));
                  },
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: screenWidth * 0.08,
                  ),
                ),
              ),
            ),
            CircleAvatar(
              radius: screenWidth * 0.2,
              backgroundImage: userModel!.profileImageUrl.isNotEmpty
                  ? NetworkImage(userModel!.profileImageUrl)
                  : null,
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              userModel!.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenHeight * 0.05,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Divider(color: Colors.white),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverProfileScreen(
                      userModel: userModel!,
                      busRouteModel: widget.busRouteModel,
                    ),
                  ),
                );
              },
              title: Text(
                "Profile",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: screenHeight * 0.025,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(color: Colors.white),
            ListTile(
              onTap: () {
                if (userModel!.busNumber.isEmpty || userModel!.busColor.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Kindly complete details of bus in profile'),
                    ),
                  );
                  return;
                }else{
 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverManageStops(
                      userModel: userModel!,
                      busRouteModel: widget.busRouteModel,
                    ),
                  ),
                );
                }
               
              },
              title: Text(
                "Manage Stops",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: screenHeight * 0.025,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            Container(
              width: double.infinity,
              height: screenHeight * 0.35,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenHeight * 0.03),
                  topRight: Radius.circular(screenHeight * 0.03),
                ),
              ),
              child: Center(
                child: CustomButton(
                  onTap: () async {
                    await authService.logout(context: context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WelcomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  text: "Logout",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



   

}



 

