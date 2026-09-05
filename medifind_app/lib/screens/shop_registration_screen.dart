import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ShopRegistrationScreen extends StatefulWidget {
  final VoidCallback onRegistered;

  const ShopRegistrationScreen({super.key, required this.onRegistered});

  @override
  State<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends State<ShopRegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String selectedCategory = 'medical';
  bool isLoading = false;
  String? errorMessage;

  Future<void> handleRegister() async {
    if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        errorMessage = 'Please enable location services';
        isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition();

    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getString('userId');

    final result = await ApiService.registerShop(
      ownerId!,
      nameController.text.trim(),
      selectedCategory,
      addressController.text.trim(),
      position.longitude,
      position.latitude,
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      widget.onRegistered();
    } else {
      setState(() {
        errorMessage = result['error'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Your Shop')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Shop Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: selectedCategory,
              items: const [
                DropdownMenuItem(value: 'medical', child: Text('Medical')),
                DropdownMenuItem(value: 'grocery', child: Text('Grocery')),
                DropdownMenuItem(value: 'hardware', child: Text('Hardware')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: handleRegister,
                    child: const Text('Register Shop'),
                  ),
            const SizedBox(height: 12),
            const Text(
              'Your shop will need approval before it appears to customers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}