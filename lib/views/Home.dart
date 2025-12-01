import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news_app/theme/energy_theme.dart';
import 'package:news_app/services/notification_service.dart';

// --- IMPORTS FOR NAVIGATION ---
import 'package:news_app/views/alerts_notifications_screen.dart';
import 'package:news_app/views/profile_screen.dart';
import 'package:news_app/views/settings_screen.dart';

import 'analytics.dart';
import 'bill_screen.dart';
import 'devices.dart';
import 'prepaid_billing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Use the same database reference as Devices screen
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://esp32energymonitor-934bb-default-rtdb.firebaseio.com'
  ).ref("energyMonitor");

  // --- NAVIGATION STATE ---
  int _selectedIndex = 0;

  // Sensor data
  double _voltage = 0.0;
  double _power = 0.0;
  int _previousMotion = 0; // Track previous motion state
  
  // Energy and bill data
  double _totalEnergyConsumed = 0.0;
  double _currentBill = 0.0;

  // Device names
  Map<String, String> _deviceNames = {};
  List<String> _activeDeviceKeys = [];

  StreamSubscription<DatabaseEvent>? _databaseSubscription;
  StreamSubscription<DatabaseEvent>? _motionSubscription;

  late AnimationController _controller;
  late Animation<Color?> _gradientColor;

  @override
  void initState() {
    super.initState();
    _loadDeviceNames();
    _setupFirebaseListener();
    _setupMotionListener();

    // Animation controller for gradient color
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Tween between primary color and off-white/cream
    _gradientColor = ColorTween(
      begin: EnergyTheme.primaryCyan,
      end: const Color(0xffFFFDD0),
    ).animate(_controller);
  }

  void _setupFirebaseListener() {
    _databaseSubscription = _database.onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        setState(() {
          // Get voltage from Firebase - ensure it's connected properly
          _voltage = double.tryParse(data['voltage']?.toString() ?? '0') ?? 0.0;
          
          // Get power from Firebase or calculate if needed
          if (data['power'] != null) {
            _power = double.tryParse(data['power']?.toString() ?? '0') ?? 0.0;
          } else if (data['voltage'] != null && data['current'] != null) {
            // Calculate power = voltage * current if power not available
            double voltage = double.tryParse(data['voltage']?.toString() ?? '0') ?? 0.0;
            double current = double.tryParse(data['current']?.toString() ?? '0') ?? 0.0;
            _power = voltage * current;
          } else {
            _power = 0.0;
          }
          
          // Get total energy and bill
          _totalEnergyConsumed = double.tryParse(data['totalEnergyKWh']?.toString() ?? '0') ?? 0.0;
          _currentBill = double.tryParse(data['bill']?.toString() ?? '0') ?? 0.0;

          // Get active device keys
          List<String> relayKeys = data.keys
              .where((k) => k.toString().startsWith("relay") && !k.toString().contains("schedule"))
              .cast<String>()
              .toList();
          
          relayKeys.sort((a, b) {
            int indexA = a == 'relay' ? 0 : int.tryParse(a.replaceAll('relay', '')) ?? 999;
            int indexB = b == 'relay' ? 0 : int.tryParse(b.replaceAll('relay', '')) ?? 999;
            return indexA.compareTo(indexB);
          });

          // Filter active devices
          _activeDeviceKeys = [];
          for (var key in relayKeys) {
            String schKey = key == "relay" ? "schedule" : key.replaceAll("relay", "schedule");
            Map sData = (data[schKey] is Map) ? data[schKey] : {};
            int manualVal = int.tryParse(data[key]?.toString() ?? '0') ?? 0;
            bool isSched = (int.tryParse(sData["active"]?.toString() ?? '0') ?? 0) == 1;
            
            // Calculate if device is on based on schedule or manual
            bool isOn = false;
            if (isSched) {
              int startH = int.tryParse(sData["startHour"]?.toString() ?? '18') ?? 18;
              int startM = int.tryParse(sData["startMin"]?.toString() ?? '0') ?? 0;
              int stopH = int.tryParse(sData["stopHour"]?.toString() ?? '6') ?? 6;
              int stopM = int.tryParse(sData["stopMin"]?.toString() ?? '0') ?? 0;

              final now = DateTime.now();
              int currentMins = now.hour * 60 + now.minute;
              int startMins = startH * 60 + startM;
              int stopMins = stopH * 60 + stopM;

              if (startMins < stopMins) {
                isOn = (currentMins >= startMins && currentMins < stopMins);
              } else {
                isOn = (currentMins >= startMins || currentMins < stopMins);
              }
            } else {
              isOn = (manualVal == 1);
            }
            
            if (isOn) {
              _activeDeviceKeys.add(key);
            }
          }
        });
      }
    });
  }

  void _setupMotionListener() {
    _motionSubscription = _database.child('motion').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        int currentMotion = int.tryParse(event.snapshot.value.toString()) ?? 0;
        
        // Only trigger when motion changes from 0 to 1
        if (currentMotion == 1 && _previousMotion == 0) {
          _handleMotionDetected();
        }
        
        _previousMotion = currentMotion;
      }
    });
  }

  Future<void> _handleMotionDetected() async {
    try {
      // Check if alerts are muted
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        bool muteAlerts = false;
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          muteAlerts = data['muteAlerts'] ?? false;
        }

        if (!muteAlerts) {
          // Send push notification
          await NotificationService.showMotionNotification();

          // Save to Firestore for Alerts screen
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('alerts')
              .add({
            'title': 'Motion Detected',
            'message': 'Movement detected by your smart energy system.',
            'timestamp': FieldValue.serverTimestamp(),
            'icon': 'motion',
            'type': 'motion',
            'read': false,
          });
        }
      }
    } catch (e) {
      debugPrint('Error handling motion detection: $e');
    }
  }

  Future<void> _loadDeviceNames() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    Map<String, String> loadedNames = {};
    for (String key in keys) {
      if (key.startsWith("relay")) {
        loadedNames[key] = prefs.getString(key) ?? "Device";
      }
    }
    setState(() {
      _deviceNames = loadedNames;
    });
  }

  String _getDeviceName(String key) {
    if (_deviceNames.containsKey(key)) {
      return _deviceNames[key]!;
    }
    if (key == "relay") {
      return "Main Device";
    }
    int index = int.tryParse(key.replaceAll("relay", "")) ?? 999;
    return "Device $index";
  }

  void _showAllDevicesBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'All Connected Devices',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _activeDeviceKeys.length,
                itemBuilder: (context, index) {
                  String key = _activeDeviceKeys[index];
                  String deviceName = _getDeviceName(key);
                  return ListTile(
                    leading: Icon(
                      Icons.power_settings_new,
                      color: EnergyTheme.primaryCyan,
                    ),
                    title: Text(
                      deviceName,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'On',
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_activeDeviceKeys.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No active devices',
                  style: GoogleFonts.poppins(
                    color: textColor.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _databaseSubscription?.cancel();
    _motionSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // --- HANDLE TAB TAPS ---
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // We create the list of pages here so we can pass context if needed
    final List<Widget> _pages = [
      _buildDashboardView(),          // Index 0: Your original Home Dashboard
      const DevicesScreen(),          // Index 1: The Device Manager (Make sure class name matches)
      const EnergyStatisticsScreen(), // Index 2: Usage Screen
      const BillScreen(),             // Index 3: Bill Screen
      const PrepaidBillingScreen(),   // Index 4: Prepaid Billing Screen
    ];

    final gradientColors = isDark
        ? EnergyTheme.darkGradient.colors
        : [
      _gradientColor.value ?? EnergyTheme.primaryCyan,
      EnergyTheme.primaryCyan,
      const Color(0xffFFFFFF),
    ];

    return AnimatedBuilder(
      animation: _gradientColor,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                const Color(0xFF1E1E1E),
                const Color(0xFF2C2C2C),
                const Color(0xFF121212),
              ]
                  : gradientColors,
            ),
          ),
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,

        // Only show the Home AppBar if we are on the Home Tab (Index 0)
        // DevicesScreen has its own AppBar, so we hide this one to avoid double headers.
        appBar: _selectedIndex == 0 ? AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
              child: const CircleAvatar(
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
            ),
          ),
          title: Text(
            'Energy Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, AlertsNotificationsScreen.routeName),
              icon: Icon(Icons.notifications_none, color: isDark ? Colors.white : Colors.black),
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, SettingsScreen.routeName),
              icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ) : null, // Return null to hide AppBar on other tabs

        // Switch the body based on selected index
        body: _pages[_selectedIndex],

        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          selectedItemColor: EnergyTheme.primaryCyan,
          unselectedItemColor: isDark ? Colors.grey.shade600 : Colors.grey,
          currentIndex: _selectedIndex, // Connect state
          onTap: _onItemTapped,         // Connect handler
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Devices'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Usage'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Bill'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Prepaid'),
          ],
        ),
      ),
    );
  }

  // --- ORIGINAL HOME CONTENT MOVED HERE ---
  Widget _buildDashboardView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnergyCard(),
          const SizedBox(height: 16),
          Text(
            'Real-time Monitoring',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildVoltageGauge(isDark)),
              const SizedBox(width: 10),
              Expanded(child: _buildPowerGauge(isDark)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Connected Devices',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: _activeDeviceKeys.length > 1 ? _showAllDevicesBottomSheet : null,
                child: Text(
                  _activeDeviceKeys.length > 1 ? 'View All' : '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: EnergyTheme.primaryCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          if (_activeDeviceKeys.isNotEmpty)
            Row(
              children: [
                Icon(Icons.arrow_forward_ios, size: 28, color: EnergyTheme.primaryCyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDeviceName(_activeDeviceKeys[0]),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'On',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No active devices',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEnergyCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [EnergyTheme.primaryCyan.withOpacity(0.8), EnergyTheme.primaryCyan]
              : [EnergyTheme.primaryCyan, EnergyTheme.primaryCyan.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Energy Consumed', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '${_totalEnergyConsumed.toStringAsFixed(2)} kWh',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('Current Bill', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              Text(
                'PKR ${_currentBill.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Icon(Icons.flash_on, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildVoltageGauge(bool isDark) {
    return SfRadialGauge(
      title: GaugeTitle(
        text: 'Voltage (V)',
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 250,
          interval: 50,
          showLabels: true,
          showTicks: true,
          axisLabelStyle: GaugeTextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          axisLineStyle: const AxisLineStyle(
            thickness: 0.1,
            thicknessUnit: GaugeSizeUnit.factor,
            color: Colors.grey,
          ),
          ranges: [
            GaugeRange(startValue: 0, endValue: 80, color: Colors.green),
            GaugeRange(startValue: 80, endValue: 180, color: Colors.blueAccent),
            GaugeRange(startValue: 180, endValue: 250, color: Colors.redAccent),
          ],
          pointers: [
            NeedlePointer(
              needleStartWidth: 1,
              needleEndWidth: 5,
              value: _voltage,
              enableAnimation: true,
              needleColor: Colors.white,
            )
          ],
          annotations: [
            GaugeAnnotation(
              widget: Text(
                '${_voltage.toStringAsFixed(2)} V',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              angle: 90,
              positionFactor: 0.6,
            )
          ],
        )
      ],
    );
  }

  Widget _buildPowerGauge(bool isDark) {
    // Power range: 0 to 1000W with 200W intervals
    return SfRadialGauge(
      title: GaugeTitle(
        text: 'Power (W)',
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 1000,
          interval: 200,
          showLabels: true,
          showTicks: true,
          axisLabelStyle: GaugeTextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          axisLineStyle: const AxisLineStyle(
            thickness: 0.1,
            thicknessUnit: GaugeSizeUnit.factor,
            color: Colors.grey,
          ),
          ranges: [
            GaugeRange(startValue: 0, endValue: 400, color: Colors.green),
            GaugeRange(startValue: 400, endValue: 700, color: Colors.blueAccent),
            GaugeRange(startValue: 700, endValue: 1000, color: Colors.redAccent),
          ],
          pointers: [
            NeedlePointer(
              needleStartWidth: 1,
              needleEndWidth: 5,
              value: _power.clamp(0.0, 1000.0), // Clamp to gauge range
              enableAnimation: true,
              needleColor: Colors.white,
            )
          ],
          annotations: [
            GaugeAnnotation(
              widget: Text(
                '${_power.toStringAsFixed(0)} W',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              angle: 90,
              positionFactor: 0.6,
            )
          ],
        )
      ],
    );
  }
}
