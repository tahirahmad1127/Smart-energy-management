import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/theme/energy_theme.dart';
import 'package:news_app/views/login.dart';
// Removed AuthServices import as it is no longer needed here
import 'about_screen.dart';
import 'change_password.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "Loading...";
  String email = "";
  String phone = "--";
  String address = "--";
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => email = user.email ?? "");
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            name = data['name'] ?? "No Name";
            phone = data['phone'] ?? "No Phone";
            address = data['address'] ?? "No Address";
            _isLoading = false;
          });
        } else {
          setState(() {
            name = "User not found";
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Removed _handleLogout and _showLogoutConfirmation from here

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? EnergyTheme.darkGradient.colors
        : [
      EnergyTheme.primaryCyan,
      EnergyTheme.primaryCyan,
      const Color(0xffFFFFFF),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Profile",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
            child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            children: [
              // --- AVATAR SECTION ---
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: EnergyTheme.primaryCyan.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "U",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: EnergyTheme.primaryCyan),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
              Text(
                email,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 14),
              ),

              const SizedBox(height: 35),

              // --- INFO CARDS ---
              _buildSectionHeader("Personal Details"),
              _buildCard([
                _buildInfoRow(Icons.phone_iphone_rounded, "Phone", phone),
                _buildDivider(),
                _buildInfoRow(
                    Icons.location_on_rounded, "Address", address),
              ]),

              const SizedBox(height: 25),

              // --- SETTINGS SECTION ---
              _buildSectionHeader("Settings"),
              _buildCard([
                // 1. Edit Profile
                _buildMenuRow(Icons.edit_rounded, "Edit Profile",
                        () async {
                      bool? updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => EditProfileScreen(currentData: {
                                'name': name,
                                'phone': phone,
                                'address': address
                              })));
                      if (updated == true) _getUserData();
                    }),

                _buildDivider(),

                // 2. Change Password
                _buildMenuRow(Icons.lock_rounded, "Change Password", () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()));
                }),
              ]),

              const SizedBox(height: 25),

              // --- SUPPORT SECTION ---
              _buildSectionHeader("Support"),
              _buildCard([
                _buildMenuRow(
                    Icons.info_outline_rounded, "About Voltify", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()));
                }),
              ]),

              const SizedBox(height: 40),

              // LOGOUT BUTTON REMOVED FROM HERE
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                    color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)
              ]),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildIconBox(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildIconBox(icon),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.grey, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: EnergyTheme.primaryCyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: EnergyTheme.primaryCyan, size: 22),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(
          height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),
    );
  }
}