import 'package:first_bus_project/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission is required for this app to work';
        });
        return;
      }

      if (!mounted) return;

      // Check user and navigate
      await _authService.checkUserAndNavigate(
        context: context,
        mounted: mounted,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error initializing app: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Image.asset(
                  "assets/logo.png",
                  height: screenHeight * 0.5,
                  width: screenHeight * 0.3,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.directions_bus,
                      size: screenHeight * 0.3,
                      color: Theme.of(context).primaryColor,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            else
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
