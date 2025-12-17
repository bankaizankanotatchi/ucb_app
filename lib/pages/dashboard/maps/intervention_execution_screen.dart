import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/intervention.dart';
import 'package:ucb_app/models/refrigerateur.dart';
import 'package:ucb_app/models/rapport_intervention.dart';
import 'package:ucb_app/models/checklist.dart';
import 'package:ucb_app/services/hive_service.dart';
import 'package:image_picker/image_picker.dart';

class InterventionExecutionScreen extends StatefulWidget {
  final Intervention intervention;
  final Refrigerateur refrigerateur;
  
  const InterventionExecutionScreen({
    super.key,
    required this.intervention,
    required this.refrigerateur,
  });
  
  @override
  State<InterventionExecutionScreen> createState() => _InterventionExecutionScreenState();
}

class _InterventionExecutionScreenState extends State<InterventionExecutionScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Stockage des chemins de photos (String au lieu de File)
  List<String> _photosAvantPaths = [];
  List<String> _photosPendantPaths = [];
  List<String> _photosApresPaths = [];
  
  // Checklist et rapport
  Checklist? _checklist;
  RapportIntervention? _rapport;
  
  // Données du formulaire
  String _problemeDiagnostique = '';
  String _actionsRealisees = '';
  List<String> _piecesUtilisees = [];
  double _tempsPasse = 0.0;
  String? _observations;
  bool? _clientSatisfait;
  
  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }
  
  Future<void> _loadExistingData() async {
    // Charger la checklist
    _checklist = HiveService.getChecklistByIntervention(widget.intervention.id);
    if (_checklist == null) {
      _checklist = await HiveService.getOrCreateChecklist(
        interventionId: widget.intervention.id,
        typePanne: widget.intervention.type,
      );
    }
    
    // Charger le rapport existant
    _rapport = HiveService.getRapportByIntervention(widget.intervention.id);
    if (_rapport != null) {
      _problemeDiagnostique = _rapport!.problemeDiagnostique;
      _actionsRealisees = _rapport!.actionsRealisees;
      _piecesUtilisees = _rapport!.piecesUtilisees;
      _tempsPasse = _rapport!.tempsPasse;
      _observations = _rapport!.observations;
      _clientSatisfait = _rapport!.clientSatisfait;
    }
    
    // Charger les photos existantes du réfrigérateur
    _loadExistingPhotos();
    
    setState(() {});
  }
  
  void _loadExistingPhotos() {
    // Récupérer les photos depuis Hive
    final photos = HiveService.getPhotosRefrigerateur(widget.refrigerateur.id);
    _photosAvantPaths = photos['avant'] ?? [];
    _photosPendantPaths = photos['pendant'] ?? [];
    _photosApresPaths = photos['apres'] ?? [];
  }
  
  Future<void> _prendrePhoto(String type) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
    );
    
    if (image != null && mounted) {
      try {
        // Obtenir le répertoire de l'application
        final appDir = await getApplicationDocumentsDirectory();
        final photosDir = Directory(path.join(appDir.path, 'photos'));
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }
        
        // Générer un nom de fichier unique
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${widget.refrigerateur.id}_${type}_$timestamp.jpg';
        final newPath = path.join(photosDir.path, fileName);
        
        // Copier l'image vers le répertoire de l'app
        await File(image.path).copy(newPath);
        
        // Ajouter localement
        setState(() {
          if (type == 'avant') {
            _photosAvantPaths.add(newPath);
          } else if (type == 'pendant') {
            _photosPendantPaths.add(newPath);
          } else {
            _photosApresPaths.add(newPath);
          }
        });
        
        // Sauvegarder dans Hive
        await HiveService.addPhotoToRefrigerateur(
          refrigerateurId: widget.refrigerateur.id,
          cheminPhoto: newPath,
          type: type,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo $type enregistrée'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
      } catch (e) {
        print('❌ Erreur sauvegarde photo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur sauvegarde photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _updateChecklistItem(int index, bool verifie, {String? observation}) {
    if (_checklist == null) return;
    
    setState(() {
      _checklist!.items[index].verifie = verifie;
      if (observation != null) {
        _checklist!.items[index].observation = observation;
      }
    });
  }
  
  Future<void> _sauvegarderIntervention() async {
    // Validation des champs obligatoires
    if (_problemeDiagnostique.isEmpty) {
      _showError('Le problème diagnostiqué est obligatoire');
      return;
    }
    
    if (_actionsRealisees.isEmpty) {
      _showError('Les actions réalisées sont obligatoires');
      return;
    }
    
    if (_clientSatisfait == null) {
      _showError('Veuillez indiquer si le client est satisfait');
      return;
    }
    
    try {
      
      // 3. Sauvegarder le rapport
      final rapportId = 'rapport_${widget.intervention.id}_${DateTime.now().millisecondsSinceEpoch}';
      _rapport = RapportIntervention(
        id: rapportId,
        interventionId: widget.intervention.id,
        technicienId: HiveService.getCurrentTechnicien()?.id ?? 'tech_001',
        dateRapport: DateTime.now(),
        problemeDiagnostique: _problemeDiagnostique,
        actionsRealisees: _actionsRealisees,
        piecesUtilisees: _piecesUtilisees,
        tempsPasse: _tempsPasse,
        observations: _observations ?? '',
        clientSatisfait: _clientSatisfait!,
        photosAvant: _photosAvantPaths,
        photosApres: _photosApresPaths,
      );
      
      await HiveService.saveRapport(_rapport!);
      
      // 4. Sauvegarder la checklist
      if (_checklist != null) {
        // Vérifier que tous les items obligatoires sont cochés
        final tousObligatoiresVerifies = _checklist!.items
            .where((item) => item.obligatoire)
            .every((item) => item.verifie);
        
        _checklist!.complete = tousObligatoiresVerifies;
        _checklist!.dateCompletion = DateTime.now();
        await HiveService.saveChecklist(_checklist!);
      }
      
      // 5. Mettre à jour l'intervention
      widget.intervention.dateFin = DateTime.now();
      if (widget.intervention.dateDebut == null) {
        widget.intervention.dateDebut = DateTime.now();
      }
      widget.intervention.rapportId = rapportId;
      widget.intervention.checklistId = _checklist?.id;
      widget.intervention.updatedAt = DateTime.now();
      
      await HiveService.saveIntervention(widget.intervention);
      
      // 6. Mettre à jour le réfrigérateur avec la date de dernière maintenance
      widget.refrigerateur.dateDerniereMaintenance = DateTime.now();
      await HiveService.saveRefrigerateur(widget.refrigerateur);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Intervention terminée avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      print('❌ Erreur sauvegarde intervention: $e');
      //_showError('Erreur lors de la sauvegarde: ${e.toString()}');
      Navigator.pop(context, true);
    }
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppTheme.greyLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepItem(0, 'Photos Avant'),
          _buildStepItem(1, 'Checklist'),
          _buildStepItem(2, 'Photos Pendant'),
          _buildStepItem(3, 'Photos Après'),
          _buildStepItem(4, 'Rapport'),
        ],
      ),
    );
  }
  
  Widget _buildStepItem(int step, String label) {
    bool isActive = _currentStep == step;
    bool isCompleted = _currentStep > step;
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          step,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isCompleted 
                ? Colors.green 
                : (isActive ? AppTheme.primaryColor : Colors.grey.shade300),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPhotosStep(String type, List<String> photoPaths) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos $type',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type == 'avant' 
              ? 'Prenez des photos du réfrigérateur avant la maintenance'
              : type == 'pendant'
                ? 'Prenez des photos pendant les réparations'
                : 'Prenez des photos après la maintenance',
            style: TextStyle(color: AppTheme.textLight),
          ),
          const SizedBox(height: 24),
          
          // Bouton pour prendre une photo
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _prendrePhoto(type),
              icon: const Icon(Icons.camera_alt),
              label: Text('Prendre une photo $type'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Galerie des photos
          if (photoPaths.isNotEmpty)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: photoPaths.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _showPhotoFullScreen(photoPaths[index]);
                    },
                    child: Stack(
                      children: [
                        // Image principale
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(photoPaths[index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        
                        // Overlay pour le numéro
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        // Bouton suppression
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              _showDeleteConfirmation(index, type);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune photo $type',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showPhotoFullScreen(String photoPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(int index, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePhoto(index, type);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
  
  void _deletePhoto(int index, String type) {
    String? photoPath;
    
    setState(() {
      if (type == 'avant') {
        photoPath = _photosAvantPaths.removeAt(index);
      } else if (type == 'pendant') {
        photoPath = _photosPendantPaths.removeAt(index);
      } else {
        photoPath = _photosApresPaths.removeAt(index);
      }
    });
    
    // Supprimer aussi de Hive
    HiveService.deletePhotoFromRefrigerateur(
      refrigerateurId: widget.refrigerateur.id,
      cheminPhoto: photoPath!,
      type: type,
    );
    
    // Supprimer le fichier physique
    try {
      File(photoPath!).delete();
    } catch (e) {
      print('❌ Erreur suppression fichier: $e');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo supprimée'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Widget _buildChecklistStep() {
    if (_checklist == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checklist de vérification',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez chaque point de la checklist',
            style: TextStyle(color: AppTheme.textLight),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.builder(
              itemCount: _checklist!.items.length,
              itemBuilder: (context, index) {
                final item = _checklist!.items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Checkbox(
                      value: item.verifie,
                      onChanged: (value) {
                        _updateChecklistItem(index, value ?? false);
                      },
                    ),
                    title: Text(
                      item.description,
                      style: TextStyle(
                        fontWeight: item.obligatoire 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: item.observation != null
                        ? Text(item.observation!)
                        : null,
                    trailing: item.obligatoire
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              'Obligatoire',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade700,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Progression
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progression',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _checklist!.items
                            .where((item) => item.verifie)
                            .length /
                            _checklist!.items.length,
                        backgroundColor: Colors.grey.shade300,
                        color: _checklist!.complete 
                            ? Colors.green 
                            : AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_checklist!.items.where((item) => item.verifie).length}/${_checklist!.items.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRapportStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Rapport d\'intervention',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complétez les informations sur l\'intervention réalisée',
            style: TextStyle(color: AppTheme.textLight),
          ),
          const SizedBox(height: 24),
          
          // Problème diagnostiqué
          TextFormField(
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Problème diagnostiqué*',
              border: OutlineInputBorder(),
              hintText: 'Décrivez le problème trouvé...',
            ),
            onChanged: (value) => _problemeDiagnostique = value,
            initialValue: _rapport?.problemeDiagnostique,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est obligatoire';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Actions réalisées
          TextFormField(
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Actions réalisées*',
              border: OutlineInputBorder(),
              hintText: 'Détaillez les travaux effectués...',
            ),
            onChanged: (value) => _actionsRealisees = value,
            initialValue: _rapport?.actionsRealisees,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est obligatoire';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Temps passé
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Temps passé (heures)',
              border: OutlineInputBorder(),
              suffixText: 'heures',
            ),
            onChanged: (value) => _tempsPasse = double.tryParse(value) ?? 0.0,
            initialValue: _rapport?.tempsPasse.toString(),
          ),
          
          const SizedBox(height: 16),
          
          // Observations
          TextFormField(
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observations (optionnel)',
              border: OutlineInputBorder(),
              hintText: 'Notes supplémentaires...',
            ),
            onChanged: (value) => _observations = value,
            initialValue: _rapport?.observations,
          ),
          
          const SizedBox(height: 16),
          
          // Client satisfait
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Client satisfait ?*',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _clientSatisfait = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _clientSatisfait == true 
                            ? Colors.green 
                            : Colors.grey,
                        side: BorderSide(
                          color: _clientSatisfait == true 
                              ? Colors.green 
                              : Colors.grey,
                        ),
                      ),
                      child: const Text('OUI'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _clientSatisfait = false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _clientSatisfait == false 
                            ? Colors.red 
                            : Colors.grey,
                        side: BorderSide(
                          color: _clientSatisfait == false 
                              ? Colors.red 
                              : Colors.grey,
                        ),
                      ),
                      child: const Text('NON'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Bouton de fin
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sauvegarderIntervention,
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'TERMINER L\'INTERVENTION',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.refrigerateur.codeQR),
            Text(
              '${widget.refrigerateur.marque} ${widget.refrigerateur.modele}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildPhotosStep('avant', _photosAvantPaths),
                _buildChecklistStep(),
                _buildPhotosStep('pendant', _photosPendantPaths),
                _buildPhotosStep('après', _photosApresPaths),
                _buildRapportStep(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentStep < 4
          ? FloatingActionButton(
              onPressed: () {
                if (_currentStep < 4) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: const Icon(Icons.arrow_forward),
            )
          : null,
    );
  }
}