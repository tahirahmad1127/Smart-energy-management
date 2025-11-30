import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app/theme/energy_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool pushEnabled = true;
  bool emailEnabled = false;
  bool billAlerts = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('notifications').get();

    if (doc.exists) {
      Map data = doc.data()!;
      setState(() {
        pushEnabled = data['push'] ?? true;
        emailEnabled = data['email'] ?? false;
        billAlerts = data['bill'] ?? true;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateSetting(String key, bool value) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() {
      if (key == 'push') pushEnabled = value;
      if (key == 'email') emailEnabled = value;
      if (key == 'bill') billAlerts = value;
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('notifications').set({
      key: value
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? EnergyTheme.darkGradient.colors
        : EnergyTheme.primaryGradient.colors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.4, 0.9],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Notifications",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.notifications_active, color: Colors.white, size: 60),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildSwitch(Icons.smartphone, "Push Notifications", "Receive alerts on this phone", pushEnabled, (v) => _updateSetting('push', v)),
                    Divider(height: 1, color: Colors.grey.shade100),
                    _buildSwitch(Icons.email_outlined, "Email Alerts", "Receive bill summaries via email", emailEnabled, (v) => _updateSetting('email', v)),
                    Divider(height: 1, color: Colors.grey.shade100),
                    _buildSwitch(Icons.bolt, "High Usage Warning", "Alert when usage spikes", billAlerts, (v) => _updateSetting('bill', v)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(IconData icon, String title, String subtitle, bool value, Function(bool) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: EnergyTheme.primaryCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:  Icon(icon, color: EnergyTheme.primaryCyan),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey,
          ),
        ),
        value: value,
        activeColor: EnergyTheme.primaryCyan,
        onChanged: onChanged,
      ),
    );
  }
}