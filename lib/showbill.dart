import 'package:flutter/material.dart';

class ShowBillPage extends StatelessWidget {
  const ShowBillPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Details"),
      ),
      body: const Center(
        child: Text(
          "No items in bill",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}