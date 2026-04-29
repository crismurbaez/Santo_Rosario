import 'package:flutter/material.dart';
import 'package:santo_rosario/constants/app_constants.dart';

/// Switch estilo iOS/Android con carril degradado cuando está activo, tonos
/// inspirados en [AppColors.colorBackgroundBody] del rosario, más claros, y relieve 3D.
class MysterySwitch extends StatelessWidget {
  const MysterySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.scale = 1.0,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double scale;

  static const double _trackW = 52;
  static const double _trackH = 28;
  static const double _thumbSz = 22;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    final thumbLeft = value ? (_trackW - _thumbSz - _gap) : _gap;

    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Semantics(
          toggled: value,
          child: SizedBox(
            width: _trackW,
            height: _trackH,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_trackH / 2),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: _trackW,
                    height: _trackH,
                    decoration: value
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppHomeColors.switchActiveGradientTop,
                                AppHomeColors.switchActiveGradientBottom,
                              ],
                            ),
                            border: Border.all(
                              color: AppHomeColors.switchActiveTrackBorder,
                              width: 0.8,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000026),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                              BoxShadow(
                                color: Color(0x4DFFFFFF),
                                offset: Offset(0, -1),
                                blurRadius: 1,
                              ),
                            ],
                          )
                        : BoxDecoration(
                            color: AppHomeColors.switchInactiveTrack,
                            border: Border.all(
                              color: const Color(0x33FFFFFF),
                              width: 0.5,
                            ),
                          ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: thumbLeft,
                    top: (_trackH - _thumbSz) / 2,
                    child: Container(
                      width: _thumbSz,
                      height: _thumbSz,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppHomeColors.switchActiveThumb,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: value
                              ? const [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFF0F4F8),
                                ]
                              : const [
                                  Color(0xFFF5F5F5),
                                  Color(0xFFDDE1E7),
                                ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66001828),
                            offset: Offset(0, 1.5),
                            blurRadius: 2.8,
                          ),
                          BoxShadow(
                            color: Color(0xFFFFFFFF),
                            offset: Offset(0, -0.8),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
