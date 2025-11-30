import 'package:flutter/material.dart';
import 'package:news_app/theme/energy_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> faqs = const [
    {
      "q": "How do I add a new device?",
      "a": "Go to the Dashboard screen and tap the '+' icon in the bottom right corner. Follow the pairing instructions to connect your ESP32 device."
    },
    {
      "q": "Why is my device showing 'Offline'?",
      "a": "Check if your ESP32 is powered on and connected to WiFi. Also, ensure your phone has an active internet connection."
    },
    {
      "q": "Can I control devices when I'm not home?",
      "a": "Yes! Voltify uses cloud synchronization. As long as your home WiFi is active and your phone has data, you can control devices from anywhere."
    },
    {
      "q": "How does the Schedule feature work?",
      "a": "You can set a Start Time and Stop Time. The device will automatically turn ON at the start time and OFF at the stop time. Note: The manual switch is disabled during active schedule hours."
    },
    {
      "q": "My electricity bill calculation looks wrong.",
      "a": "Go to Settings and ensure you have entered the correct 'Unit Price' (Rs/kWh) for your region. The app calculates the bill based on this rate."
    },
    {
      "q": "How do I reset my password?",
      "a": "If you are logged out, use the 'Forgot Password' link on the login screen. If you are logged in, go to Profile > Change Password."
    },
    {
      "q": "What happens if the WiFi goes down?",
      "a": "Your physical switches (relays) will stay in their last state. However, the app will not update until the connection is restored."
    },
    {
      "q": "Can I share access with my family?",
      "a": "Currently, you must share your login credentials. Multi-user support with different permissions is coming in a future update."
    },
    {
      "q": "Is my data secure?",
      "a": "Yes, all communication between the app and your devices is encrypted using Google Firebase security protocols."
    },
    {
      "q": "How do I contact support?",
      "a": "You can email us at support@voltify.com or call our helpline at +92-300-1234567 between 9 AM and 5 PM."
    },
  ];

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
            "Help & Support",
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
        body: Column(
          children: [
            // Header Image/Icon
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.support_agent, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text("Frequently Asked Questions", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),

            // FAQ List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            )
                          ],
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                            title: Text(
                              faqs[index]["q"]!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            leading: Icon(Icons.help_outline, color: EnergyTheme.primaryCyan),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Text(
                                  faqs[index]["a"]!,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}