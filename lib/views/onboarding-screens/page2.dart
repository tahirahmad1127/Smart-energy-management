import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

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
                padding: const EdgeInsets.only(top: 70),
                child: Container(
                    width: 300, height: 300,
                    child: Image.asset('assets/images/onboarding21.png')),
              ),
              SizedBox(height: 10,),
              Text("Track Your Energy Live",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      textStyle: TextStyle(fontWeight:
                      FontWeight.w700, fontSize: 28, color: Colors.black))),
              SizedBox(height: 12,),
              Text("Get instant insights on your power consumption and reduce costs.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      textStyle: TextStyle(fontWeight:
                      FontWeight.w400, fontSize: 16, color: Color(0xff4B5563) ))),
              SizedBox(height: 20,),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xffE5E7EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                height: 65, width: 310,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/lightning.png'),
                      SizedBox(width: 6,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("Real-time Monitoring",
                          textAlign: TextAlign.start,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xff1F2937)
                          )
                          ),
                          SizedBox(height: 1,),
                          Text("Track voltage and current instantly",
                              textAlign: TextAlign.start,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xff4B5563)
                              )
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16,),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xffE5E7EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                height: 65, width: 310,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/analytics.png'),
                      SizedBox(width: 6,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("Usage Analytics",
                              textAlign: TextAlign.start,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff1F2937)
                              )
                          ),
                          SizedBox(height: 1,),
                          Text("Detailed consumption patterns",
                              textAlign: TextAlign.start,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xff4B5563)
                              )
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16,),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xffE5E7EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                height: 65, width: 310,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/alert.png'),
                      SizedBox(width: 6,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("Smart Alerts",
                              textAlign: TextAlign.start,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff1F2937)
                              )
                          ),
                          SizedBox(height: 1,),
                          Text("Get notified of unusual activity",
                              textAlign: TextAlign.start,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xff4B5563)
                              )
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}
