import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ucb_app/models/intervention.dart';
import 'package:ucb_app/models/refrigerateur.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/pages/dashboard/maps/intervention_execution_screen.dart';
import 'package:ucb_app/services/hive_service.dart';
import 'package:ucb_app/pages/dashboard/maps/refrigerateur_detail_screen.dart';

class QrScanInterventionScreen extends StatefulWidget {
  final Intervention intervention;
  
  const QrScanInterventionScreen({
    super.key,
    required this.intervention,
  });
  
  @override
  State<QrScanInterventionScreen> createState() => _QrScanInterventionScreenState();
}

class _QrScanInterventionScreenState extends State<QrScanInterventionScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String? _scannedQrCode;
  bool _isProcessing = false;
  bool _qrCodeDetected = false;
  Refrigerateur? _scannedRefrigerateur;
  bool _isExpected = false;
  
  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }
  
  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onQrCodeDetect(BarcodeCapture barcodeCapture) {
    if (_isProcessing || _qrCodeDetected) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final Barcode barcode = barcodes.first;
      final String? qrCode = barcode.rawValue;
      
      if (qrCode != null && qrCode.isNotEmpty && qrCode != _scannedQrCode) {
        setState(() {
          _isProcessing = true;
          _scannedQrCode = qrCode;
        });

        cameraController.stop();
        
        Future.delayed(const Duration(milliseconds: 500), () {
          _processQrCodeDetection(qrCode);
        });
      }
    }
  }

  void _processQrCodeDetection(String qrCode) async {
    try {
      _scannedRefrigerateur = HiveService.getRefrigerateurByQR(qrCode);
      
      if (_scannedRefrigerateur != null) {
        _isExpected = widget.intervention.refrigerateurIds.contains(_scannedRefrigerateur!.id);
      } else {
        _showError('Réfrigérateur non trouvé. Ce QR code n\'est pas dans la base.');
      }

      setState(() {
        _isProcessing = false;
        _qrCodeDetected = true;
      });
    } catch (e) {
      print('❌ Erreur processQrCodeDetection: $e');
      _showError('Erreur lors du traitement du QR code: $e');
      _resetScanner();
    }
  }

  void _commencerIntervention() {
    if (_scannedRefrigerateur == null) return;

    if (!_isExpected) {
      _showNotExpectedDialog();
      return;
    }

    // Démarrer l'exécution de l'intervention pour ce réfrigérateur
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterventionExecutionScreen(
          intervention: widget.intervention,
          refrigerateur: _scannedRefrigerateur!,
        ),
      ),
    ).then((value) {
      if (value == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showNotExpectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text('Réfrigérateur non prévu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ce réfrigérateur n\'est pas dans la liste prévue pour l\'intervention :',
              style: TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.intervention.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.intervention.description),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Veuillez scanner un réfrigérateur prévu pour cette intervention.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewRefrigerateurInfo() {
    if (_scannedRefrigerateur == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RefrigerateurDetailScreen(
          refrigerateur: _scannedRefrigerateur!,
        ),
      ),
    );
  }

  void _recommencerScanner() {
    _resetScanner();
  }

  void _resetScanner() {
    setState(() {
      _scannedQrCode = null;
      _qrCodeDetected = false;
      _scannedRefrigerateur = null;
      _isExpected = false;
      _isProcessing = false;
    });
    cameraController.start();
  }

  void _enterQrCodeManually() {
    final TextEditingController manualController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisir le QR code manuellement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: manualController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ex: QR001-2024-001',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _processQrCodeManuel(value);
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Scannez le QR code du réfrigérateur à maintenir',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = manualController.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context);
                _processQrCodeManuel(value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _processQrCodeManuel(String qrCode) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      _scannedRefrigerateur = HiveService.getRefrigerateurByQR(qrCode);
      
      if (_scannedRefrigerateur != null) {
        _isExpected = widget.intervention.refrigerateurIds.contains(_scannedRefrigerateur!.id);
      } else {
        _showError('QR code inconnu');
      }

      setState(() {
        _scannedQrCode = qrCode;
        _isProcessing = false;
        _qrCodeDetected = true;
      });
    } catch (e) {
      print('❌ Erreur processQrCodeManuel: $e');
      _showError('Erreur: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _toggleTorch() {
    cameraController.toggleTorch();
  }

  void _switchCamera() {
    cameraController.switchCamera();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

Widget _buildScannerOverlay() {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final frameSize = 250.0;
  final topMargin = (screenHeight - frameSize) / 2;
  final leftMargin = (screenWidth - frameSize) / 2;

  return Stack(
    children: [
      // Overlay sombre autour du cadre
      Container(
        color: Colors.black.withOpacity(0.4),
      ),

      // Fenêtre transparente au centre
      Positioned(
        top: topMargin,
        left: leftMargin,
        child: Container(
          width: frameSize,
          height: frameSize,
          decoration: BoxDecoration(
            border: Border.all(
              color: _qrCodeDetected 
                  ? (_scannedRefrigerateur != null ? Colors.green : Colors.red)
                  : AppTheme.primaryColor,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
        ),
      ),

      // Coins décoratifs - maintenant correctement alignés
      Positioned(
        top: topMargin,
        left: leftMargin,
        child: Container(
          width: frameSize,
          height: frameSize,
          child: CustomPaint(
            painter: ScannerCornersPainter(
              color: _qrCodeDetected 
                  ? (_scannedRefrigerateur != null ? Colors.green : Colors.red)
                  : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    ],
  );
}


  Widget _buildScannerCorners() {
    final cornerColor = _qrCodeDetected 
        ? (_scannedRefrigerateur != null ? Colors.green : Colors.red)
        : AppTheme.primaryColor;
    
    return Stack(
      children: [
        // Coin supérieur gauche
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 125,
          left: MediaQuery.of(context).size.width / 2 - 125,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: 6),
                left: BorderSide(color: cornerColor, width: 6),
              ),
            ),
          ),
        ),
        
        // Coin supérieur droit
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 125,
          left: MediaQuery.of(context).size.width / 2 + 85,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: 6),
                right: BorderSide(color: cornerColor, width: 6),
              ),
            ),
          ),
        ),
        
        // Coin inférieur gauche
        Positioned(
          top: MediaQuery.of(context).size.height / 2 + 85,
          left: MediaQuery.of(context).size.width / 2 - 125,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: 6),
                left: BorderSide(color: cornerColor, width: 6),
              ),
            ),
          ),
        ),
        
        // Coin inférieur droit
        Positioned(
          top: MediaQuery.of(context).size.height / 2 + 85,
          left: MediaQuery.of(context).size.width / 2 + 85,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: 6),
                right: BorderSide(color: cornerColor, width: 6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodeDetectedPanel() {
    final hasRefrigerateur = _scannedRefrigerateur != null;
    
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasRefrigerateur 
                  ? (_isExpected ? Icons.check_circle : Icons.warning)
                  : Icons.error,
              color: hasRefrigerateur 
                  ? (_isExpected ? Colors.green : Colors.orange)
                  : Colors.red,
              size: 64,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              hasRefrigerateur 
                  ? (_isExpected ? 'RÉFRIGÉRATEUR VALIDE' : 'RÉFRIGÉRATEUR NON PRÉVU')
                  : 'QR CODE INCONNU',
              style: TextStyle(
                color: hasRefrigerateur 
                    ? (_isExpected ? Colors.green : Colors.orange)
                    : Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code, color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _scannedQrCode!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (hasRefrigerateur)
              Column(
                children: [
                  // Statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_scannedRefrigerateur!.statut).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(_scannedRefrigerateur!.statut),
                      ),
                    ),
                    child: Text(
                      _scannedRefrigerateur!.statut,
                      style: TextStyle(
                        color: _getStatusColor(_scannedRefrigerateur!.statut),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Informations du réfrigérateur
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.greyLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _scannedRefrigerateur!.codeQR,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_scannedRefrigerateur!.marque} ${_scannedRefrigerateur!.modele}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_scannedRefrigerateur!.numeroSerie.isNotEmpty)
                          Text(
                            'Série: ${_scannedRefrigerateur!.numeroSerie}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Information d'intervention
                  if (!_isExpected)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Non prévu pour l\'intervention en cours',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            
            if (!hasRefrigerateur)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ce QR code n\'est associé à aucun réfrigérateur connu.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Boutons d'action
            if (hasRefrigerateur && _isExpected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _commencerIntervention,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'COMMENCER L\'INTERVENTION',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            
            if (hasRefrigerateur && !_isExpected)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _viewRefrigerateurInfo,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('VOIR LES DÉTAILS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _recommencerScanner,
                icon: const Icon(Icons.refresh),
                label: const Text('SCANNER UN AUTRE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Fonctionnel': return Colors.green;
      case 'En_panne': return Colors.red;
      case 'Maintenance': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildScannerInstructions() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Scanner le réfrigérateur',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intervention: ${widget.intervention.code}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.intervention.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            const Text(
              'Placez le QR code dans le cadre',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _toggleTorch,
            tooltip: 'Torche',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
            tooltip: 'Changer caméra',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner (seulement visible si pas de QR code détecté)
          if (!_qrCodeDetected)
            MobileScanner(
              controller: cameraController,
              onDetect: _onQrCodeDetect,
              fit: BoxFit.cover,
            ),

          // Overlay de guidage
          if (!_qrCodeDetected) _buildScannerOverlay(),

          // Instructions (seulement visible si pas de QR code détecté)
          if (!_qrCodeDetected && !_isProcessing)
            _buildScannerInstructions(),

          // Indicateur de traitement
          if (_isProcessing)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Vérification du QR code...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Panel QR code détecté
          if (_qrCodeDetected && _scannedQrCode != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildQrCodeDetectedPanel(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: !_qrCodeDetected
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.9),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _enterQrCodeManually,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Saisir le QR code manuellement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Intervention: ${widget.intervention.code}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class ScannerCornersPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double cornerWidth;

  ScannerCornersPainter({
    required this.color,
    this.cornerLength = 40.0,
    this.cornerWidth = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // Coin supérieur gauche
    canvas.drawLine(
      Offset(0, cornerLength),
      Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerLength, 0),
      paint,
    );

    // Coin supérieur droit
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Coin inférieur gauche
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    // Coin inférieur droit
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}