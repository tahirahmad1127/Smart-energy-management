import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff000000),
                  Color(0xff23ABC3),
                  Color(0xffFFFFFF)
                ]
            )
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 173),
                  child: Container(
                      width: 300, height: 300,
                      child: Image.asset('assets/images/onboarding1.png')),
                ),
                SizedBox(height: 32,),
                Text("Welcome to Voltify",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                    textStyle: TextStyle(fontWeight:
                    FontWeight.w700, fontSize: 30, color: Colors.black))),
                SizedBox(height: 19,),
                Text("Control and optimize your energy usage effortlessly",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                      textStyle: TextStyle(fontWeight:
                      FontWeight.w400, fontSize: 18, color: Color(0xff4B5563) ))),
              ],
            ),
          ),
        ),
      );

  }
}
