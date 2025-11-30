import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ADDED AUTH SERVICES IMPORT
import 'package:news_app/services/auth.dart';
import 'package:news_app/theme/theme_manager.dart';
import 'package:news_app/theme/energy_theme.dart';

import 'support_screens.dart';
import 'about_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State Variables
  bool _isDarkMode = false;
  String _selectedTimezone = "PKT (UTC+5)";
  bool _isLoading = false;


  // Timezone List
  final List<String> _timezones = [
    "PKT (UTC+5)",
    "IST (UTC+5:30)",
    "EST (UTC-5)",
    "PST (UTC-8)",
    "GMT (UTC+0)",
    "System Default"
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
  }

  // 1. Load Settings from Local Storage
  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = themeManager.themeMode == ThemeMode.dark;
      _selectedTimezone = prefs.getString('timezone') ?? "PKT (UTC+5)";
    });
  }

  // 2. Save WiFi to Firebase
  Future<void> _saveWifiCredentials(String ssid, String password) async {
    Navigator.pop(context); // Close Bottom Sheet
    setState(() => _isLoading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      // Write to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('device_config').doc('wifi').set({
        'ssid': ssid,
        'password': password,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackbar("WiFi Credentials updated on Cloud!");
    } catch (e) {
      _showErrorSnackbar("Failed to save: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. Helper to Launch Email/Phone
  Future<void> _launchContact(String scheme, String path) async {
    final Uri launchUri = Uri(scheme: scheme, path: path);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint("Could not launch $scheme");
    }
  }

  // 4. Logout Confirmation Dialog (Added Here)
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to log out of your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              AuthServices().signOut(context); // Perform the actual logout
            },
            child: Text("Log Out", style: TextStyle(color: EnergyTheme.primaryCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
          colors: gradientColors,
          begin: Alignment.topCenter, 
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Settings",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // --- SECTION 1: PREFERENCES ---
              _buildHeader("General"),
              _buildPremiumCard([
                _buildSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  gradient: const [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                  title: "Dark Mode",
                  subtitle: "Switch theme",
                  value: _isDarkMode,
                  onChanged: (v) async {
                    setState(() => _isDarkMode = v);
                    // Use ThemeManager to toggle theme - this will update all screens
                    await themeManager.toggleTheme(v);
                  },
                ),
                _buildDivider(),
                _buildNavTile(
                  icon: Icons.access_time_filled_rounded,
                  gradient: const [Color(0xFFFF512F), Color(0xFFDD2476)],
                  title: "Timezone",
                  subtitle: _selectedTimezone,
                  onTap: _showTimezonePicker,
                ),
                _buildDivider(),
                _buildNavTile(
                  icon: Icons.notifications_active_rounded,
                  gradient: const [Color(0xFFFF8008), Color(0xFFFFC837)],
                  title: "Notifications",
                  subtitle: "Manage alerts",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  },
                ),
              ]),

              const SizedBox(height: 30),

              // --- SECTION 2: HARDWARE ---
              _buildHeader("Hardware"),
              _buildPremiumCard([
                _buildNavTile(
                  icon: Icons.wifi_tethering,
                  gradient: [EnergyTheme.primaryCyan, EnergyTheme.primaryCyan.withOpacity(0.6)],
                  title: "Device Connection",
                  subtitle: "Setup ESP32 WiFi",
                  onTap: () => _showWifiBottomSheet(context),
                ),
              ]),

              const SizedBox(height: 30),

              // --- SECTION 3: SUPPORT ---
              _buildHeader("Support"),
              _buildPremiumCard([
                _buildNavTile(
                  icon: Icons.support_agent_rounded,
                  gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                  title: "Support Center",
                  subtitle: "Contact us",
                  onTap: () => _showContactSheet(context),
                ),
                _buildDivider(),
                _buildNavTile(
                  icon: Icons.live_help_rounded,
                  gradient: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  title: "FAQs",
                  subtitle: "Common questions",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                ),
              ]),

              const SizedBox(height: 40),

              // --- LOGOUT BUTTON (ADDED HERE) ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _showLogoutConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: EnergyTheme.primaryCyan.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded),
                      SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // UI COMPONENTS (Cards, Tiles, Gradients)
  // ===========================================================================

  Widget _buildHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              _buildGradientIcon(icon, gradient),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildGradientIcon(icon, gradient),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: EnergyTheme.primaryCyan,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            onChanged: onChanged,
          )
        ],
      ),
    );
  }

  Widget _buildGradientIcon(IconData icon, List<Color> gradient) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 86),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.black.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 10), Text(message)])
        )
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(message)));
  }

  // ===========================================================================
  // BOTTOM SHEETS & DIALOGS
  // ===========================================================================

  // 1. Timezone Picker
  void _showTimezonePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8
        ),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10)
                  )
              ),
              const Padding(
                  padding: EdgeInsets.all(25),
                  child: Text(
                      "Select Timezone",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)
                  )
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _timezones.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  bool isSelected = _selectedTimezone == _timezones[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                    title: Text(
                        _timezones[index],
                        style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? EnergyTheme.primaryCyan : Colors.black87
                        )
                    ),
                    trailing: isSelected ? Icon(Icons.check_circle, color: EnergyTheme.primaryCyan) : null,
                    onTap: () async {
                      setState(() => _selectedTimezone = _timezones[index]);
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString('timezone', _timezones[index]);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  // 2. WiFi Config Sheet
  void _showWifiBottomSheet(BuildContext context) {
    final ssidController = TextEditingController();
    final passController = TextEditingController();
    bool obscureText = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 30),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: EnergyTheme.primaryCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.wifi_find_rounded, color: EnergyTheme.primaryCyan, size: 28),
                    ),
                    const SizedBox(width: 15),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Connect ESP32", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                        Text("Configure hardware internet", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: ssidController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: "WiFi SSID",
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: EnergyTheme.primaryCyan, width: 2)),
                    prefixIcon: Icon(Icons.router_rounded, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passController,
                  obscureText: obscureText,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: "WiFi Password",
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: EnergyTheme.primaryCyan, width: 2)),
                    prefixIcon: Icon(Icons.lock_rounded, color: Colors.grey.shade600),
                    suffixIcon: IconButton(
                      icon: Icon(obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.grey.shade600),
                      onPressed: () => setState(() => obscureText = !obscureText),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () => _saveWifiCredentials(ssidController.text, passController.text),
                    child: const Text("Save Configuration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3. Contact Sheet
  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Support Center", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.email, color: Colors.white)),
              title: const Text("Email Us", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("support@voltify.com"),
              onTap: () => _launchContact('mailto', 'support@voltify.com'),
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.phone, color: Colors.white)),
              title: const Text("Call Us", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("+92 300 1234567"),
              onTap: () => _launchContact('tel', '+923001234567'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
            )
          ],
        ),
      ),
    );
  }
}