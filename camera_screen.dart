// ignore_for_file: use_build_context_synchronously, constant_identifier_names, avoid_print
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import './display_picture_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();
  bool _isFlashOn = false;
  String _selectedButton = "StreetSense"; // Add this line
  bool _isMoreAppsPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _isFlashOn = false;
  }

  void _initializeCamera() {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      // Ensure flash is off when camera initializes
      if (mounted) {
        _controller.setFlashMode(FlashMode.off);
      }
    });
  }

  @override
  void dispose() {
    if (_isFlashOn) {
      _controller.setFlashMode(FlashMode.off);
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openGallery(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        await Navigator.pushAndRemoveUntil(
          // Changed from push to pushAndRemoveUntil
          context,
          MaterialPageRoute(
            builder: (context) => DisplayPictureScreen(
              imagePath: image.path,
              fromGallery: true,
              camera: widget.camera,
            ),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _takePicture(BuildContext context) async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      if (!mounted) return;

      await _controller.setFlashMode(FlashMode.off);
      setState(() {
        _isFlashOn = false;
      });

      if (!mounted) return;

      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
            imagePath: image.path,
            fromGallery: false,
            camera: widget.camera,
          ),
        ),
        (route) => false, // Removes all previous routes
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _showExitDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFF4285F4),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Exit App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Do you want to exit the app?',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (_isFlashOn) {
                          await _controller.setFlashMode(FlashMode.off);
                        }
                        SystemNavigator.pop();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF4285F4).withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (bool didPop) async {
        if (!didPop) {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Stack(
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => _showExitDialog(context),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isFlashOn = !_isFlashOn;
                                  _controller.setFlashMode(
                                    _isFlashOn
                                        ? FlashMode.torch
                                        : FlashMode.off,
                                  );
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Text(
                      'StreetSense',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2.0),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _openGallery(context),
                          child: Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.photo_library, size: 24),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          height: 64,
                          child: GestureDetector(
                            onTap: () => _takePicture(context),
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt, size: 28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomButton(Icons.delete_outline, "WasteSense"),
                      _buildBottomButton(Icons.add_road, "StreetSense"),
                      _buildBottomButton(Icons.grid_view, "More Apps"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, String label) {
    bool isMoreApps = label == "More Apps";
    bool isMoreAppsPressed = isMoreApps && _isMoreAppsPressed;

    return GestureDetector(
      onTapDown: (_) {
        if (isMoreApps) {
          setState(() => _isMoreAppsPressed = true);
        }
      },
      onTapUp: (_) {
        if (isMoreApps) {
          setState(() => _isMoreAppsPressed = false);
        }
      },
      onTapCancel: () {
        if (isMoreApps) {
          setState(() => _isMoreAppsPressed = false);
        }
      },
      onTap: () {
        if (!isMoreApps) {
          setState(() => _selectedButton = label);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: !isMoreApps && label == _selectedButton || isMoreAppsPressed
              ? const Color(0xFF4285F4).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon,
                color:
                    !isMoreApps && label == _selectedButton || isMoreAppsPressed
                        ? const Color(0xFF4285F4)
                        : Colors.white,
                size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    !isMoreApps && label == _selectedButton || isMoreAppsPressed
                        ? const Color(0xFF4285F4)
                        : Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
