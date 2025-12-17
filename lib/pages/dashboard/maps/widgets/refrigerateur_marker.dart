import 'package:flutter/material.dart';
import 'package:ucb_app/models/refrigerateur.dart';

class RefrigerateurMarker extends StatelessWidget {
  final Refrigerateur refrigerateur;
  final bool isSelected;
  final VoidCallback onTap;
  
  const RefrigerateurMarker({
    super.key,
    required this.refrigerateur,
    this.isSelected = false,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.red.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.3 : 0.2),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _getIconForType(refrigerateur.type),
            color: Colors.white,
            size: isSelected ? 20 : 16,
          ),
        ),
      ),
    );
  }
  
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Icons.local_hospital;
      case 'alimentaire':
        return Icons.kitchen;
      case 'industriel':
        return Icons.factory;
      default:
        return Icons.kitchen;
    }
  }
}