import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileAvatar extends StatefulWidget {
  final String? imageUrl;
  final double radius;
  final String userName;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    required this.userName,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      debugPrint('📥 Fetching profile image: ${widget.imageUrl}');
      final response = await http.get(Uri.parse(widget.imageUrl!));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('❌ Failed to load image. Status: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching image bytes: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.white,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty || _hasError) {
      return Text(
        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
        style: TextStyle(
          color: const Color(0xFF2196F3),
          fontSize: widget.radius * 0.9, // Responsive font size
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (_isLoading) {
      return SizedBox(
        width: widget.radius,
        height: widget.radius,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF2196F3),
        ),
      );
    }

    if (_imageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _imageBytes!,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
        ),
      );
    }

    // Fallback
    return Text(
      widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
      style: TextStyle(
        color: const Color(0xFF2196F3),
        fontSize: widget.radius * 0.9,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
