import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hibuz_billing/add_product.dart';
import 'package:http/http.dart' as http;
import 'showbill.dart';
import 'myaccount.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List products = [];
  bool isLoading = true;
  bool isCreatingBill = false;
  Map<String, int> cart = {};

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchProducts();
  }


  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    final token = await storage.read(key: "token");
try{
    final response = await http.get(
      Uri.parse("https://billing-system-y42h.onrender.com/api/retail/product"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is Map && decoded["data"] is List) {
          setState(() {
            products = List.from(decoded["data"]);
            isLoading = false;
          });

        } else {
          throw Exception("Invalid data format");
        }
      } else {
        throw Exception("Status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fetch error: $e")),
      );
    }
  }

  Future<void> deleteProduct(String productId) async {
    final token = await storage.read(key: "token");

    try {
      final response = await http.delete(
        Uri.parse(
          "https://billing-system-y42h.onrender.com/api/retail/product/$productId",
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Deleted")),
        );

        //  Refresh list after delete
        fetchProducts();
      } else {
        throw Exception(data["message"] ?? "Delete failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void increaseQty(String productId) {
    setState(() {
      cart[productId] = (cart[productId] ?? 0) + 1;
    });
  }

  void decreaseQty(String productId) {
    setState(() {
      final current = cart[productId] ?? 0;
      if (current <= 1) {
        cart.remove(productId);
      } else {
        cart[productId] = current - 1;
      }
    });
  }

  int get totalItems => cart.values.fold(0, (a, b) => a + b);

  double get totalPrice {
    double total = 0;
    for (final product in products) {
      final qty = cart[product['_id']] ?? 0;
      total += qty * (product['price'] as num).toDouble();
    }
    return total;
  }

  Future<void> createBill() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one product")),
      );
      return;
    }

    setState(() => isCreatingBill = true);

    final token = await storage.read(key: "token");

    final payload = {
      "items": cart.entries
          .map((e) =>
      {
        "productId": e.key,
        "qty": e.value,
      })
          .toList()
    };

    try {
      final postRes = await http.post(
        Uri.parse(
            "https://billing-system-y42h.onrender.com/api/retail/bill/add-products/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );

      final postData = json.decode(postRes.body);

      if (postRes.statusCode != 200 && postRes.statusCode != 201) {
        throw Exception(postData["message"] ?? "Create bill failed");
      }

      final billId = postData["billId"];
      final getRes = await http.get(
        Uri.parse(
            "https://billing-system-y42h.onrender.com/api/retail/bill/get-bill/$billId"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      final getData = json.decode(getRes.body);

      if (getRes.statusCode != 200) {
        throw Exception("Fetch bill failed");
      }

      setState(() => isCreatingBill = false);

      setState(() => cart.clear());

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ShowBillPage(
                billId: billId,
                billData: getData["bill"],
              ),
        ),
      );
    } catch (e) {
      setState(() => isCreatingBill = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget _qtyBtn({
      required IconData icon,
      required Color color,
      VoidCallback? onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F4),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "My Billing App",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.add, color: Colors.black87),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductPage()),
            );
            await fetchProducts();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black87),
            onPressed: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyAccountPage()),
                ),
          ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
            padding: const EdgeInsets.only(
                top: 12, left: 14, right: 14, bottom: 100),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final item = products[index];
              final String productId = item['_id'];
              final int qty = cart[productId] ?? 0;
              final bool isSelected = qty > 0;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (cart.containsKey(productId)) {
                    setState(() {
                      cart.remove(productId); // deselect
                    });
                  } else {
                    increaseQty(productId); // first select
                  }
                },
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (_) =>
                        AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          title: const Text("Delete Product"),
                          content: const Text(
                              "Are you sure you want to delete this product?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                deleteProduct(productId);
                              },
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                        border: Border.all(
                          color: isSelected
                              ? Colors.black87
                              : Colors.black.withOpacity(0.06),
                          width: isSelected ? 2 : 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Image.network(
                                item['images'].isNotEmpty
                                    ? item['images'][0]
                                    : "https://via.placeholder.com/150",
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                            child: Text(
                              item['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "₹${item['price']}",
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 4,),
                          if (isSelected) ...[
                            const SizedBox(height: 4),
                            Divider(
                              color: Colors.black,
                              thickness: 2,
                              height: 1,
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: isSelected
                                ? Row(
                              children: [
                                _qtyBtn(
                                  icon: Icons.remove,
                                  color: Colors.black87,
                                  onTap: () => decreaseQty(productId),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      "$qty",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                _qtyBtn(
                                  icon: Icons.add,
                                  color: Colors.black87,
                                  onTap: () => increaseQty(productId),
                                ),
                              ],
                            )
                                : SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => increaseQty(productId),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                child: const Text(
                                  "ADD",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // TOP RIGHT CHECKBOX
                    if (isSelected)
                    Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                    color: Colors.black87,
                    width: 2,
                    ),
                    ),
                    child: const Icon(
                    Icons.check,
                    color: Colors.red,
                    size: 14,
                    ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                      color: Colors.black.withOpacity(0.06)),
                ),
              ),
              child: totalItems == 0
                  ? Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Show Bill",
                  style: TextStyle(color: Colors.black45),
                ),
              )
                  : Row(
                children: [
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$totalItems item${totalItems > 1 ? 's' : ''}",
                        style: TextStyle(
                            fontSize: 12,
                            color:
                            Colors.black.withOpacity(0.5)),
                      ),
                      Text(
                        "₹${totalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap:
                    isCreatingBill ? null : createBill,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: isCreatingBill
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        "Show Bill",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}