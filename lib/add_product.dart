import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final storage = const FlutterSecureStorage();

  File? image;
  bool isLoading = false;

  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
      });
    }
  }

  Future<void> addProduct() async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select image")),
      );
      return;
    }

    setState(() => isLoading = true);

    //  GET TOKEN FROM STORAGE
    final token = await storage.read(key: "token");

    if (token == null) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login again")),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("https://billing-system-y42h.onrender.com/api/retail/product"),
    );

    // ADD AUTH HEADER
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = nameController.text;
    request.fields['price'] = priceController.text;
    request.fields['stock'] = stockController.text;

    request.files.add(
      await http.MultipartFile.fromPath('images', image!.path),
    );

    var response = await request.send();
    var resBody = await response.stream.bytesToString();

    dynamic data;
    try {
      data = jsonDecode(resBody);
    } catch (e) {
      data = {};
    }

    setState(() => isLoading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Added ")),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stock"),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: pickImage,
                child: const Text("Select Image"),
              ),

              const SizedBox(height: 10),

              image != null
                  ? Image.file(image!, height: 120)
                  : const Text("No image selected"),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: isLoading ? null : addProduct,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add Product"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}