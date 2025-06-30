import 'package:flutter/material.dart';

class MysteryListItem extends StatelessWidget {
  const MysteryListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.value,
    required this.onChanged,
    this.imageWidth = 100.0, 
    this.imageHeight = 100.0, 
    this.imageFit = BoxFit.cover
  });

  final String title;
  final String subtitle;
  final String imageAsset;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double imageWidth;
  final double imageHeight;
  final BoxFit imageFit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      leading: SizedBox(
        width: imageWidth,
        height: imageHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Image.asset(
            imageAsset,
            fit: imageFit, 
          ),
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.displayMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.displaySmall,
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
       onTap: () => onChanged(!value), // Permite tocar en cualquier parte del ListTile para cambiar el switch
    );
  }
}