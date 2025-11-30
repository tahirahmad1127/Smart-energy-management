import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/theme/energy_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertsNotificationsScreen extends StatefulWidget {
  const AlertsNotificationsScreen({super.key});

  static const routeName = '/alerts-notifications';

  @override
  State<AlertsNotificationsScreen> createState() => _AlertsNotificationsScreenState();
}

class _AlertsNotificationsScreenState extends State<AlertsNotificationsScreen> {
  bool _muteAlerts = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMuteSetting();
  }

  Future<void> _loadMuteSetting() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _muteAlerts = data['muteAlerts'] ?? false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _muteAlerts = false;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mute setting: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMuteSetting(bool value) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _muteAlerts = value;
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'muteAlerts': value,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Notifications muted' : 'Notifications enabled',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: value ? Colors.orange : EnergyTheme.primaryCyan,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating mute setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      // Revert the state on error
      setState(() {
        _muteAlerts = !value;
      });
    }
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
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

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
          title: Text(
            'Alerts & Notifications',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: EnergyTheme.primaryCyan,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    
                    // Mute Notifications Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: EnergyTheme.primaryCyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.notifications_off_rounded,
                              color: EnergyTheme.primaryCyan,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mute Notifications',
                                  style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Temporarily disable all energy usage alerts',
                                  style: GoogleFonts.poppins(
                                    color: subTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Switch(
                            value: _muteAlerts,
                            onChanged: _updateMuteSetting,
                            activeColor: Colors.white,
                            activeTrackColor: EnergyTheme.primaryCyan,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Motion Alerts Section
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseAuth.instance.currentUser != null
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('alerts')
                              .where('type', isEqualTo: 'motion')
                              .orderBy('timestamp', descending: true)
                              .limit(10)
                              .snapshots()
                          : null,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: EnergyTheme.primaryCyan.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.bolt_rounded,
                                    color: EnergyTheme.primaryCyan,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Future Alerts',
                                  style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your energy usage alerts will appear here once implemented.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: subTextColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motion Alerts',
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final timestamp = data['timestamp'] as Timestamp?;
                              final timeStr = timestamp != null
                                  ? _formatTimestamp(timestamp.toDate())
                                  : 'Just now';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: EnergyTheme.primaryCyan.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.sensors_rounded,
                                        color: EnergyTheme.primaryCyan,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['title'] ?? 'Motion Detected',
                                            style: GoogleFonts.poppins(
                                              color: textColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data['message'] ?? 'Movement detected by your smart energy system.',
                                            style: GoogleFonts.poppins(
                                              color: subTextColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            timeStr,
                                            style: GoogleFonts.poppins(
                                              color: subTextColor.withOpacity(0.7),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
