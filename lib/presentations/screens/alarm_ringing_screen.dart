import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import 'package:santo_rosario/services/alarm_notification_service.dart';

/// Pantalla a pantalla completa al abrir la app desde la notificación de alarma.
class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({super.key, required this.notificationId});

  final int notificationId;

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _playerReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    await AlarmNotificationService.instance.cancelNotification(
      widget.notificationId,
    );
    try {
      await _player.setAsset(AppAssets.soundAveMariaBackground);
      await _player.setLoopMode(LoopMode.all);
      await _player.setVolume(0.35);
      await _player.play();
      if (mounted) setState(() => _playerReady = true);
    } catch (e, st) {
      debugPrint('[AlarmRingingScreen] audio: $e\n$st');
    }
  }

  Future<void> _dismiss() async {
    await _player.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppHomeColors.screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppCalendarLayout.horizontalPadding,
          ),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.notifications_active_rounded,
                size: 72,
                color: AppHomeColors.startButtonBottom,
              ),
              const SizedBox(height: 20),
              Text(
                'Recordatorio del rosario',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 26,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _playerReady
                    ? 'Tocá el botón para apagar la alarma.'
                    : 'Preparando el sonido…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 15,
                      height: 1.35,
                    ),
              ),
              const Spacer(),
              Material(
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _dismiss,
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppHomeColors.startButtonTop,
                          AppHomeColors.startButtonBottom,
                        ],
                      ),
                      border: const Border(
                        bottom: BorderSide(
                          color: AppHomeColors.button3DBottomHighlight,
                          width: 3,
                        ),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppHomeColors.buttonShadowDark,
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 28,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.alarm_off_rounded,
                            color: AppHomeColors.startButtonForeground,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Apagar alarma',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppHomeColors.startButtonForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
