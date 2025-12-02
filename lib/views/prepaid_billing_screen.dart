import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news_app/theme/energy_theme.dart';

class PrepaidBillingScreen extends StatefulWidget {
  const PrepaidBillingScreen({Key? key}) : super(key: key);

  @override
  State<PrepaidBillingScreen> createState() => _PrepaidBillingScreenState();
}

class _PrepaidBillingScreenState extends State<PrepaidBillingScreen> {
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://esp32energymonitor-934bb-default-rtdb.firebaseio.com'
  ).ref('energyMonitor');

  double _prepaidBalance = 0.0;
  double _currentBill = 0.0;
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  static const String _prepaidBalanceKey = 'prepaidBalance';

  @override
  void initState() {
    super.initState();
    _loadPrepaidBalance();
  }

  Future<void> _loadPrepaidBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prepaidBalance = prefs.getDouble(_prepaidBalanceKey) ?? 0.0;
    });
  }

  Future<void> _savePrepaidBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prepaidBalanceKey, balance);
    setState(() {
      _prepaidBalance = balance;
    });
  }

  Future<void> _addBalance(double amount) async {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 1));
    
    double newBalance = _prepaidBalance + amount;
    await _savePrepaidBalance(newBalance);
    
    setState(() => _isLoading = false);
    _amountController.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added PKR ${amount.toStringAsFixed(2)} to your account'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _usePrepaidBalance() async {
    if (_prepaidBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No prepaid balance available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentBill <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bill to pay'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    double amountToUse = _prepaidBalance >= _currentBill ? _currentBill : _prepaidBalance;
    double newBalance = _prepaidBalance - amountToUse;
    
    await _savePrepaidBalance(newBalance);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Used PKR ${amountToUse.toStringAsFixed(2)} from prepaid balance'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
            "Prepaid Billing",
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
        ),
        body: StreamBuilder<DatabaseEvent>(
          stream: _database.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
              Map data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
              _currentBill = double.tryParse(data["bill"]?.toString() ?? "0") ?? 0.0;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prepaid Balance Card
                  _buildBalanceCard(isDark, cardColor, textColor, subTextColor),
                  const SizedBox(height: 20),

                  // Current Bill Card
                  _buildCurrentBillCard(isDark, cardColor, textColor, subTextColor),
                  const SizedBox(height: 20),

                  // Add Balance Section
                  _buildAddBalanceSection(isDark, cardColor, textColor, subTextColor),
                  const SizedBox(height: 20),

                  // Use Balance Button
                  if (_prepaidBalance > 0 && _currentBill > 0)
                    _buildUseBalanceButton(isDark, textColor),
                  const SizedBox(height: 20),

                  // Banking Apps Section
                  _buildBankingAppsSection(isDark, cardColor, textColor, subTextColor),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(bool isDark, Color cardColor, Color textColor, Color subTextColor) {
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
                'Prepaid Balance',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'PKR ${_prepaidBalance.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Available for bill payment',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBillCard(bool isDark, Color cardColor, Color textColor, Color subTextColor) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Bill',
                style: GoogleFonts.poppins(
                  color: subTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PKR ${_currentBill.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            Icons.receipt_long,
            color: EnergyTheme.primaryCyan,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildAddBalanceSection(bool isDark, Color cardColor, Color textColor, Color subTextColor) {
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
              Icon(Icons.add_circle_outline, color: EnergyTheme.primaryCyan, size: 24),
              const SizedBox(width: 12),
              Text(
                'Add Balance',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Amount (PKR)',
              labelStyle: TextStyle(color: subTextColor),
              prefixIcon: Icon(Icons.attach_money, color: EnergyTheme.primaryCyan),
              filled: true,
              fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: EnergyTheme.primaryCyan, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                double? amount = double.tryParse(_amountController.text);
                if (amount != null) {
                  _addBalance(amount);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EnergyTheme.primaryCyan,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Add Balance',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUseBalanceButton(bool isDark, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _usePrepaidBalance,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Use Prepaid Balance to Pay Bill',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankingAppsSection(bool isDark, Color cardColor, Color textColor, Color subTextColor) {
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
              Icon(Icons.account_balance, color: EnergyTheme.primaryCyan, size: 24),
              const SizedBox(width: 12),
              Text(
                'Pay via Banking Apps',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select a banking app to add balance (Demo)',
            style: GoogleFonts.poppins(
              color: subTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          _buildBankingAppTile(
            'JazzCash',
            Icons.account_balance_wallet,
            const Color(0xFF00A859),
            isDark,
            cardColor,
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          _buildBankingAppTile(
            'EasyPaisa',
            Icons.mobile_friendly,
            const Color(0xFFE31837),
            isDark,
            cardColor,
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          _buildBankingAppTile(
            'UBL Omni',
            Icons.business,
            const Color(0xFF0066CC),
            isDark,
            cardColor,
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          _buildBankingAppTile(
            'HBL Konnect',
            Icons.phone_android,
            const Color(0xFFE31837),
            isDark,
            cardColor,
            textColor,
            subTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBankingAppTile(
    String name,
    IconData icon,
    Color iconColor,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBankingAppDialog(name, icon, iconColor, isDark, cardColor, textColor),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to pay via $name',
                      style: GoogleFonts.poppins(
                        color: subTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: subTextColor,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankingAppDialog(
    String appName,
    IconData icon,
    Color iconColor,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pay via $appName',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'DEMO MODE',
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is a demo banking interface.\nReal payment integration is not available.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: textColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enter Amount (PKR)',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.attach_money, color: EnergyTheme.primaryCyan),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: EnergyTheme.primaryCyan, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                        'In a real app, this would redirect to $appName for payment processing.',
                        style: GoogleFonts.poppins(
                          color: textColor.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
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
            onPressed: () {
              double? amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                _addBalance(amount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
            ),
            child: Text(
              'Proceed (Demo)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

