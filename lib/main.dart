import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hibuz_billing/add_product.dart';
import 'package:hibuz_billing/login.dart';
import 'package:http/http.dart' as http;
import 'showbill.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// ✅ CHANGED: Stateless → Stateful
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List products = [];
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // ✅ API CALL
  Future<void> fetchProducts() async {
    final response = await http.get(
      Uri.parse("https://billing-system-y42h.onrender.com/api/retail/product"),
    );

    if (response.statusCode == 200) {
      setState(() {
        products = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Billing App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
            padding: const EdgeInsets.only(top: 50, left: 10, right: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final item = products[index];

              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        item['images'].isNotEmpty
                            ? item['images'][0]
                            : "https://via.placeholder.com/150",
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text("₹${item['price']}"),
                    ),
                  ],
                ),
              );
            },
          ),

          // ✅ YOUR EXISTING ADD BUTTON (UNCHANGED)
          Positioned(
            top: 10,
            right: 5,
            child: IconButton(
              icon: const Icon(Icons.add, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductPage(),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> const ShowBillPage()),);
              },
              icon: const Icon(Icons.receipt),
              label: const Text("Show Bill"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}