import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF466365), Color(0xFF1E293B)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Modern Economic Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB49A67).withOpacity(0.3), width: 2),
              ),
              child: const Icon(
                Icons.insights_rounded, // Modern economic/analytics icon
                size: 80, 
                color: Color(0xFFB49A67),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'أخبار العملات',
              style: TextStyle(
                color: Colors.white, 
                fontSize: 32, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'أسعار الصرف والتحليل الاقتصادي الذكي',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const Spacer(flex: 2),
            const CircularProgressIndicator(color: Color(0xFFB49A67)),
            const SizedBox(height: 40),
            const Text(
              'عمل الطالب: مؤيد حميد',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              'بإشراف الدكتور القدير:',
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.1),
            ),
            const SizedBox(height: 4),
            const Text(
              'مازن المصطفى',
              style: TextStyle(
                color: Color(0xFFB49A67), 
                fontSize: 28, 
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Colors.black45, offset: Offset(0, 3), blurRadius: 6)
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
