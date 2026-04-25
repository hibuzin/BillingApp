import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TopProductsPage extends StatefulWidget {
  const TopProductsPage({super.key});

  @override
  State<TopProductsPage> createState() => _TopProductsPageState();
}

class _TopProductsPageState extends State<TopProductsPage> {
  List products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTopProducts();
  }

  final storage = FlutterSecureStorage();

  Future<void> fetchTopProducts() async {
    try {
      // 🔥 Get token from storage
      String? token = await storage.read(key: "token");

      final response = await http.get(
        Uri.parse(
          "https://billing-system-y42h.onrender.com/api/retail/bill/top-products?min=1",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ✅ IMPORTANT
        },
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          products = data["products"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          products = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Top sales Products"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(child: Text("No Top Products Found"))
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final item = products[index];

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),

              // 🔥 PRODUCT IMAGE
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item["image"],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported);
                  },
                ),
              ),

              // 🔥 NAME
              title: Text(
                item["name"],
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),

              // 🔥 SOLD COUNT
              subtitle: Text(
                "Sold: ${item["totalSold"]}",
                style: const TextStyle(color: Colors.grey),
              ),

              // 🔥 RIGHT SIDE ICON
              trailing: const Icon(Icons.trending_up,
                  color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}