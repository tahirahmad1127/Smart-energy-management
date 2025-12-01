import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news_app/theme/energy_theme.dart';
import 'package:news_app/services/bill_calculator.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({Key? key}) : super(key: key);

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://esp32energymonitor-934bb-default-rtdb.firebaseio.com'
  ).ref('energyMonitor');
  String _selectedPeriod = 'Current Month';
  final List<String> _periods = ['Current Month', 'Last Month', 'Last 3 Months', 'All Time'];
  
  // Note: Using IESCO tariff calculator for consistent bill calculation
  
  // Monthly tracking keys
  static const String _lastMonthEnergyKey = 'lastMonthEnergyKWh';
  static const String _lastMonthStartKey = 'lastMonthStartTimestamp';
  static const String _currentMonthStartKey = 'currentMonthStartTimestamp';
  static const String _energyAtMonthStartKey = 'energyAtMonthStart';
  
  // Cached values
  double _lastMonthEnergy = 0.0;
  double _energyAtMonthStart = 0.0;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadMonthlyTracking();
  }

  Future<void> _loadMonthlyTracking() async {
    final prefs = await SharedPreferences.getInstance();
    _lastMonthEnergy = prefs.getDouble(_lastMonthEnergyKey) ?? 0.0;
    _energyAtMonthStart = prefs.getDouble(_energyAtMonthStartKey) ?? 0.0;
    
    // Check if we're in a new month
    DateTime now = DateTime.now();
    int lastStoredMonth = prefs.getInt(_currentMonthStartKey) ?? now.month;
    int lastStoredYear = prefs.getInt(_lastMonthStartKey) ?? now.year;
    
    if (now.month != lastStoredMonth || now.year != lastStoredYear) {
      // New month detected - update tracking
      _lastMonthEnergy = _energyAtMonthStart > 0 
          ? (prefs.getDouble('previousTotalEnergy') ?? 0.0) - _energyAtMonthStart
          : 0.0;
      
      await prefs.setDouble(_lastMonthEnergyKey, _lastMonthEnergy);
      await prefs.setDouble('previousTotalEnergy', _energyAtMonthStart);
      await prefs.setInt(_currentMonthStartKey, now.month);
      await prefs.setInt(_lastMonthStartKey, now.year);
      
      setState(() {
        _currentMonth = now.month;
        _currentYear = now.year;
      });
    }
  }

  Future<void> _updateMonthlyTracking(double currentTotalEnergy) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    int storedMonth = prefs.getInt(_currentMonthStartKey) ?? now.month;
    int storedYear = prefs.getInt(_lastMonthStartKey) ?? now.year;
    
    // If new month, save previous month's data
    if (now.month != storedMonth || now.year != storedYear) {
      double previousEnergyAtStart = prefs.getDouble(_energyAtMonthStartKey) ?? 0.0;
      if (previousEnergyAtStart > 0) {
        double lastMonthConsumption = currentTotalEnergy - previousEnergyAtStart;
        await prefs.setDouble(_lastMonthEnergyKey, lastMonthConsumption);
      }
      
      // Update for new month
      await prefs.setDouble(_energyAtMonthStartKey, currentTotalEnergy);
      await prefs.setInt(_currentMonthStartKey, now.month);
      await prefs.setInt(_lastMonthStartKey, now.year);
      
      setState(() {
        _energyAtMonthStart = currentTotalEnergy;
        _currentMonth = now.month;
        _currentYear = now.year;
        if (previousEnergyAtStart > 0) {
          _lastMonthEnergy = currentTotalEnergy - previousEnergyAtStart;
        }
      });
    } else {
      // Same month - just ensure energy at start is stored
      double storedEnergyAtStart = prefs.getDouble(_energyAtMonthStartKey) ?? 0.0;
      if (storedEnergyAtStart == 0) {
        await prefs.setDouble(_energyAtMonthStartKey, currentTotalEnergy);
        setState(() {
          _energyAtMonthStart = currentTotalEnergy;
        });
      }
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
          title: GestureDetector(
            onLongPress: () => _showTestDataDialog(context, isDark, cardColor, textColor),
            child: Text(
              "Energy Bill",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          actions: [
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              tooltip: 'Set Test Data',
              onPressed: () => _showTestDataDialog(context, isDark, cardColor, textColor),
            ),
          ],
        ),
        body: StreamBuilder<DatabaseEvent>(
          stream: _database.onValue,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: EnergyTheme.primaryCyan,
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: subTextColor),
                  const SizedBox(height: 16),
                  Text(
                    "Connecting to Device...",
                    style: TextStyle(color: subTextColor, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          Map data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          double totalEnergy = double.tryParse(data["totalEnergyKWh"]?.toString() ?? "0") ?? 0.0;
          double currentBill = double.tryParse(data["bill"]?.toString() ?? "0") ?? 0.0;
          double currentPower = double.tryParse(data["power"]?.toString() ?? "0") ?? 0.0;

          // Update monthly tracking (async - will update state on next rebuild)
          _updateMonthlyTracking(totalEnergy);
          
          // Calculate current month's consumption so far
          DateTime now = DateTime.now();
          DateTime firstOfCurrentMonth = DateTime(now.year, now.month, 1);
          DateTime firstOfNextMonth = now.month == 12
              ? DateTime(now.year + 1, 1, 1)
              : DateTime(now.year, now.month + 1, 1);

          int daysElapsed = now.difference(firstOfCurrentMonth).inDays + 1;
          int daysInMonth = firstOfNextMonth.difference(firstOfCurrentMonth).inDays;
          int daysRemaining = daysInMonth - daysElapsed;

          // Calculate current month's consumption so far
          // Use current values from state (may be 0 on first load, will update on next rebuild)
          double currentMonthEnergySoFar = _energyAtMonthStart > 0 
              ? (totalEnergy - _energyAtMonthStart).clamp(0.0, double.infinity)
              : 0.0;
          
          // Calculate average daily consumption from last month
          double lastMonthDailyAverage = _lastMonthEnergy > 0 
              ? _lastMonthEnergy / 30.0  // Approximate 30 days per month
              : 0.0;
          
          // If we have current month data, use it; otherwise use last month's average or current power
          double dailyAverage = 0.0;
          if (currentMonthEnergySoFar > 0 && daysElapsed > 0) {
            dailyAverage = currentMonthEnergySoFar / daysElapsed;
          } else if (lastMonthDailyAverage > 0) {
            dailyAverage = lastMonthDailyAverage;
          } else {
            // Fallback: If no historical data, use current power estimate
            // This allows the app to work even on first use
            dailyAverage = (currentPower / 1000.0) * 24.0;
            if (dailyAverage == 0) {
              // If power is also 0, use a reasonable default (e.g., 10 kWh/day average household)
              dailyAverage = 10.0;
            }
          }
          
          // Predict remaining energy for the month
          double predictedEnergyRemaining = dailyAverage * daysRemaining;
          
          // Total predicted energy for the month
          double predictedMonthlyEnergy = currentMonthEnergySoFar + predictedEnergyRemaining;
          
          // Predicted bill for the month using IESCO tariff structure
          double predictedMonthlyBill = BillCalculator.calculateIESCOBill(predictedMonthlyEnergy);
          
          // Calculate effective rate for display
          double effectiveRate = predictedMonthlyEnergy > 0 
              ? predictedMonthlyBill / predictedMonthlyEnergy 
              : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  _buildPeriodSelector(isDark, cardColor, textColor),
                  const SizedBox(height: 20),

                  // Current Bill Card
                  _buildCurrentBillCard(
                    isDark,
                    predictedMonthlyBill,
                    predictedMonthlyEnergy,
                    predictedMonthlyBill,
                    currentPower,
                  ),
                  const SizedBox(height: 20),

                  // Energy Consumption Overview
                  _buildEnergyOverviewCard(
                    isDark,
                    totalEnergy,
                    predictedMonthlyEnergy,
                    currentPower,
                    textColor,
                    subTextColor,
                    cardColor,
                  ),
                  const SizedBox(height: 20),

                  // Bill Breakdown
                  _buildBillBreakdownCard(
                    isDark,
                    effectiveRate,
                    predictedMonthlyEnergy,
                    predictedMonthlyBill,
                    textColor,
                    subTextColor,
                    cardColor,
                  ),
                  const SizedBox(height: 20),

                  // Predicted Bill (1st to 1st)
                  _buildPredictedBillCard(
                    isDark,
                    cardColor,
                    textColor,
                    subTextColor,
                    predictedMonthlyBill,
                    predictedMonthlyEnergy,
                    daysElapsed,
                    daysRemaining,
                    currentMonthEnergySoFar,
                    predictedEnergyRemaining,
                    effectiveRate,
                    firstOfNextMonth,
                    _lastMonthEnergy,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 18, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                isExpanded: true,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                dropdownColor: cardColor,
                items: _periods.map((period) {
                  return DropdownMenuItem<String>(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPeriod = value);
                  }
                },
                icon: Icon(Icons.arrow_drop_down, color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBillCard(
      bool isDark,
      double currentBill,
      double monthlyEnergy,
      double monthlyBill,
      double currentPower,
      ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
              : [EnergyTheme.primaryCyan, EnergyTheme.primaryCyan.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.blue.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Bill',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedPeriod,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'PKR ${monthlyBill.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 6),
              Text(
                '${monthlyEnergy.toStringAsFixed(2)} kWh consumed',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(
                'Current Load',
                '${(currentPower / 1000).toStringAsFixed(2)} kW',
                Colors.white.withOpacity(0.9),
              ),
              _buildMiniStat(
                'Est. Daily Cost',
                'PKR ${(monthlyBill / 30).toStringAsFixed(2)}',
                Colors.white.withOpacity(0.9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyOverviewCard(
      bool isDark,
      double totalEnergy,
      double monthlyEnergy,
      double currentPower,
      Color textColor,
      Color subTextColor,
      Color cardColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: EnergyTheme.primaryCyan, size: 24),
              const SizedBox(width: 12),
              Text(
                'Energy Overview',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnergyStatRow(
            'Total Energy Consumed',
            '${totalEnergy.toStringAsFixed(2)} kWh',
            Icons.flash_on,
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          const SizedBox(height: 16),
          _buildEnergyStatRow(
            'Monthly Average',
            '${monthlyEnergy.toStringAsFixed(2)} kWh',
            Icons.calendar_month,
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          const SizedBox(height: 16),
          _buildEnergyStatRow(
            'Current Load',
            '${(currentPower / 1000).toStringAsFixed(2)} kW',
            Icons.power,
            textColor,
            subTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyStatRow(
      String label,
      String value,
      IconData icon,
      Color textColor,
      Color subTextColor,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EnergyTheme.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: EnergyTheme.primaryCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: subTextColor,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillBreakdownCard(
      bool isDark,
      double unitPrice,
      double monthlyEnergy,
      double monthlyBill,
      Color textColor,
      Color subTextColor,
      Color cardColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: EnergyTheme.primaryCyan, size: 24),
              const SizedBox(width: 12),
              Text(
                'Bill Breakdown',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBreakdownRow(
            'Energy Consumption',
            '${monthlyEnergy.toStringAsFixed(2)} kWh',
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            'Unit Price',
            'PKR ${unitPrice.toStringAsFixed(2)}/kWh',
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'PKR ${monthlyBill.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  color: EnergyTheme.primaryCyan,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
      String label,
      String value,
      Color textColor,
      Color subTextColor,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: subTextColor,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictedBillCard(
      bool isDark,
      Color cardColor,
      Color textColor,
      Color subTextColor,
      double predictedMonthlyBill,
      double predictedMonthlyEnergy,
      int daysElapsed,
      int daysRemaining,
      double estimatedEnergySoFar,
      double predictedEnergyRemaining,
      double unitPrice,
      DateTime firstOfNextMonth,
      double lastMonthEnergy,
      ) {
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    final currentMonthName = monthNames[DateTime.now().month - 1];
    final nextMonthName = monthNames[firstOfNextMonth.month - 1];
    final currentYear = DateTime.now().year;
    final nextMonthYear = firstOfNextMonth.year;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: EnergyTheme.primaryCyan, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Predicted Bill (1st to 1st)',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currentMonthName 1 - $nextMonthName 1, $nextMonthYear',
            style: GoogleFonts.poppins(
              color: subTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Predicted Amount',
                    style: GoogleFonts.poppins(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${predictedMonthlyBill.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EnergyTheme.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: EnergyTheme.primaryCyan,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          const SizedBox(height: 16),
          // Show last month's data
          if (lastMonthEnergy > 0)
            _buildPredictionRow(
              'Last Month\'s Consumption',
              '${lastMonthEnergy.toStringAsFixed(2)} kWh',
              'Based on actual usage',
              textColor,
              subTextColor,
            ),
          if (lastMonthEnergy > 0) const SizedBox(height: 12),
          // Show message if no historical data
          if (lastMonthEnergy == 0)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: EnergyTheme.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: EnergyTheme.primaryCyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: EnergyTheme.primaryCyan, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No historical data yet. Prediction based on current usage. Tap the settings icon (⚙️) in the top right to set test data.',
                      style: GoogleFonts.poppins(
                        color: subTextColor,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (lastMonthEnergy == 0) const SizedBox(height: 12),
          _buildPredictionRow(
            'Energy Consumed (Est.)',
            '${estimatedEnergySoFar.toStringAsFixed(2)} kWh',
            '$daysElapsed days',
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          _buildPredictionRow(
            'Predicted Remaining',
            '${predictedEnergyRemaining.toStringAsFixed(2)} kWh',
            '$daysRemaining days',
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Predicted',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${predictedMonthlyEnergy.toStringAsFixed(2)} kWh',
                    style: GoogleFonts.poppins(
                      color: EnergyTheme.primaryCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@ PKR ${unitPrice.toStringAsFixed(0)}/kWh',
                    style: GoogleFonts.poppins(
                      color: subTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(
      String label,
      String value,
      String days,
      Color textColor,
      Color subTextColor,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: subTextColor,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          days,
          style: GoogleFonts.poppins(
            color: subTextColor,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
    ),
    Text(
    value,
    style: GoogleFonts.poppins(
    color: textColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    ),
    ),
    ],
    );
    }

  // Test Data Dialog - For testing bill predictions without waiting a month
  void _showTestDataDialog(BuildContext context, bool isDark, Color cardColor, Color textColor) {
    TextEditingController lastMonthController = TextEditingController(
      text: _lastMonthEnergy > 0 ? _lastMonthEnergy.toStringAsFixed(2) : ''
    );
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            'Set Test Data',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter last month\'s consumption (kWh) for testing:',
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastMonthController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: textColor),
                  onChanged: (value) {
                    setDialogState(() {}); // Trigger rebuild to show estimated bill
                  },
                  decoration: InputDecoration(
                    labelText: 'Last Month Energy (kWh)',
                    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: EnergyTheme.primaryCyan),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: EnergyTheme.primaryCyan, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    double? testValue = double.tryParse(lastMonthController.text);
                    double estimatedBill = 0.0;
                    if (testValue != null && testValue > 0) {
                      estimatedBill = BillCalculator.calculateIESCOBill(testValue);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (testValue != null && testValue > 0)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: EnergyTheme.primaryCyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: EnergyTheme.primaryCyan, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Estimated bill: PKR ${estimatedBill.toStringAsFixed(2)} (using IESCO tariff)',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (testValue != null && testValue > 0) const SizedBox(height: 8),
                        Text(
                          'Note: This will simulate last month\'s data for bill prediction testing.',
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: textColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                double? testValue = double.tryParse(lastMonthController.text);
                if (testValue != null && testValue >= 0) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble(_lastMonthEnergyKey, testValue);
                  setState(() {
                    _lastMonthEnergy = testValue;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test data set: ${testValue.toStringAsFixed(2)} kWh'),
                      backgroundColor: EnergyTheme.primaryCyan,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EnergyTheme.primaryCyan,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(_lastMonthEnergyKey);
                await prefs.remove(_energyAtMonthStartKey);
                await prefs.remove(_currentMonthStartKey);
                await prefs.remove(_lastMonthStartKey);
                setState(() {
                  _lastMonthEnergy = 0.0;
                  _energyAtMonthStart = 0.0;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test data cleared'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}