import 'package:flutter/material.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import 'package:santo_rosario/presentations/widgets/mystery_switch.dart';

class MysteryListItem extends StatelessWidget {
  const MysteryListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.value,
    required this.onChanged,
    this.expandToParentSlot = false,
    this.imageWidth = 96.0,
    this.imageHeight = 52.0,
    this.imageFit = BoxFit.cover,
  });

  final String title;
  final String subtitle;
  final String imageAsset;
  final bool value;
  final ValueChanged<bool> onChanged;
  /// Si es true, el padre debe dar altura finita (p. ej. [Expanded]): la tarjeta
  /// usa todo ese alto e imagen proporcional al hueco y al ancho.
  final bool expandToParentSlot;
  final double imageWidth;
  final double imageHeight;
  final BoxFit imageFit;

  @override
  Widget build(BuildContext context) {
    if (expandToParentSlot) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final slotH = constraints.maxHeight;
          final slotW = constraints.maxWidth;
          final safeH = slotH.isFinite ? slotH : 96.0;
          final screenW = MediaQuery.sizeOf(context).width;
          final rowW = slotW.isFinite && slotW > 0 ? slotW : screenW;
          final imgH = (safeH * 0.62).clamp(42.0, safeH - 10.0);
          final imgW = (rowW * 0.32).clamp(88.0, 172.0);

          return SizedBox(
            height: safeH.isFinite ? safeH : null,
            width: double.infinity,
            child: _cardShell(
              context,
              marginV: 0,
              compact: false,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: safeH > 96 ? 6 : 4),
              horizontalTitleGap: 12,
              minTileHeight: safeH.isFinite ? safeH : 96,
              imgW: imgW,
              imgH: imgH,
            ),
          );
        },
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = screenHeight < 620;
    final tileMinHeight = compact
        ? (screenWidth * 0.22).clamp(72.0, 92.0)
        : (screenWidth * 0.28).clamp(94.0, 116.0);
    final dynamicImageHeight = compact
        ? (tileMinHeight * 0.65).clamp(44.0, 68.0)
        : (tileMinHeight * 0.72).clamp(60.0, 92.0);
    final dynamicImageWidth = compact
        ? (screenWidth * 0.28).clamp(88.0, 124.0)
        : (screenWidth * 0.31).clamp(108.0, 156.0);

    return _cardShell(
      context,
      compact: compact,
      marginV: compact ? 1 : 2,
      marginH: compact ? 10 : 12,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 6,
      ),
      horizontalTitleGap: compact ? 8 : 12,
      minTileHeight: tileMinHeight,
      imgW: dynamicImageWidth,
      imgH: dynamicImageHeight,
    );
  }

  Widget _cardShell(
    BuildContext context, {
    required double minTileHeight,
    required double imgW,
    required double imgH,
    required EdgeInsets contentPadding,
    required double horizontalTitleGap,
    required bool compact,
    double marginV = 2,
    double marginH = 12,
  }) {
    final switchScale = compact ? 0.82 : 1.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: marginH, vertical: marginV),
      constraints: BoxConstraints(minHeight: minTileHeight),
      decoration: BoxDecoration(
        color: AppHomeColors.cardBackground,
        borderRadius: BorderRadius.circular(AppHomeLayout.listItemRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66203048),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 7),
          ),
          BoxShadow(
            color: Color(0x40203245),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x4DFFFFFF),
            blurRadius: 2,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppHomeLayout.listItemRadius),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: contentPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: imgW,
                  height: imgH,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(imageAsset, fit: imageFit),
                  ),
                ),
                SizedBox(width: horizontalTitleGap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: AppHomeColors.titleText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppHomeColors.subtitleText,
                                ),
                      ),
                    ],
                  ),
                ),
                MysterySwitch(
                  value: value,
                  onChanged: onChanged,
                  scale: switchScale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}