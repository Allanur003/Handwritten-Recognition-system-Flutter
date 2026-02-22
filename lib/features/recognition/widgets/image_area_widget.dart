import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:handwritten_recognition/core/localization/app_localizations.dart';
import 'package:handwritten_recognition/features/recognition/recognition_provider.dart';

class ImageAreaWidget extends StatelessWidget {
  const ImageAreaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecognitionProvider>();
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => provider.pickImage(ImageSource.gallery),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: provider.selectedImage != null
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.4),
            width: 2,
          ),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        child: provider.selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  provider.selectedImage!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.draw_outlined,
                    size: 72,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.get('tapToSelect'),
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
