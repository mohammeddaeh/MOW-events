import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:photo_view/photo_view.dart';

class ProfileImage extends StatelessWidget {
  final String? text;
  final String? imageUrl;
  final VoidCallback onChangeImage;

  const ProfileImage({
    super.key,
    this.imageUrl,
    required this.text,
    required this.onChangeImage,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onLongPress: hasImage
              ? () => _showFloatingImageDialog(imageUrl!)
              : null,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary,
                child: hasImage ? _userImage() : _logoImage(),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onChangeImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          text ?? '-',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _userImage() {
    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _logoImage(),
      ),
    );
  }

  Widget _logoImage() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: SvgPicture.asset(AppImages.logoAndName, fit: BoxFit.contain),
    );
  }

  void _showFloatingImageDialog(String imageUrl) {
    Get.dialog(
      GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          color: Colors.black.withOpacity(0.8),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 400,
                height: 500,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PhotoView(
                    imageProvider: NetworkImage(imageUrl),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
      barrierColor: Colors.transparent,
    );
  }
}
