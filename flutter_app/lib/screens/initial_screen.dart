import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'main_screen.dart';

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;

          // Design dimensions based on Figma (440 x 956)
          
          return SizedBox(
            width: w,
            height: h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Spacer: ~222px -> ~23% of height
                const Spacer(flex: 23), 
                
                // Text: World / Education
                Column(
                  children: [
                    Text(
                      'World',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: w * 0.09, // ~40px on 440w
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Education',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: w * 0.09,
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),

                // Spacer to SVG
                const Spacer(flex: 15),

                // SVG Icon
                SvgPicture.asset(
                  'assets/images/world_education.svg',
                  width: w * 0.23, // Scaling relative to width
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  fit: BoxFit.contain,
                ),

                // Spacer to Button
                const Spacer(flex: 25),

                // Start Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                    );
                  },
                  child: Container(
                    width: w * 0.58, // 258/440
                    height: h * 0.072, // 69/956
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Start',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: w * 0.064, // 28/440
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),

                // Bottom padding
                const Spacer(flex: 11),
              ],
            ),
          );
        },
      ),
    );
  }
}
