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
  static const imageVirgenLourdes = 'assets/images/VirgenLourdes.jpg';
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


