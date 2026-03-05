import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// Screen where users can file a missed‑pickup report.
class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final TextEditingController _notesController = TextEditingController();
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint("Error opening camera: $e");
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F3),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sanitrax Support',
            style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text('Report a Pickup Issue',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF4A5D4A),
                )),
            const SizedBox(height: 10),
            const Text(
              'Provide details about the missed pickup to help the Sanitrax team resolve it quickly.',
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: const Color(0xFF5B6B5B),
                borderRadius: BorderRadius.circular(40),
                image: _capturedImage != null
                    ? DecorationImage(
                        image: FileImage(_capturedImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: Column(
                children: [
                  if (_capturedImage == null) ...[
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 20),
                    const Text('Upload Photo',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Take a clear photo of the\nuncollected bins',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                  ] else ...[
                    const SizedBox(height: 80),
                  ],
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _openCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 15),
                      elevation: 0,
                    ),
                    child: Text(_capturedImage == null
                        ? 'Open Camera'
                        : 'Retake Photo',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),
            _buildReadOnlyField(
                'CURRENT LOCATION',
                '842 Urban Heights, Sector 4, NY',
                Icons.location_on),
            const SizedBox(height: 20),

            const Text('ADDITIONAL NOTES',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A5D4A)),
                decoration: InputDecoration(
                  hintText:
                      'e.g. Bins were placed out by 6 AM, but were skipped...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  contentPadding: const EdgeInsets.all(15),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFFF0F4F0),
                        child: Icon(Icons.check_circle,
                            color: Color(0xFF4A5D4A)),
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sanitrax Ticket',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4A5D4A))),
                          Text('STATUS: READY TO SUBMIT',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 15, left: 55),
                    child: Text(
                      'Once submitted, a Sanitrax agent will review your report within 24 hours.',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 11, height: 1.5),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),
            _buildSubmitButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return _PressableScale(
      onTap: () {
        if (_capturedImage == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Please take a photo first!')));
          return;
        }
        ScaffoldMessenger.of(context).
            showSnackBar(const SnackBar(content: Text('Sanitrax Report Submitted!')));
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF4A5D4A),
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: const Text('Submit Report',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF4A5D4A), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A5D4A),
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Reusable pressable animation used across multiple pages.
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
