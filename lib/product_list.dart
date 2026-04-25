import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List products = [];
  bool isLoading = true;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // ✅ GET PRODUCTS
  Future<void> fetchProducts() async {
    setState(() => isLoading = true);

    final token = await storage.read(key: "token");

    try {
      final res = await http.get(
        Uri.parse("https://billing-system-y42h.onrender.com/api/retail/product"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          products = data["products"];
        });
      } else {
        throw Exception(data["message"]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  // ✅ DELETE
  Future<void> deleteProduct(String id) async {
    final token = await storage.read(key: "token");

    try {
      final res = await http.delete(
        Uri.parse("https://billing-system-y42h.onrender.com/api/retail/product/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200) {
        fetchProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );
      } else {
        throw Exception(data["message"]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete error: $e")),
      );
    }
  }

  // ✅ UPDATE
  Future<void> updateProduct(String id, String name, String price, String stock) async {
    final token = await storage.read(key: "token");

    try {
      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("https://billing-system-y42h.onrender.com/api/retail/product/$id"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.fields["name"] = name;
      request.fields["price"] = price;
      request.fields["stock"] = stock;

      var res = await request.send();
      var body = await res.stream.bytesToString();
      var data = json.decode(body);

      if (res.statusCode == 200) {
        fetchProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );
      } else {
        throw Exception(data["message"]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update error: $e")),
      );
    }
  }

  void showEditDialog(Map item) {
    final name = TextEditingController(text: item["name"]);
    final price = TextEditingController(text: item["price"].toString());
    final stock = TextEditingController(text: item["stock"].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: price, decoration: const InputDecoration(labelText: "Price")),
            TextField(controller: stock, decoration: const InputDecoration(labelText: "Stock")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              updateProduct(item["_id"], name.text, price.text, stock.text);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Products")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, i) {
          final item = products[i];

          return ListTile(
            leading: Image.network(
              item["images"].isNotEmpty
                  ? item["images"][0]
                  : "https://via.placeholder.com/100",
              width: 50,
            ),
            title: Text(item["name"]),
            subtitle: Text("₹${item["price"]} | Stock: ${item["stock"]}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => showEditDialog(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deleteProduct(item["_id"]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}