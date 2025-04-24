import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;

class IconGenerator {
  static Future<void> generateIcons() async {
    // Créer le widget de l'icône
    final iconWidget = Container(
      width: 1024,
      height: 1024,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue,
            Colors.blue.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(240),
      ),
      child: const Center(
        child: Text(
          'CE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 400,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    // Convertir le widget en image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(1024, 1024);
    
    final renderObject = iconWidget.createRenderObject(null);
    renderObject.paint(canvas, Offset.zero);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // Sauvegarder l'image
    final baseIconPath = 'assets/app_icon.png';
    await File(baseIconPath).writeAsBytes(buffer);

    // Générer les différentes tailles d'icônes
    final iconSizes = {
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };

    for (final entry in iconSizes.entries) {
      final targetSize = entry.value;
      final resizedImage = await _resizeImage(image, targetSize);
      final targetPath = path.join(
        'ios',
        'Runner',
        'Assets.xcassets',
        'AppIcon.appiconset',
        entry.key,
      );
      
      await File(targetPath).parent.create(recursive: true);
      await File(targetPath).writeAsBytes(resizedImage);
    }

    // Générer les images de lancement
    final launchSizes = {
      'LaunchImage.png': 512,
      'LaunchImage@2x.png': 1024,
      'LaunchImage@3x.png': 1536,
    };

    for (final entry in launchSizes.entries) {
      final targetSize = entry.value;
      final resizedImage = await _resizeImage(image, targetSize);
      final targetPath = path.join(
        'ios',
        'Runner',
        'Assets.xcassets',
        'LaunchImage.imageset',
        entry.key,
      );
      
      await File(targetPath).parent.create(recursive: true);
      await File(targetPath).writeAsBytes(resizedImage);
    }
  }

  static Future<Uint8List> _resizeImage(ui.Image image, int targetSize) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
      paint,
    );

    final resizedPicture = recorder.endRecording();
    final resizedImage = await resizedPicture.toImage(targetSize, targetSize);
    final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
