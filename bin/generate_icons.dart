import 'package:flutter/material.dart';
import '../lib/utils/icon_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IconGenerator.generateIcons();
  print('Icônes générées avec succès !');
}
