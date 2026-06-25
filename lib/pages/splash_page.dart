import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../services/user_provider.dart';
import '../theme/app_theme.dart';
import 'phone_login_page.dart';
import 'main_navigation_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    final startTime = DateTime.now();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Wait for user data to load from storage
    await userProvider.initializationFuture;
    
    // Ensure splash shows for at least 3 seconds total
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 3000) {
      await Future.delayed(Duration(milliseconds: 3000 - elapsed));
    }

    if (!mounted) return;

    if (userProvider.isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationPage()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PhoneLoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle, 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05), 
                      blurRadius: 20, 
                      spreadRadius: 5
                    )
                  ]
                ),
                child: Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/Logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Text(
                "Suja Creations",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36, 
                  fontWeight: FontWeight.bold, 
                  color: AppColors.primaryStart
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: Text(
                "Elegant • Timeless • Premium",
                style: GoogleFonts.poppins(
                  fontSize: 14, 
                  color: AppColors.textSecondary, 
                  letterSpacing: 2
                ),
              ),
            ),
            const SizedBox(height: 100),
            FadeIn(
              delay: const Duration(milliseconds: 1500),
              child: const CircularProgressIndicator(
                color: AppColors.primaryStart, 
                strokeWidth: 2
              ),
            ),
          ],
        ),
      ),
    );
  }
}
