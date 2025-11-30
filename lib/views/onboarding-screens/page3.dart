import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

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
            Color(0xffFFFFFF),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 50),
                Text(
                  "Automate Your Devices",
                  textAlign: TextAlign.start,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: Color(0xffF9F6EE),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Set schedules and let your home work for you",
                  textAlign: TextAlign.start,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0xffFFFDD0),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: 300,
                  height: 300,
                  child: Image.asset('assets/images/onboarding2.png'),
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xffE5E7EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  height: 65,
                  width: 310,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/schedule.png'),
                        SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Schedule Devices",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff1F2937),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                "Set specific times for devices to turn on/off",
                                softWrap: true,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xff4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Smart Lighting
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xffE5E7EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  height: 65,
                  width: 310,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/bulb.png'),
                        SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Smart Lighting",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff1F2937),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                "Automatic brightness based on time of day",
                                softWrap: true,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xff4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Custom Routines
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xffE5E7EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  height: 65,
                  width: 310,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/custom.png'),
                        SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Custom Routines",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff1F2937),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                "Create your perfect automation sequence",
                                softWrap: true,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xff4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
