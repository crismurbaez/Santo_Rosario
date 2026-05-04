import 'dart:ui';

//Strings de prayers_screen.dart
abstract class AppColors {
  static const Color colorBackgroundBody = Color(0xFF1D404C);
  static const Color colorButtonPrimary = Color.fromRGBO(255, 192, 121, 0.5);
  static const Color colorBackgroundDialogError = Color.fromRGBO(
    255,
    121,
    121,
    0.8,
  );
  static const Color colorCircularProgressIndicator = Color.fromARGB(
    255,
    228,
    207,
    143,
  );
}

abstract class AppDelays {
  static const delayAudio = Duration(milliseconds: 100);
  static const delayMusic = Duration(milliseconds: 1000);
}

abstract class AppAssets {
  static const soundAveMariaBackground =
      'assets/sounds/Ave_Maria_Background.mp3';
  static const soundSignalOfTheCross = 'assets/sounds/Senal_de_la_cruz.mp3';
  static const imageVirgenLourdes = 'assets/images/VirgenLourdes.png';
}

abstract class AppAudio {
  static const backgroundMusicVolume = 0.1;
}

abstract class AppLayout {
  static const appBarToolbarHeight = 70.0;
  static const rosaryWidthFactor = 0.9;
  static const rosaryHeightFactor = 0.69;

  /// Margen vertical compacto entre las filas de controles glass en [PrayScreen]
  /// (misterio/volumen, flechas, pill). Cada fila suma arriba+abajo; el hueco
  /// real entre una fila y la siguiente es el doble de este valor.
  static const prayScreenGlassControlsRowPaddingV = 4.0;

  /// Aire bajo el pill inferior respecto al borde seguro (evita recortes).
  static const prayScreenGlassControlsBottomInset = 12.0;
  static const sectionPadding = 20.0;
  static const buttonHorizontalPadding = 20.0;
  static const buttonVerticalPadding = 20.0;
  static const rowItemSpacing = 8.0;
  static const infoIconSize = 20.0;
  static const errorBannerInset = 10.0;
}

/// Estilo “glassmorphism” compartido por la pantalla del rosario ([PrayScreen]):
/// barra superior, botones flotantes y menú de opciones de audio.
///
/// **Cómo retocar el aspecto**
/// - Más o menos desenfoque del fondo: [blurSigma] (mismo valor en X e Y).
/// - Botones circulares más grandes o pequeños: [roundButtonSize].
/// - Botón inferior (oración): [pillRadius], padding en `_prayGlassPillButton`, y
///   en `pray_screen` un [LayoutBuilder] pasa `width` para igualar el ancho útil
///   de la fila de los dos círculos (flechas).
/// - Más “vidrio” blanco: sube la opacidad del canal alpha en [frostedTint] y
///   [borderLight] (p. ej. `0x44FFFFFF` → `0x55FFFFFF`).
/// - Barra superior más oscura o clara: [navBarGradientTop] y [navBarGradientBottom].
/// - Texto más legible: [onGlassText] y [onGlassTextMuted].
/// - Panel del menú hamburguesa: [menuBorderRadius] y el padding interno del panel
///   en `_prayGlassAudioMenuPanel` de `pray_screen.dart`.
/// - Iconos del menú de audio: [menuIconMusic] (fila música) y [menuIconPrayers] (fila oraciones).
abstract class AppPrayGlass {
  /// Intensidad del desenfoque gaussiano aplicado detrás del “vidrio”
  /// (`BackdropFilter`). Valores altos = más borroso y más costoso en GPU.
  static const double blurSigma = 7;

  /// Diámetro en píxeles lógicos de los botones circulares (volumen, flechas).
  static const double roundButtonSize = 70;

  /// Tras pulsar play/stop de la sesión de audio en [PrayScreen], el botón no
  /// acepta otro toque hasta pasar este intervalo (evita taps repetidos).
  static const Duration audioSessionButtonDebounce = Duration(milliseconds: 2000);

  /// Radio de las esquinas del botón ancho inferior (oración + info).
  static const double pillRadius = 26;

  /// Radio de las esquinas del menú emergente de audio (misma familia visual que el pill).
  static const double menuBorderRadius = 14;

  /// Capa de color semitransparente encima del blur. No pongas opacidad 0 si
  /// quieres que se note el cristal; combínala con [blurSigma].
  static const Color frostedTint = Color.fromRGBO(5, 26, 34, 0.2);

  /// Color del trazo del borde del vidrio (navbar, botones, menú).
  static const Color borderLight = Color(0x55FFFFFF);

  /// Color superior del degradé bajo el blur del AppBar (más contraste arriba).
  static const Color navBarGradientTop = Color.fromRGBO(5, 26, 34, 0.447);

  /// Color inferior del degradé del AppBar (transición hacia el contenido).
  static const Color navBarGradientBottom = Color(0x480A1E28);

  /// Color principal del texto e iconos sobre superficies glass.
  static const Color onGlassText = Color(0xFFF8FBFF);

  /// Color secundario (subtítulos, textos menos prominentes).
  static const Color onGlassTextMuted = Color(0xD0E2ECF5);

  /// Icono de la fila «Música de Fondo» en el menú de audio (nota / música apagada).
  static const Color menuIconMusic = onGlassText;

  /// Icono de la fila «Audios Oraciones» en el menú (voz / silencio).
  static const Color menuIconPrayers = onGlassText;
}

abstract class AppPreferencesKeys {
  static const prayersAudioPlaying = 'isPrayersAudioPlaying';
  static const backgroundMusicPlaying = 'isBackgroundMusicPlaying';
  static const helpMessageDismissedPrefix = 'help_message_dismissed_';
  static const errorLogs = 'error_logs';
  static const savePrayerProgressEnabled = 'save_prayer_progress_enabled';
  static const prayerProgressSnapshot = 'prayer_progress_snapshot';
}

/// Identificadores de los tips “No volver a mostrar” en [PrayScreen].
/// Mantener sincronizado con `_buildHelpMessageQueueOnce`.
abstract class AppHelpMessageIds {
  static const prayKeepScreenOn = 'pray_keep_screen_on';
  static const prayNavigation = 'pray_navigation';
  static const prayAudioBehavior = 'pray_audio_behavior';
  static const prayAudioMenu = 'pray_audio_menu';
  static const prayMysteryNavigation = 'pray_mystery_navigation';

  /// Todos los consejos persistidos al marcar «No mostrar de nuevo».
  static const List<String> prayScreenTips = [
    prayKeepScreenOn,
    prayNavigation,
    prayAudioBehavior,
    prayAudioMenu,
    prayMysteryNavigation,
  ];
}

abstract class AppSentinels {
  static const noError = 'Sin Error';
}

//Strings de rosary_painter.dart

abstract class AppRosarySizes {
  static const basic = 'basic';
  static const medium = 'medium';
  static const large = 'large';
  static const largest = 'largest';
}

abstract class AppRosaryAccounts {
  static const medalla = 'medalla';
  static const brillo = 'brillo';
  static const cruz = 'cruz';
}

abstract class AppRosaryMapKeys {
  static const cuenta = 'cuenta';
  static const angle = 'angle';
  static const width = 'width';
  static const height = 'height';
  static const dstcuentas = 'dstcuentas';
  static const cuentaCenter = 'cuentaCenter';
  static const prayers = 'prayers';
  static const order = 'order';
}

//String de home_screen.dart
abstract class AppHomeLayout {
  static const appBarToolbarHeight = 50.0;
  static const minHeightOffset = 130.0;
  static const horizontalPadding = 20.0;
  static const startButtonFontSize = 20.0;
  static const transitionDuration = Duration(milliseconds: 500);
  static const listTopSpacing = 14.0;
  static const listItemGap = 6.0;
  static const todayCardMaxWidth = 240.0;
  static const todayCardRadius = 16.0;
  static const listItemRadius = 18.0;

  /// Reserva inferior del body (sombras tarjeta/botón, redondeos) para no solapar.
  static const bodyBottomVisualReserve = 28.0;

  /// Mínimo alto usable por cada fila misterio en modo Expanded (switch + texto).
  static const mysteryRowMinSlotHeight = 72.0;

  /// Estimación conservadora alto chip "Hoy es…" (icono + texto + padding).
  static const chipHeightEstimateCompact = 118.0;
  static const chipHeightEstimateRelaxed = 132.0;

  /// Espacio inferior mínimo bajo la lista cuando hay scroll para no quedar pegado /
  /// solapado visualmente al BottomAppBar (botón + padding + parte de las sombras).
  static const scrollClearOfBottomBarMin = 88.0;

  /// Hueco dentro del modo "relleno" entre la zona de tarjetas y borde inferior del body.
  static const fillModeFooterBreathingRoom = 12.0;
}

abstract class AppHomeColors {
  // Fondo general
  static const screenBackground = Color(0xFFCFE2F3);
  // Tarjetas
  static const cardBackground = Color(0xFFDCE6F1);
  static const cardShadow = Color(0x1F5E7FA2);
  // Textos
  static const titleText = Color(0xFF1F2A37);
  static const subtitleText = Color(0xFF5B6B7C);
  // Chip "Hoy es ..."
  static const todayChipBackground = Color(0xFFE5ECF4);
  static const todayChipIcon = Color(0xFF6D7885);
  static const divider = Color(0x66FFFFFF);
  // Switch activo (tono relacionado con AppColors.colorBackgroundBody rosario ~0xFF1D404C, más claro + 3D vía MysterySwitch)
  static const switchActiveGradientTop = Color(0xFF5798B4);
  static const switchActiveGradientBottom = Color(0xFF3F6B82);
  static const switchActiveTrackBorder = Color(0xFF2A4A58);
  static const switchActiveThumb = Color(0xFFFFFFFF);
  static const switchActiveTrack = Color(0xFF7DC7CF);
  // Switch inactivo
  static const switchInactiveTrack = Color(0xFFD2D7DE);
  static const switchInactiveThumb = Color(0xFF868B93);
  // Botón comenzar
  static const startButtonBackground = Color(0xFFF6B565);
  static const startButtonTop = Color(0xFFF8C176);
  static const startButtonBottom = Color(0xFFEEA952);
  static const startButtonForeground = Color(0xFF1D1A17);
  static const buttonShadowDark = Color(0x6E3D2910);
  static const buttonShadowMid = Color(0x454A3018);
  static const buttonShadowLight = Color(0x59FFE1B3);
  static const button3DBottomHighlight = Color(0xDEFFFFFF);
}

abstract class AppMysteryTypes {
  static const gozosos = 'gozosos';
  static const dolorosos = 'dolorosos';
  static const gloriosos = 'gloriosos';
  static const luminosos = 'luminosos';
}

abstract class AppWeekdays {
  static const lunes = 'Lunes';
  static const martes = 'Martes';
  static const miercoles = 'Miércoles';
  static const jueves = 'Jueves';
  static const viernes = 'Viernes';
  static const sabado = 'Sábado';
  static const domingo = 'Domingo';
}
