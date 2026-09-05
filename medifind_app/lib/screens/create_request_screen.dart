import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'request_status_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  final String category;

  const CreateRequestScreen({super.key, required this.category});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController itemController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  File? selectedImage;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImageToCloudinary(File image) async {
    const cloudName = 'vrdew7cm';
    const uploadPreset = 'fsdnm0pn';

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      return jsonData['secure_url'];
    } else {
      return null;
    }
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        errorMessage = 'Please enable location services';
      });
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          errorMessage = 'Location permission denied';
        });
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        errorMessage = 'Location permission permanently denied. Enable it in settings.';
      });
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> handleSubmit() async {
    if (itemController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Please enter what you need';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String? imageUrl;
    if (selectedImage != null) {
      imageUrl = await uploadImageToCloudinary(selectedImage!);
    }

    final position = await getCurrentLocation();

    if (position == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('userId');

    final result = await ApiService.createRequest(
      customerId!,
      widget.category,
      itemController.text.trim(),
      position.longitude,
      position.latitude,
      imageUrl,
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RequestStatusScreen(
              requestId: result['data']['_id'],
              itemText: itemController.text.trim(),
            ),
          ),
        );
      }
    } else {
      setState(() {
        errorMessage = result['error'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request ${widget.category}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What do you need?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: itemController,
              decoration: const InputDecoration(
                hintText: 'e.g. Dolo 650',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(selectedImage!, height: 150),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(selectedImage == null ? 'Add Photo (optional)' : 'Change Photo'),
            ),
            const SizedBox(height: 20),
            
            // Image Picker UI Component
            if (selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  selectedImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.image),
              label: Text(selectedImage == null ? 'Attach Image' : 'Change Image'),
            ),
            const SizedBox(height: 20),

            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: handleSubmit,
                      child: const Text('Send Request'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}