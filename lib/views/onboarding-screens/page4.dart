import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:news_app/views/login.dart';
import 'package:news_app/views/register.dart';
import 'package:news_app/views/terms_and_conditions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class Onboarding4 extends StatefulWidget {
  const Onboarding4({super.key});

  @override
  State<Onboarding4> createState() => _Onboarding4State();
}

class _Onboarding4State extends State<Onboarding4> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/money.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0)
    ,
    child
    :
    Container
    (
    decoration
    :
    BoxDecoration
    (
    gradient
    :
    LinearGradient
    (
    begin
    :
    Alignment
    .
    topCenter
    ,
    end
    :
    Alignment
    .
    bottomCenter
    ,
    colors
    :
    [
    Color
    (
    0xff000000
    )
    ,
    Color
    (
    0xff23ABC3
    )
    ,
    Color
    (
    0xffFFFFFF
    )
    ]
    ,
    )
    ,
    )
    ,
    child
    :
    Scaffold
    (
    backgroundColor
    :
    Colors
    .
    transparent
    ,
    body
    :
    Center
    (
    child
    :
    Padding
    (
    padding
    :
    const
    EdgeInsets
    .
    only
    (
    top
    :
    10
    )
    ,
    child
    :
    SingleChildScrollView
    (
    child
    :
    Column
    (
    mainAxisAlignment
    :
    MainAxisAlignment
    .
    center
    ,
    crossAxisAlignment
    :
    CrossAxisAlignment
    .
    center
    ,
    children
    :
    [
    Container
    (
    height
    :
    300
    ,
    width
    :
    MediaQuery
    .
    of
    (
    context
    ).size.width,
    child: _controller.value.isInitialized
    ? ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: AspectRatio(
    aspectRatio: _controller.value.aspectRatio,
    child: VideoPlayer(_controller),
    ),
    )
        : Center(child: CircularProgressIndicator()),
    ),
    SizedBox(height: 40),
    Text(
    "Save Energy, Save Money",
    textAlign: TextAlign.center,
    style: GoogleFonts.poppins(
    textStyle: TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 25,
    color: Color(0xff111827),
    ),
    ),
    ),
    SizedBox(height: 20),
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(
    "Smart insights help you cut costs without effort",
    textAlign: TextAlign.center,
    style: GoogleFonts.poppins(
    textStyle: TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: Color(0xff4B5563),
    ),
    ),
    ),
    ),
    SizedBox(height: 50),
    ElevatedButton(
    style: ElevatedButton.styleFrom(
    minimumSize: Size(150, 50),
    backgroundColor: Colors.white,
    ),
    onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => LoginScreen()),
    );
    },
    child: Text("Login", style: GoogleFonts.poppins(
    textStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Colors.black,),
    ))),
    SizedBox(height: 20),
    ElevatedButton(
    style: ElevatedButton.styleFrom(
    minimumSize: Size(150, 50),
    backgroundColor: Colors.white,
    ),
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SignupScreen()),
    );
    },
    child: Text(
    "Signup",
    style: GoogleFonts.poppins(
    textStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Colors.black,
    ),
    ),
    ),
    ),
    SizedBox(height: 90),
    Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Text(
    "To read our Terms & Conditions Tap",
    style: GoogleFonts.poppins(
    textStyle: TextStyle(
    fontWeight: FontWeight.w300,
    fontSize: 8,
    color: Colors.black,
    ),
    ),
    ),
    SizedBox(width: 3),
    TextButton(
    style: TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: Size(0, 0),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => TermsAndConditions()),
    );
    },
    child: Text(
    "Here",
    style: GoogleFonts.poppins(
    textStyle: TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 9,
    color: Colors.black,
    ),
    ),
    ),
    ),
    ],
    ),
    Text(
    "By Sign Up Or Login you have agreed to our Terms & Conditions",
    style: GoogleFonts.poppins(
    textStyle: TextStyle(
    fontWeight: FontWeight.w300,
    fontSize: 8,
    color: Colors.black,
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    ),
    ),
    ),
    );
  }
}
