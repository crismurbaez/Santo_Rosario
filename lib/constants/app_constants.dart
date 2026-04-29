import 'dart:ui';

//Strings de prayers_screen.dart
abstract class AppColors {
  static const Color colorBackgroundBody = Color(0xFF1D404C);
  static const Color colorButtonPrimary = Color.fromRGBO(255, 192, 121, 0.5);
  static const Color colorBackgroundDialogError = Color.fromRGBO(255, 121, 121, 0.8);
  static const Color colorCircularProgressIndicator = Color.fromARGB(255, 228, 207, 143);
}

abstract class AppDelays {
  static const delayAudio =  Duration(milliseconds: 100);
  static const delayMusic =  Duration(milliseconds: 15000);
}

abstract class AppAssets {
  static const soundAveMariaBackground = 'assets/sounds/Ave_Maria_Background.mp3';
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
  static const sectionPadding = 20.0;
  static const buttonHorizontalPadding = 20.0;
  static const buttonVerticalPadding = 20.0;
  static const rowItemSpacing = 8.0;
  static const infoIconSize = 20.0;
  static const errorBannerInset = 10.0;
}

abstract class AppPreferencesKeys {
  static const prayersAudioPlaying = 'isPrayersAudioPlaying';
  static const backgroundMusicPlaying = 'isBackgroundMusicPlaying';
}

abstract class AppSentinels {
  static const noError = 'Sin Error';
}

//Strings de rosary_painter.dart

abstract class AppRosarySizes {
  static const basic = 'basic';
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
  static const startButtonForeground =  Color(0xFF1D1A17);
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