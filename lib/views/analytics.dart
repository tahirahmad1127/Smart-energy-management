import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news_app/theme/energy_theme.dart';

// CRITICAL: Class defined outside widget
class DeviceConsumption {
  final String device;
  final double consumption;
  final Color color;
  final double percentage;

  DeviceConsumption(this.device, this.consumption, this.color, double totalConsumption)
      : percentage = totalConsumption > 0 ? (consumption / totalConsumption) * 100 : 0.0;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(home: EnergyStatisticsScreen()));
}

class EnergyStatisticsScreen extends StatefulWidget {
  const EnergyStatisticsScreen({super.key});

  @override
  State<EnergyStatisticsScreen> createState() => _EnergyStatisticsScreenState();
}

class _EnergyStatisticsScreenState extends State<EnergyStatisticsScreen> {
  final dbRef = FirebaseDatabase.instance.ref("energyMonitor");
  String _selectedPeriod = 'Daily'; // Daily, Weekly, Monthly
  Map<String, String> _savedNames = {};

  // Define a palette of colors to assign dynamically
  final List<Color> _colors = [
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFFE91E63), // Pink
    const Color(0xFFFF9800), // Orange
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFFFC107), // Amber
    const Color(0xFF795548), // Brown
  ];

  @override
  void initState() {
    super.initState();
    _loadDeviceNames();
  }

  // Load names from SharedPrefs (Same as your DevicesScreen)
  Future<void> _loadDeviceNames() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('deviceNames');
    if (jsonString != null) {
      Map<String, dynamic> storedNames = jsonDecode(jsonString);
      setState(() {
        storedNames.forEach((key, value) {
          _savedNames[key] = value.toString();
        });
      });
    }
  }

  // Helper to sort relay keys: relay, relay1, relay2...
  int _getRelayIndex(String key) {
    if (key == 'relay') return 0;
    return int.tryParse(key.replaceAll('relay', '')) ?? 999;
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
            'Energy Statistics',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        ),
        body: StreamBuilder(
          stream: dbRef.onValue,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: EnergyTheme.primaryCyan));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(child: Text("No Data Available", style: TextStyle(color: textColor)));
          }

          // 1. Parse Data
          Map data = {};
          try {
            data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          } catch (e) {
            return const Center(child: Text("Data Error"));
          }

          // 2. Get Metrics
          double totalLifeTimeEnergy = double.tryParse(data["totalEnergyKWh"].toString()) ?? 0.0;
          double currentPowerWatts = double.tryParse(data["power"].toString()) ?? 0.0;

          // 3. Dynamic Device Processing
          List<String> relayKeys = data.keys
              .where((k) => k.toString().startsWith("relay") && !k.toString().contains("schedule"))
              .cast<String>()
              .toList();
          relayKeys.sort((a, b) => _getRelayIndex(a).compareTo(_getRelayIndex(b)));

          // 4. Calculate Consumption Data
          List<DeviceConsumption> chartData = _generateChartData(relayKeys, data, currentPowerWatts);
          double maxConsumption = chartData.isNotEmpty
              ? chartData.map((d) => d.consumption).reduce(max)
              : 10.0;
          if (maxConsumption == 0) maxConsumption = 10;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Summary Cards (Projections based on Total) ---
                    Row(
                      children: [
                        // Since ESP32 only sends Total Lifetime, we estimate daily/weekly based on averages
                        // or just show the lifetime split. Here we show actual Lifetime.
                        Expanded(child: _buildSummaryCard('Current Load', '${(currentPowerWatts/1000).toStringAsFixed(2)} kW', EnergyTheme.amberGlow, isDark, cardColor, textColor, subTextColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSummaryCard('Total Energy', '${totalLifeTimeEnergy.toStringAsFixed(2)} kWh', EnergyTheme.primaryCyan, isDark, cardColor, textColor, subTextColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSummaryCard('Est. Bill', 'Rs ${data["bill"] ?? "0"}', EnergyTheme.electricBlue, isDark, cardColor, textColor, subTextColor)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // --- Filter Dropdown ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Device Load Distribution',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey[300]!),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            underline: const SizedBox(),
                            dropdownColor: cardColor,
                            style: TextStyle(color: textColor),
                            items: ['Daily', 'Weekly', 'Monthly'].map((String period) {
                              return DropdownMenuItem<String>(
                                value: period, 
                                child: Text(period, style: TextStyle(color: textColor)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedPeriod = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Bar Chart ---
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: chartData.isEmpty
                          ? Center(child: Text("No Active Devices", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)))
                          : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxConsumption * 1.2,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: isDark ? Colors.grey[900]! : Colors.grey[800]!,
                              tooltipRoundedRadius: 8,
                              tooltipPadding: const EdgeInsets.all(8),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final device = chartData[groupIndex];
                                return BarTooltipItem(
                                  '${device.device}\n${rod.toY.toStringAsFixed(1)} kWh\n(${device.percentage.toStringAsFixed(1)}%)',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: SizedBox(
                                        width: 50,
                                        child: Text(
                                          chartData[value.toInt()].device,
                                          style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.w600),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 40,
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide left numbers for cleaner look
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey[300]!, width: 1)),
                          ),
                          barGroups: chartData.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.consumption,
                                  color: entry.value.color,
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Legend ---
                    if (chartData.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: chartData.map((device) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(color: device.color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${device.device} (${device.percentage.toStringAsFixed(0)}%)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- LOGIC TO GENERATE DYNAMIC DATA ---
  List<DeviceConsumption> _generateChartData(List<String> relayKeys, Map data, double totalWatts) {
    List<DeviceConsumption> items = [];
    int activeCount = 0;
    List<String> activeKeys = [];

    // 1. Identify Active Devices (Value == 1)
    // Note: In your DB, 1 = ON, 0 = OFF (based on previous chat)
    for (String key in relayKeys) {
      if (data[key].toString() == '1') {
        activeCount++;
        activeKeys.add(key);
      }
    }

    if (activeCount == 0) return [];

    // 2. Logic: Since the hardware has only 1 sensor for ALL relays,
    // We visually distribute the Total Power equally among active devices.
    // If you had individual sensors, you would read them here.
    double estimatedPowerPerDevice = totalWatts / activeCount;

    // Scale based on period (Just for visualization)
    double multiplier = 1.0;
    if (_selectedPeriod == 'Weekly') multiplier = 7.0;
    if (_selectedPeriod == 'Monthly') multiplier = 30.0;

    // Convert Watts to kWh for the period (Hypothetical projection)
    // Formula: (Watts * 24h * Days) / 1000
    double projectedKWh = (estimatedPowerPerDevice * 24 * multiplier) / 1000;
    double totalProjected = (totalWatts * 24 * multiplier) / 1000;

    for (int i = 0; i < activeKeys.length; i++) {
      String key = activeKeys[i];

      // Get Name
      String defaultName = key == "relay" ? "Main Device" : "Device ${_getRelayIndex(key)}";
      String name = _savedNames[key] ?? defaultName;

      // Assign Color
      Color color = _colors[i % _colors.length];

      items.add(DeviceConsumption(name, projectedKWh, color, totalProjected));
    }

    return items;
  }

  Widget _buildSummaryCard(String title, String value, Color accentColor, bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), 
            blurRadius: 8, 
            offset: const Offset(0, 2)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor)),
        ],
      ),
    );
  }
}