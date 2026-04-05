import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/nutrition/data/open_food_facts_client.dart';

// ---------------------------------------------------------------------------
// Barcode Scanner Screen
// ---------------------------------------------------------------------------

/// Screen that activates the device camera to scan barcodes/QR codes and
/// looks up the corresponding food item in the Open Food Facts API.
///
/// On successful lookup, pops with a [FoodItemDto] as the navigation result.
/// On unknown product, shows a snack bar and resumes scanning.
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState
    extends ConsumerState<BarcodeScannerScreen> {
  late final MobileScannerController _controller;

  bool _scanning = true;
  bool _loading = false;
  String? _lastBarcode;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Detection handler
  // ---------------------------------------------------------------------------

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (!_scanning || _loading) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;
    if (barcode == _lastBarcode) return;

    setState(() {
      _scanning = false;
      _loading = true;
      _lastBarcode = barcode;
    });

    try {
      final client = ref.read(openFoodFactsClientProvider);
      final dto = await client.searchByBarcode(barcode);

      if (!mounted) return;

      if (dto != null) {
        Navigator.of(context).pop(dto);
      } else {
        _showNotFoundSnack(barcode);
        setState(() {
          _scanning = true;
          _loading = false;
          _lastBarcode = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      _showErrorSnack();
      setState(() {
        _scanning = true;
        _loading = false;
        _lastBarcode = null;
      });
    }
  }

  void _showNotFoundSnack(String barcode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Producto no encontrado: $barcode'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Reintentar',
          onPressed: () => setState(() {
            _scanning = true;
            _lastBarcode = null;
          }),
        ),
      ),
    );
  }

  void _showErrorSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Error al buscar el producto. Verifica tu conexion.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear codigo de barras'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Semantics(
            label: 'Alternar linterna',
            button: true,
            child: IconButton(
              key: const ValueKey('barcode_torch_button'),
              icon: const Icon(Icons.flash_on_outlined),
              tooltip: 'Linterna',
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
          Semantics(
            label: 'Cambiar camara',
            button: true,
            child: IconButton(
              key: const ValueKey('barcode_flip_button'),
              icon: const Icon(Icons.flip_camera_ios_outlined),
              tooltip: 'Voltear camara',
              onPressed: () => _controller.switchCamera(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            key: const ValueKey('barcode_scanner_view'),
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // Scan overlay with bracket corners
          _ScanOverlay(scanning: _scanning && !_loading),

          // Loading indicator
          if (_loading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.nutrition),
                      SizedBox(height: 16),
                      Text('Buscando producto...'),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom instruction banner
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: const Text(
                'Apunta la camara al codigo de barras del producto',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scan overlay
// ---------------------------------------------------------------------------

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({required this.scanning});

  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerPainter(scanning: scanning),
      child: const SizedBox.expand(),
    );
  }
}

class _ScannerPainter extends CustomPainter {
  const _ScannerPainter({required this.scanning});

  final bool scanning;

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black54;
    final scanW = size.width * 0.75;
    final scanH = scanW * 0.55;
    final left = (size.width - scanW) / 2;
    final top = (size.height - scanH) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanW, scanH);

    // Dimmed areas
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), dimPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, top + scanH, size.width, size.height - top - scanH),
      dimPaint,
    );
    canvas.drawRect(Rect.fromLTWH(0, top, left, scanH), dimPaint);
    canvas.drawRect(
      Rect.fromLTWH(left + scanW, top, size.width - left - scanW, scanH),
      dimPaint,
    );

    // Corner brackets
    final bracketPaint = Paint()
      ..color = scanning ? AppColors.nutrition : Colors.grey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLen = 24.0;

    canvas.drawLine(scanRect.topLeft,
        scanRect.topLeft.translate(cornerLen, 0), bracketPaint);
    canvas.drawLine(scanRect.topLeft,
        scanRect.topLeft.translate(0, cornerLen), bracketPaint);

    canvas.drawLine(scanRect.topRight,
        scanRect.topRight.translate(-cornerLen, 0), bracketPaint);
    canvas.drawLine(scanRect.topRight,
        scanRect.topRight.translate(0, cornerLen), bracketPaint);

    canvas.drawLine(scanRect.bottomLeft,
        scanRect.bottomLeft.translate(cornerLen, 0), bracketPaint);
    canvas.drawLine(scanRect.bottomLeft,
        scanRect.bottomLeft.translate(0, -cornerLen), bracketPaint);

    canvas.drawLine(scanRect.bottomRight,
        scanRect.bottomRight.translate(-cornerLen, 0), bracketPaint);
    canvas.drawLine(scanRect.bottomRight,
        scanRect.bottomRight.translate(0, -cornerLen), bracketPaint);
  }

  @override
  bool shouldRepaint(_ScannerPainter oldDelegate) =>
      oldDelegate.scanning != scanning;
}
