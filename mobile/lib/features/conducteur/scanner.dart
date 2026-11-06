import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme.dart';

/// Lit le QR code d'embarquement présenté par le passager et renvoie son contenu à l'écran précédent.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final _controleur = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _lu = false;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _detecte(BarcodeCapture capture) {
    final valeur = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (valeur == null || _lu) return;
    _lu = true;
    Navigator.pop(context, valeur);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scanner le code')),
        backgroundColor: Colors.black,
        body: Stack(children: [
          MobileScanner(
            controller: _controleur,
            onDetect: _detecte,
            // Au-dessus du cadre de visée, pour rester lisible.
            errorBuilder: (_, erreur) => Align(
              alignment: const Alignment(0, -0.75),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  erreur.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'L\'accès à la caméra a été refusé. Autorisez-le dans les réglages, ou saisissez le code à 6 chiffres.'
                      : 'Caméra indisponible. Saisissez le code à 6 chiffres du passager.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Couleurs.orange, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text('Placez le QR code du passager dans le cadre.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}
