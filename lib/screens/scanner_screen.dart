import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../services/gemini_service.dart';
import 'remedy_screen.dart';
import '../widgets/app_background.dart';
import '../widgets/ai_fab.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  Uint8List? _selectedImageBytes;
  bool _isAnalyzing = false;

  String _selectedCrop = 'Paddy';
  final List<String> _crops = ['Paddy', 'Tea', 'Tomato'];

  final ImagePicker _picker = ImagePicker();

  // ───────── PICK IMAGE ─────────
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  // ───────── ANALYZE IMAGE ─────────
  Future<void> _analyzeImage() async {
    if (_selectedImageBytes == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await GeminiService.analyzeCropImageBytes(
        _selectedImageBytes!,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RemedyScreen(result: result)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // ───────── UI ─────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text('AI Disease Scanner'),
        backgroundColor: AppColors.primary,
      ),

      floatingActionButton: const AiFab(),

      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCropSelector(),
                const SizedBox(height: 20),
                _buildImageArea(),
                const SizedBox(height: 20),
                _buildTips(),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────── CROP SELECTOR ─────────
  Widget _buildCropSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Crop Type",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children:
              _crops.map((crop) {
                final isSelected = _selectedCrop == crop;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCrop = crop),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primary
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        crop,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  // ───────── IMAGE AREA ─────────
  Widget _buildImageArea() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child:
            _selectedImageBytes != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                )
                : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50),
                      SizedBox(height: 10),
                      Text("Tap to select crop image"),
                    ],
                  ),
                ),
      ),
    );
  }

  // ───────── TIPS ─────────
  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tips:", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text("• Use good lighting"),
          Text("• Focus on affected area"),
          Text("• Keep camera steady"),
        ],
      ),
    );
  }

  // ───────── BUTTONS ─────────
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo),
                label: const Text("Gallery"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Camera"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _selectedImageBytes == null || _isAnalyzing
                    ? null
                    : _analyzeImage,
            child:
                _isAnalyzing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Analyze Disease"),
          ),
        ),
      ],
    );
  }
}
