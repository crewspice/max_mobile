import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';
import '../config/device_config.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentUserId; // driver/user "initial"

  const EditProfileScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _pickedFile;
  bool _uploading = false;
  int _cacheBust = 0;
  bool _hasCustomImage = false;

  double get _avatarDiameter => DeviceConfig.isIpad ? 260 : 160;

  @override
  void initState() {
    super.initState();
    _refreshHasCustomImage();
  }

  Future<void> _refreshHasCustomImage() async {
    final hasImage = await ApiService().hasProfilePicture(widget.currentUserId);
    if (!mounted) return;
    setState(() => _hasCustomImage = hasImage);
  }

  Future<File?> _pickImage({bool camera = true}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile != null) return File(pickedFile.path);
    return null;
  }

  // Auto center-crop to square, then downscale — no manual crop UI, matches
  // how the rest of the app handles photos (capture then compress, no editing step).
  Future<File> _cropAndCompress(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return file;

    final int size =
        decoded.width < decoded.height ? decoded.width : decoded.height;
    final int offsetX = (decoded.width - size) ~/ 2;
    final int offsetY = (decoded.height - size) ~/ 2;

    final img.Image cropped = img.copyCrop(
      decoded,
      x: offsetX,
      y: offsetY,
      width: size,
      height: size,
    );

    final img.Image resized = img.copyResize(cropped, width: 500, height: 500);

    return File(file.path)
      ..writeAsBytesSync(img.encodeJpg(resized, quality: 85));
  }

  Future<void> _selectAndUpload(BuildContext context, {bool camera = true}) async {
    final file = await _pickImage(camera: camera);
    if (file == null) return;

    final prepared = await _cropAndCompress(file);

    setState(() {
      _pickedFile = prepared;
      _uploading = true;
    });

    final api = ApiService();
    final success =
        await api.uploadProfilePicture(widget.currentUserId, prepared);

    // Old cached copies (same URL, different bytes) would otherwise linger.
    imageCache.clear();
    imageCache.clearLiveImages();

    if (!context.mounted) return;

    setState(() {
      _uploading = false;
      if (success) _hasCustomImage = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profile picture updated!' : 'Upload failed',
        ),
      ),
    );
  }

  Future<void> _resetToDefault(BuildContext context) async {
    setState(() => _uploading = true);

    final api = ApiService();
    final success = await api.resetProfilePicture(widget.currentUserId);

    // Old cached copies (same URL, different bytes) would otherwise linger.
    imageCache.clear();
    imageCache.clearLiveImages();

    if (!context.mounted) return;

    setState(() {
      _pickedFile = null;
      _uploading = false;
      _cacheBust++;
      if (success) _hasCustomImage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Reset to default' : 'Reset failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.mainBackground,
        iconTheme: const IconThemeData(color: AppColors.yellow),
        title: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppColors.yellow,
                AppColors.green,
                AppColors.red,
              ],
            ).createShader(bounds);
          },
          child: Text(
            DeviceConfig.isIphone ? "Profile Pic" : "Profile Picture",
            style: GoogleFonts.permanentMarker(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pickedFile != null
                ? ClipOval(
                    child: Image.file(
                      _pickedFile!,
                      width: _avatarDiameter,
                      height: _avatarDiameter,
                      fit: BoxFit.cover,
                    ),
                  )
                : UserAvatar(
                    initials: widget.currentUserId,
                    radius: _avatarDiameter / 2,
                    color: AppColors.yellow,
                    cacheBust: _cacheBust,
                  ),
            const SizedBox(height: 12),
            if (_uploading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: CircularProgressIndicator(color: AppColors.yellow),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.main,
                  foregroundColor: AppColors.yellow,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _uploading
                    ? null
                    : () => _selectAndUpload(context, camera: true),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Take Photo"),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: DeviceConfig.isIpad ? 220 * 1.7 : 220,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.main,
                  foregroundColor: AppColors.yellow,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _uploading
                    ? null
                    : () => _selectAndUpload(context, camera: false),
                icon: const Icon(Icons.photo_library),
                label: const Text("Choose from Gallery"),
              ),
            ),
            if (_hasCustomImage) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 220,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.yellow,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed:
                      _uploading ? null : () => _resetToDefault(context),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text("Reset"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
