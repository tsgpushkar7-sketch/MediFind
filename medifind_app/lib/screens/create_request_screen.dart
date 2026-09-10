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

  const CreateRequestScreen({
    super.key,
    required this.category,
  });

  @override
  State<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState
    extends State<CreateRequestScreen> {
  final TextEditingController itemController =
      TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  File? selectedImage;

  static const Color primary = Color(0xFF16B8B0);
  static const Color primaryDark = Color(0xFF087F82);
  static const Color background = Color(0xFFF5F9FA);
  static const Color textDark = Color(0xFF173042);
  static const Color textLight = Color(0xFF71828D);

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

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
        ),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData =
          await response.stream.bytesToString();

      final jsonData = jsonDecode(responseData);

      return jsonData['secure_url'];
    } else {
      return null;
    }
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        errorMessage = 'Please enable location services';
      });
      return null;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

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
        errorMessage =
            'Location permission permanently denied. Enable it in settings.';
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
      imageUrl =
          await uploadImageToCloudinary(selectedImage!);
    }

    final position = await getCurrentLocation();

    if (position == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final customerId =
        prefs.getString('userId');

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

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        8,
        10,
        16,
        18,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: textDark,
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Request',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Find ${widget.category.toLowerCase()} near you',
                  style: const TextStyle(
                    color: textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  primary,
                  primaryDark,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF087F82),
            Color(0xFF16B8B0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.16),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Request category',
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.75),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget inputSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you need?',
          style: TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Enter the medicine or item you are looking for.',
          style: TextStyle(
            color: textLight,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2ECEE),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: itemController,
            textCapitalization:
                TextCapitalization.sentences,
            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration:
                const InputDecoration(
              hintText: 'e.g. Dolo 650',
              hintStyle: TextStyle(
                color: textLight,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: primary,
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget imageSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Add a photo',
          style: TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Optional — a photo can help pharmacies identify the item.',
          style: TextStyle(
            color: textLight,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 12),

        if (selectedImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(20),
                child: Image.file(
                  selectedImage!,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedImage = null;
                    });
                  },
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 125,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color: primary.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color:
                          primary.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: primaryDark,
                      size: 23,
                    ),
                  ),

                  const SizedBox(height: 9),

                  const Text(
                    'Add medicine photo',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  const Text(
                    'Tap to choose from gallery',
                    style: TextStyle(
                      color: textLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (selectedImage != null)
          Padding(
            padding:
                const EdgeInsets.only(top: 10),
            child: GestureDetector(
              onTap: pickImage,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.edit_rounded,
                    color: primaryDark,
                    size: 16,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Change photo',
                    style: TextStyle(
                      color: primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget locationInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F8),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: primary.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: primaryDark,
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Your location',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'We use your current location to find nearby pharmacies.',
                  style: TextStyle(
                    color: textLight,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget errorBox() {
    if (errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            isLoading ? null : handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          disabledBackgroundColor:
              primaryDark.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 23,
                width: 23,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Send Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  25,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    categoryCard(),

                    const SizedBox(height: 25),

                    inputSection(),

                    const SizedBox(height: 25),

                    imageSection(),

                    const SizedBox(height: 22),

                    locationInfo(),

                    const SizedBox(height: 16),

                    errorBox(),

                    if (errorMessage != null)
                      const SizedBox(height: 12),

                    submitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}