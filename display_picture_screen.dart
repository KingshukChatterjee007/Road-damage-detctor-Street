// ignore_for_file: constant_identifier_names, avoid_print, sized_box_for_whitespace, deprecated_member_use

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img_lib;
import './damage_analysis_screen.dart';
import './camera_screen.dart';

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final bool fromGallery;
  final CameraDescription camera;

  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    required this.camera,
    this.fromGallery = false,
  });

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  static const API_KEY = "7v3Mm2xjjrLD5eHkRiV2";
  static const MODEL_ENDPOINT = "road-damage-detection-apxtk/5";
  Map<String, dynamic>? detections;
  bool isLoading = true;
  String? error;

  double getConfidenceThreshold(Size imageSize, Size damageSize) {
    double damageArea = damageSize.width * damageSize.height;
    double imageArea = imageSize.width * imageSize.height;
    double ratio = damageArea / imageArea;

    if (ratio > 0.5) return 20; // Very close shots
    if (ratio < 0.1) return 5; // Far shots
    return 10; // Default
  }

  String getDisplayClass(String originalClass) {
    originalClass = originalClass.toLowerCase();
    if (originalClass.contains('longitudinal') ||
        originalClass.contains('aligator')) {
      return 'CRACKS';
    }
    return originalClass.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    analyzeImage();
  }

  Future<void> analyzeImage() async {
    if (!mounted) return;

    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      print('Image read successfully from: ${widget.imagePath}');
      print('Image size: ${bytes.length} bytes');

      final image = img_lib.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      final compressedImg = img_lib.copyResize(
        image,
        width: widget.fromGallery ? 620 : 640,
        height: widget.fromGallery
            ? 620
            : (640 * image.height / image.width).round(),
      );
      final compressedBytes = img_lib.encodeJpg(compressedImg, quality: 100);
      final base64Image = base64Encode(compressedBytes);

      final url = Uri.parse('https://detect.roboflow.com/$MODEL_ENDPOINT')
          .replace(queryParameters: {
        'api_key': API_KEY,
        'confidence': getConfidenceThreshold(
                Size(image.width.toDouble(), image.height.toDouble()),
                Size(compressedImg.width.toDouble(),
                    compressedImg.height.toDouble()))
            .toString(),
        'overlap': '20',
      });

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: base64Image,
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('API Response: $responseData');

        setState(() {
          detections = responseData;
          isLoading = false;
          error = null;
        });

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => DamageAnalysisScreen(
              detections: detections,
              imagePath: widget.imagePath,
              camera: widget.camera,
            ),
          ),
          (route) => false,
        );
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Add PopScope here
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (!didPop) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CameraScreen(camera: widget.camera),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: const Text('Damage Analysis',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CameraScreen(camera: widget.camera),
                ),
              );
            },
          ),
        ),
        body: isLoading
            ? Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Image.file(
                        File(widget.imagePath),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.75),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4285F4)),
                            ),
                            SizedBox(height: 16),
                            Text('Analyzing image...',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(widget.imagePath),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          if (detections != null)
                            CustomPaint(
                              painter: DamagePainter(
                                  detections!, MediaQuery.of(context).size),
                            ),
                        ],
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.signal_wifi_off,
                                  color: Color.fromARGB(255, 244, 66, 66),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Connection Error',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Please check your internet connection',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CameraScreen(camera: widget.camera),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFF4285F4)
                                        .withOpacity(0.2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Try Again',
                                    style: TextStyle(
                                      color: Color(0xFF4285F4),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (detections != null &&
                        detections!['predictions'] != null)
                      const SizedBox(),
                  ],
                ),
              ),
      ),
    );
  }
}
