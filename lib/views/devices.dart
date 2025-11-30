import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news_app/theme/energy_theme.dart';

import 'settings_screen.dart';
import 'profile_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  // Use .instanceFor if you are in a specific region, otherwise use .instance
  final dbRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://esp32energymonitor-934bb-default-rtdb.firebaseio.com'
  ).ref("energyMonitor");

  Map<String, String> _deviceNames = {};

  @override
  void initState() {
    super.initState();
    _loadAllSavedNames();
  }

  // --- 1. LOAD SAVED NAMES ---
  Future<void> _loadAllSavedNames() async {
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

  // --- 2. SAVE NAME ---
  Future<void> _saveDeviceName(String key, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, newName);
    setState(() {
      _deviceNames[key] = newName;
    });
  }

  // --- 3. HELPER: GET INDEX ---
  int _getRelayIndex(String key) {
    if (key == 'relay') return 0;
    return int.tryParse(key.replaceAll('relay', '')) ?? 999;
  }

  // --- 4. HELPER: CALCULATE SCHEDULE STATE ---
  bool _calculateScheduleState(Map schedData) {
    int startH = int.tryParse(schedData["startHour"].toString()) ?? 18;
    int startM = int.tryParse(schedData["startMin"].toString()) ?? 0;
    int stopH = int.tryParse(schedData["stopHour"].toString()) ?? 6;
    int stopM = int.tryParse(schedData["stopMin"].toString()) ?? 0;

    final now = DateTime.now();
    int currentMins = now.hour * 60 + now.minute;
    int startMins = startH * 60 + startM;
    int stopMins = stopH * 60 + stopM;

    if (startMins < stopMins) {
      return (currentMins >= startMins && currentMins < stopMins);
    } else {
      return (currentMins >= startMins || currentMins < stopMins);
    }
  }

  // --- 5. HELPER: FORMAT TIME ---
  String _formatTime(dynamic h, dynamic m) {
    if (h == null || m == null) return "--:--";
    int hour = int.tryParse(h.toString()) ?? 0;
    int min = int.tryParse(m.toString()) ?? 0;
    String period = hour >= 12 ? "PM" : "AM";
    int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return "$displayHour:${min.toString().padLeft(2, '0')} $period";
  }

  @override
  Widget build(BuildContext context) {
    // Dark Mode Checks
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
    final subTextColor = isDark ? Colors.grey.shade400 : EnergyTheme.primaryCyan;

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
            "Voltify Manager",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          actions: [
            IconButton(
              icon: Icon(Icons.person, color: isDark ? Colors.white : Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
            IconButton(
              icon: Icon(Icons.settings, color: isDark ? Colors.white : Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        body: StreamBuilder(
          stream: dbRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: EnergyTheme.primaryCyan));
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data?.snapshot.value == null) {
              return Center(child: Text("Connecting to Device...", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)));
            }

          Map data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);

          double power = double.tryParse(data["power"].toString()) ?? 0.0;
          double powerKW = power / 1000.0;
          double totalEnergy = double.tryParse(data["totalEnergyKWh"].toString()) ?? 0.0;
          double bill = double.tryParse(data["bill"].toString()) ?? 0.0;

          // Get List of Keys
          List<String> relayKeys = data.keys.where((k) => k.toString().startsWith("relay") && !k.toString().contains("schedule")).cast<String>().toList();
          relayKeys.sort((a, b) => _getRelayIndex(a).compareTo(_getRelayIndex(b)));

          // --- FIX 1: Calculate Actual Active Devices ---
          int activeCount = 0;
          for (var key in relayKeys) {
            String schKey = key == "relay" ? "schedule" : key.replaceAll("relay", "schedule");
            Map sData = (data[schKey] is Map) ? data[schKey] : {};
            int manualVal = int.tryParse(data[key].toString()) ?? 0;
            bool isSched = (int.tryParse(sData["active"].toString()) ?? 0) == 1;
            bool isOn = isSched ? _calculateScheduleState(sData) : (manualVal == 1);
            if (isOn) activeCount++;
          }

            return Column(
              children: [
                // --- SUMMARY CARD ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.grey.shade800 : EnergyTheme.primaryCyan.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Display Active / Total
                          _buildSummaryItem("Active Devices", "$activeCount / ${relayKeys.length}", CrossAxisAlignment.start, textColor, subTextColor),
                          _buildSummaryItem("Total Power", "${powerKW.toStringAsFixed(2)} kW", CrossAxisAlignment.end, textColor, subTextColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

                // --- DEVICE LIST ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: relayKeys.length,
                    itemBuilder: (context, index) {
                      String key = relayKeys[index];
                      String schKey = key == "relay" ? "schedule" : key.replaceAll("relay", "schedule");

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildDeviceCard(context, key, schKey, data, cardColor, textColor, isDark),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, CrossAxisAlignment align, Color txtColor, Color subColor) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: txtColor)),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, String relayKey, String scheduleKey, Map data, Color cardColor, Color textColor, bool isDark) {
    int manualVal = int.tryParse(data[relayKey].toString()) ?? 0;
    Map schedData = (data[scheduleKey] is Map) ? data[scheduleKey] : {};
    bool isSchedActive = (int.tryParse(schedData["active"].toString()) ?? 0) == 1;
    bool isOn = isSchedActive ? _calculateScheduleState(schedData) : (manualVal == 1);

    String defaultName = relayKey == "relay" ? "Main Device" : "Device ${_getRelayIndex(relayKey)}";
    String currentName = _deviceNames[relayKey] ?? defaultName;

    return InkWell(
      onLongPress: () => _showRenameDialog(relayKey, currentName),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: cardColor,
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Top Row: Icon + Name + Switch
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                        color: isOn ? Colors.green.withOpacity(0.2) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                        shape: BoxShape.circle
                    ),
                    child: Icon(Icons.power_settings_new, color: isOn ? Colors.green : Colors.grey, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                        const SizedBox(height: 4),
                        Text(
                          isSchedActive ? (isOn ? "Auto: ON" : "Auto: OFF") : "Manual Mode",
                          style: TextStyle(fontSize: 13, color: isSchedActive ? Colors.orange : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // SWITCH LOGIC
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Switch(
                        value: isOn,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.green,
                        // If Schedule is active, disable the switch visually
                        onChanged: isSchedActive ? null : (val) => dbRef.child(relayKey).set(val ? 1 : 0),
                      ),
                      // If Schedule Active, add invisible tap detector to show warning
                      if (isSchedActive)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => _showScheduleConflictDialog(context, currentName, scheduleKey, schedData),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

              // --- FIX 2: Schedule Button Logic ---
              InkWell(
                onTap: () => _showScheduleDialog(context, currentName, scheduleKey, schedData),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: isDark ? Colors.grey : EnergyTheme.primaryCyan),
                          const SizedBox(width: 8),
                          Text(
                            isSchedActive
                                ? "${_formatTime(schedData['startHour'], schedData['startMin'])} ➔ ${_formatTime(schedData['stopHour'], schedData['stopMin'])}"
                                : "Tap to set schedule",
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade300 : EnergyTheme.primaryCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.edit, size: 16, color: isDark ? Colors.grey : EnergyTheme.primaryCyan.withOpacity(0.5)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- DIALOGS (Restored) ---

  // 1. Rename Dialog
  void _showRenameDialog(String key, String currentName) {
    TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Device Name"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter new name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) _saveDeviceName(key, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // 2. Conflict Dialog
  void _showScheduleConflictDialog(BuildContext context, String name, String key, Map currentData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_clock, size: 48, color: Colors.orange),
        title: const Text("Schedule Active"),
        content: const Text(
          "You cannot manually toggle this device because a schedule is currently running.\n\nPlease disable the schedule first.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EnergyTheme.primaryCyan),
            onPressed: () {
              Navigator.pop(ctx);
              _showScheduleDialog(context, name, key, currentData);
            },
            child: const Text("Manage Schedule", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 3. Schedule Editor
  void _showScheduleDialog(BuildContext context, String title, String key, Map currentData) {
    bool active = (int.tryParse(currentData["active"].toString()) ?? 0) == 1;
    TimeOfDay initialStart;
    TimeOfDay initialStop;

    // Load existing time or default to current time
    if (!active) {
      final now = TimeOfDay.now();
      initialStart = now;
      initialStop = now.replacing(hour: now.hour + 1); // Default to 1 hour later
    } else {
      initialStart = TimeOfDay(
          hour: int.tryParse(currentData["startHour"].toString()) ?? 18,
          minute: int.tryParse(currentData["startMin"].toString()) ?? 0
      );
      initialStop = TimeOfDay(
          hour: int.tryParse(currentData["stopHour"].toString()) ?? 6,
          minute: int.tryParse(currentData["stopMin"].toString()) ?? 0
      );
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Schedule for $title", style: const TextStyle(fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text(active ? "Enabled" : "Disabled", style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.green : Colors.grey)),
                    value: active,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => active = val),
                  ),
                  const SizedBox(height: 20),

                  ListTile(
                    leading: const Icon(Icons.wb_sunny_outlined, color: Colors.orange),
                    title: const Text("Turn ON"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: Text(initialStart.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: initialStart);
                      if (t != null) setState(() => initialStart = t);
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.nights_stay_outlined, color: Colors.teal),
                    title: const Text("Turn OFF"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: Text(initialStop.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: initialStop);
                      if (t != null) setState(() => initialStop = t);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    Map<String, int> updates = {
                      "$key/active": active ? 1 : 0,
                      "$key/startHour": initialStart.hour,
                      "$key/startMin": initialStart.minute,
                      "$key/stopHour": initialStop.hour,
                      "$key/stopMin": initialStop.minute,
                    };
                    dbRef.update(updates);
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                )
              ],
            );
          },
        );
      },
    );
  }
}