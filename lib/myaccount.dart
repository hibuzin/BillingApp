import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hibuz_billing/login.dart';
import 'package:hibuz_billing/main.dart';
import 'package:hibuz_billing/sales.dart';

class MyAccountPage extends StatelessWidget {
  const MyAccountPage({super.key});

  final storage = const FlutterSecureStorage();

  Future<void> logout(BuildContext context) async {
    await storage.delete(key: "token");
    Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPage()));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await logout(context);
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text("My Account"),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const SizedBox(height: 24),

          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
              child: const Icon(Icons.person_outline, size: 30, color: Colors.black38),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              "My Account",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "Manage your workspace",
              style: textTheme.bodySmall?.copyWith(
                color: Colors.black38,
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 40),

          _sectionLabel("Operations"),
          const SizedBox(height: 8),
          _group([
            _row(
              context,
              label: "Sales",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>SalesPage()))
            ),
            _row(
              context,
              label: "Stock Check",
              onTap: () => Navigator.pushNamed(context, "/stock"),
            ),
          ]),

          const SizedBox(height: 24),

          _sectionLabel("Account"),
          const SizedBox(height: 8),
          _group([
            _row(
              context,
              icon: Icons.logout,
              label: "Log out",
              isDestructive: true,
              showChevron: false,
              onTap: () => _showLogoutDialog(context),
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        color: Colors.black38,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _group(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(height: 0, thickness: 0.5, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, {
        IconData? icon,
        required String label,
        required VoidCallback onTap,
        bool isDestructive = false,
        bool showChevron = true,
      }) {
    final color = isDestructive ? Colors.red.shade400 : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.07),
                    width: 0.5,
                  ),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: color),
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}