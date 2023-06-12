import 'package:chitchat/screens/auth.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  double _opacityLogo = 0.0;
  bool _showSpinner = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    // Display the logo with animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        _opacityLogo = 1.0;
      });

      // Display the loading spinner
      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() {
          _showSpinner = true;
        });
      });

      // Change screen
      Future.delayed(const Duration(seconds: 4), () {
        setState(() {
          _showSpinner = false;
        });
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(
              milliseconds: 500,
            ), // Adjust the duration as needed
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedOpacity(
              opacity: _opacityLogo,
              duration: const Duration(milliseconds: 300),
              child: Image.asset('assets/images/logo1.png'),
            ),
            if (_showSpinner) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
