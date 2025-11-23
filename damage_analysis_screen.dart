// ignore_for_file: unnecessary_string_interpolations, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'camera_screen.dart'; // Import the CameraScreen class
import 'package:camera/camera.dart';

class DamageAnalysisScreen extends StatelessWidget {
  static const List<String> excludedClasses = [
    'white line blur',
    'bump',
    'cross walk blur',
    'white line',
    'wheel marks'
  ];

  final Map<String, dynamic>? detections;
  final String imagePath;
  final CameraDescription camera;

  const DamageAnalysisScreen({
    required this.camera,
    required this.detections,
    required this.imagePath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (!didPop) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CameraScreen(camera: camera),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: const Text('Analysis Results',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CameraScreen(camera: camera),
                ),
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildImageWithDetections(context),
              if (detections != null) _buildAnalysisResults(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithDetections(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(imagePath), fit: BoxFit.cover),
          if (detections != null)
            CustomPaint(
              painter: DamagePainter(detections!, MediaQuery.of(context).size),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults(BuildContext context) {
    if (detections == null ||
        detections!['predictions'] == null ||
        detections!['predictions'].isEmpty ||
        detections!['predictions']
            .where((pred) => !excludedClasses
                .contains(pred['class'].toString().toLowerCase()))
            .isEmpty) {
      return Padding(
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
                  Icons.warning_amber_rounded,
                  color: Color.fromARGB(255, 244, 66, 66),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Damage Detected',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Please try capturing the image again',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => CameraScreen(camera: camera),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4).withOpacity(0.2),
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
      );
    }
    final predictions = detections!['predictions'] as List;
    final validPredictions = predictions
        .where((pred) =>
            !excludedClasses.contains(pred['class'].toString().toLowerCase()))
        .toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Damage Detection Results',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDamageOverview(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildMetrics(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Damage Distribution',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDamageTypeMeters(validPredictions, context),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const ContactForm(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  double calculateTotalDamage() {
    if (detections == null || detections!['predictions'] == null) return 0.0;

    var validPredictions = detections!['predictions']
        .where((pred) =>
            !excludedClasses.contains(pred['class'].toString().toLowerCase()))
        .toList();

    if (validPredictions.isEmpty) return 0.0;

    double totalDamageScore = 0.0;
    double imageArea = (detections!['image']['width'] as num).toDouble() *
        (detections!['image']['height'] as num).toDouble();

    // Track maximum confidence and counts
    double maxPotholeConfidence = 0.0;
    double maxCrackConfidence = 0.0;
    int potholeCount = 0;
    int crackCount = 0;
    double totalArea = 0.0;

    for (var pred in validPredictions) {
      String className = pred['class'].toString().toLowerCase();
      double confidence = (pred['confidence'] as num).toDouble();
      double width = (pred['width'] as num).toDouble();
      double height = (pred['height'] as num).toDouble();
      double area = width * height;
      double areaRatio = (area / imageArea).clamp(0.0, 1.0);
      totalArea += areaRatio;

      if (className.contains('pothole')) {
        potholeCount++;
        maxPotholeConfidence = max(maxPotholeConfidence, confidence);
        // Base damage calculation for potholes
        double potholeDamage = confidence * areaRatio * 2.0;
        // Additional scaling based on confidence
        if (confidence > 0.7) {
          potholeDamage *= 1.3;
        }
        totalDamageScore += potholeDamage;
      } else if (className.contains('longitudinal') ||
          className.contains('aligator')) {
        crackCount++;
        maxCrackConfidence = max(maxCrackConfidence, confidence);
        totalDamageScore += confidence * areaRatio * 1.5;
      }
    }

    // Calculate base damage
    double averageConfidence = (maxPotholeConfidence * potholeCount +
            maxCrackConfidence * crackCount) /
        (potholeCount + crackCount);

    // Scale based on damage characteristics
    double severityScale = 1.0;

    // Adjust for multiple instances
    if (potholeCount + crackCount > 1) {
      severityScale *= 1.2;
    }

    // Adjust for high confidence
    if (maxPotholeConfidence > 0.7 || maxCrackConfidence > 0.7) {
      severityScale *= 1.2;
    }

    // Factor in total affected area more conservatively
    double areaImpact = totalArea > 0.3 ? 1.3 : (totalArea > 0.15 ? 1.15 : 1.0);

    // Calculate final damage percentage more conservatively
    double finalDamage =
        (totalDamageScore * averageConfidence * severityScale * areaImpact * 70)
            .clamp(0.0, 100.0);

    // For single damage cases, ensure the pie value doesn't exceed the confidence
    if (potholeCount + crackCount == 1) {
      finalDamage =
          min(finalDamage, max(maxPotholeConfidence, maxCrackConfidence) * 100);
    }

    return finalDamage;
  }

  String? validateDetections(List predictions) {
    if (predictions.isEmpty) return 'No damage detected';
    if (predictions.any((p) => p['confidence'] == null)) {
      return 'Invalid confidence values';
    }
    return null;
  }

  Color getConsistentColor(double value) {
    if (value >= 70) return const Color(0xFFFF3B30); // Red
    if (value >= 40) return const Color(0xFFFFCC00); // Orange
    return const Color.fromARGB(255, 53, 207, 79); // Green
  }

  Widget _buildDamageOverview() {
    if (detections == null || detections!['predictions'] == null) {
      return const SizedBox.shrink();
    }

    double totalDamage = calculateTotalDamage();

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: 100,
                  color: getConsistentColor(totalDamage).withOpacity(0.2),
                  showTitle: false,
                  radius: 60,
                ),
              ],
              centerSpaceRadius: 40,
              sectionsSpace: 0,
            ),
          ),
          Text(
            '${totalDamage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: getConsistentColor(totalDamage),
            ),
          ),
        ],
      ),
    );
  }

  double calculateRiskAssessment(double hazardLevel, double accidentRisk) {
    // Base the assessment more heavily on the hazard level
    double hazardWeight = 0.7;
    double accidentWeight = 0.3;

    // Calculate base risk
    double baseRisk =
        (hazardLevel * hazardWeight) + (accidentRisk * accidentWeight);

    // Scale up if both metrics are high but maintain logical relationships
    if (hazardLevel > 60 && accidentRisk > 60) {
      baseRisk *= 1.2;
    }

    // Ensure final assessment makes sense relative to inputs
    double finalRisk = min(baseRisk, max(hazardLevel, accidentRisk));

    return finalRisk.clamp(0.0, 100.0);
  }

  Widget _buildMetrics() {
    if (detections == null || detections!['predictions'] == null) {
      return const SizedBox.shrink();
    }

    final predictions = detections!['predictions'] as List;
    final validPredictions = predictions
        .where((pred) =>
            !excludedClasses.contains(pred['class'].toString().toLowerCase()))
        .toList();

    double hazardLevel = _calculateHazardLevel(validPredictions);
    double accidentRisk = _calculateAccidentRisk(validPredictions);
    double riskAssessment = calculateRiskAssessment(hazardLevel, accidentRisk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Predictions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildMetricItem(MetricData(
                title: 'Hazard Level',
                value: hazardLevel.round(),
                icon: Icons.warning_amber_rounded,
                color: getConsistentColor(hazardLevel),
                status: _getMetricStatus(hazardLevel),
              )),
              _buildMetricItem(MetricData(
                title: 'Accident Risk',
                value: accidentRisk.round(),
                icon: Icons.car_crash,
                color: getConsistentColor(accidentRisk),
                status: _getMetricStatus(accidentRisk),
              )),
              _buildMetricItem(MetricData(
                title: 'Risk Assessment',
                value: riskAssessment.round(),
                icon: Icons.shield,
                color: getConsistentColor(riskAssessment),
                status: _getMetricStatus(riskAssessment),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(MetricData metric) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: metric.color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF2A2A2A),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(metric.icon, color: metric.color),
              const SizedBox(width: 12),
              Text(
                metric.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: metric.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${metric.value}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateHazardLevel(List<dynamic> predictions) {
    if (predictions.isEmpty) return 0;

    double hazardScore = 0;
    double maxConfidence = 0;
    double imageArea = (detections!['image']['width'] as num).toDouble() *
        (detections!['image']['height'] as num).toDouble();

    for (var pred in predictions) {
      double confidence = (pred['confidence'] as num).toDouble();
      double area = (pred['width'] as num).toDouble() *
          (pred['height'] as num).toDouble();
      double areaRatio = (area / imageArea).clamp(0.0, 1.0);
      String className = pred['class'].toString().toLowerCase();

      // Weighted scoring based on damage type and size
      double severityWeight = className.contains('pothole')
          ? 3.0 // Increased weight for potholes
          : (confidence > 0.6 ? 2.0 : 1.5);

      // Additional weight for larger damages
      double sizeWeight = areaRatio > 0.1 ? 1.5 : 1.0;

      hazardScore +=
          (confidence * areaRatio * severityWeight * sizeWeight * 100);
      maxConfidence = max(maxConfidence, confidence);
    }

    // Scale based on number of detections
    double countScale = predictions.length > 2 ? 1.3 : 1.0;

    return (hazardScore * maxConfidence * countScale).clamp(0.0, 100.0);
  }

  double _calculateAccidentRisk(List<dynamic> predictions) {
    if (predictions.isEmpty) return 0;

    double hazardLevel = _calculateHazardLevel(predictions);
    double riskScore = 0;
    int potholesCount = 0;
    int cracksCount = 0;
    double imageArea = (detections!['image']['width'] as num).toDouble() *
        (detections!['image']['height'] as num).toDouble();
    double totalDangerousArea = 0.0;

    for (var pred in predictions) {
      String className = pred['class'].toString().toLowerCase();
      double confidence = (pred['confidence'] as num).toDouble();
      double width = (pred['width'] as num).toDouble();
      double height = (pred['height'] as num).toDouble();
      double area = width * height;
      double areaRatio = (area / imageArea).clamp(0.0, 1.0);

      if (className.contains('pothole')) {
        potholesCount++;
        // Potholes are more dangerous for accidents
        double potholeSeverity = confidence * areaRatio * 2.0;
        riskScore += potholeSeverity;
        totalDangerousArea += areaRatio;
      } else {
        cracksCount++;
        // Cracks contribute less to accident risk
        riskScore += confidence * areaRatio;
        totalDangerousArea +=
            areaRatio * 0.5; // Cracks contribute less to dangerous area
      }
    }

    // Factor in the total dangerous area coverage
    double areaImpact = 1.0;
    if (totalDangerousArea > 0.3) {
      areaImpact = 1.4; // Large coverage of dangerous area
    } else if (totalDangerousArea > 0.15) {
      areaImpact = 1.2; // Moderate coverage of dangerous area
    }

    // Base risk calculation including area impact
    double baseRisk = min(riskScore * 50 * areaImpact, hazardLevel * 1.2);

    // Additional risk factors
    if (potholesCount > 0 && cracksCount > 0) {
      baseRisk *= 1.15;
    }

    if (potholesCount > 1 || cracksCount > 1) {
      baseRisk *= 1.1;
    }

    // Final risk calculations
    double finalRisk = min(baseRisk, 100.0);

    if (finalRisk > hazardLevel * 1.5) {
      finalRisk = hazardLevel * 1.5;
    }

    if (hazardLevel < 10) {
      finalRisk = min(finalRisk, 15.0);
    }

    return finalRisk.clamp(0.0, 100.0);
  }

  String _getMetricStatus(double value) {
    if (value >= 70) return 'High';
    if (value >= 40) return 'Medium';
    return 'Low';
  }

  // ignore: unused_element
  List<Widget> _buildDetectionResults() {
    return detections!['predictions']
        .where((pred) =>
            !excludedClasses.contains(pred['class'].toString().toLowerCase()))
        .map<Widget>((pred) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF2A2A2A),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFF4285F4)),
                const SizedBox(width: 12),
                Text(
                  _getDisplayClass(pred['class'].toString()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(pred['confidence'] * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getDisplayClass(String originalClass) {
    originalClass = originalClass.toLowerCase();
    if (originalClass.contains('longitudinal') ||
        originalClass.contains('aligator')) {
      return 'CRACKS';
    }
    return originalClass.toUpperCase();
  }

  Widget _buildDamageTypeMeters(
      List<dynamic> predictions, BuildContext context) {
    // Filter and count potholes and cracks
    int potholesCount = 0;
    double maxPotholeConfidence = 0.0;
    int cracksCount = 0;
    double maxCrackConfidence = 0.0;

    for (var pred in predictions) {
      String className = pred['class'].toString().toLowerCase();
      double confidence = (pred['confidence'] as num).toDouble() * 100;

      if (className.contains('pothole')) {
        potholesCount++;
        if (confidence > maxPotholeConfidence) {
          maxPotholeConfidence = confidence;
        }
      } else if (className.contains('longitudinal') ||
          className.contains('aligator')) {
        cracksCount++;
        if (confidence > maxCrackConfidence) {
          maxCrackConfidence = confidence;
        }
      }
    }

    return Column(
      children: [
        _buildDamageMeter(
          'Potholes',
          maxPotholeConfidence,
          potholesCount,
          const Color(0xFF006400),
          context,
        ),
        const SizedBox(height: 16),
        _buildDamageMeter(
          'Cracks',
          maxCrackConfidence,
          cracksCount,
          const Color(0xFFFF0000),
          context,
        ),
      ],
    );
  }

  Widget _buildDamageMeter(String title, double percentage, int count,
      Color color, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title: $count',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: (percentage / 100) * constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class ContactForm extends StatefulWidget {
  const ContactForm({super.key});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Get the values
      String name = _nameController.text;
      String contactInfo = _contactController.text;

      // Print or process the values (you can modify this part to handle the data as needed)
      debugPrint('Name: $name');
      debugPrint('Contact Info: $contactInfo');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you $name, your information has been saved'),
            backgroundColor: const Color(0xFF4285F4),
          ),
        );
      }

      // Clear the form
      _nameController.clear();
      _contactController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF4285F4), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                  return 'Only alphabets are allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email/Phone Number',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF4285F4), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email or phone number';
                }
                bool isEmail =
                    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
                bool isPhone = RegExp(r'^[0-9]{10}$').hasMatch(value);

                if (!isEmail && !isPhone) {
                  return 'Enter valid email or 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: _submitForm,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4).withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DamagePainter extends CustomPainter {
  final Map<String, dynamic> detections;
  final Size screenSize;

  DamagePainter(this.detections, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (detections['predictions'] == null) return;

    for (var pred in detections['predictions'] as List) {
      double width = (pred['width'] as num).toDouble();
      double height = (pred['height'] as num).toDouble();
      double imageWidth = (detections['image']['width'] as num).toDouble();
      double imageHeight = (detections['image']['height'] as num).toDouble();

      if ((width * height) / (imageWidth * imageHeight) > 0.7) {
        continue; // Skip if detection is too large
      }

      String className = pred['class'].toString().toLowerCase();
      if (DamageAnalysisScreen.excludedClasses.contains(className)) {
        continue;
      }

      // Set colors and rename labels
      Color boxColor;
      String displayLabel = pred['class'];

      if (className.contains('pothole')) {
        boxColor = const Color(0xFF006400);
        displayLabel = "Potholes";
      } else if (className.contains('longitudinal')) {
        boxColor = const Color(0xFFFF0000);
        displayLabel = "Cracks";
      } else if (className.contains('aligator')) {
        boxColor = const Color(0xFFFF0000);
        displayLabel = "Cracks";
      } else {
        boxColor = const Color(0xFFFFFF00);
      }

      try {
        double x = (pred['x'] as num).toDouble();
        double y = (pred['y'] as num).toDouble();
        double w = (pred['width'] as num).toDouble();
        double h = (pred['height'] as num).toDouble();

        // Adjust coordinates to keep boxes within bounds
        if (x < 0) x = 0;
        if (y < 0) y = 0;
        if (x + w > detections['image']['width']) {
          w = detections['image']['width'] - x;
        }
        if (y + h > detections['image']['height']) {
          h = detections['image']['height'] - y;
        }

        x = (x - w / 2) * size.width / detections['image']['width'];
        y = (y - h / 2) * size.height / detections['image']['height'];
        w = w * size.width / detections['image']['width'];
        h = h * size.height / detections['image']['height'];

        final rect = Rect.fromLTWH(x, y, w, h);
        canvas.drawRect(
            rect,
            Paint()
              ..color = boxColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0);

        final labelText =
            '$displayLabel: ${(pred['confidence'] * 100).toInt()}%';
        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.drawRect(
          Rect.fromLTWH(x, y - 25, textPainter.width + 10, 25),
          Paint()..color = boxColor,
        );

        textPainter.paint(canvas, Offset(x + 5, y - 22));
      } catch (e) {
        debugPrint('Error drawing box: $e');
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MetricData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String status;

  MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.status,
  });
}
