import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ToastNotification {
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: AppDurations.medium,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.success,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon ??
                        (backgroundColor == AppColors.error
                            ? Icons.error
                            : Icons.check_circle),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle,
    );
  }

  static void showError(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info,
    );
  }
}
