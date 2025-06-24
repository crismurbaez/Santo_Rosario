
  
  //Para el formato del rosario crear un objeto en el cual se guarda su configuración
  //y se puede usar otro objeto para cambiar el origen de la imagen toda vez que se quiera.
  
  class Data {
    static const Map<String, String> cuentas = {
      'perla': 'assets/images/perla.png',
      'rosa': 'assets/images/rosa.png',
      'medalla': 'assets/images/medalla.png',
      'cruz': 'assets/images/cruz.png',
      'brillo': 'assets/images/brillo.png',
    };
    static const Map<String, String> prayers = {
      'PadreNuestro': 'Padre nuestro, que estás en los cielos, santificado sea tu nombre; venga tu reino; hágase tu voluntad, así en la tierra como en el cielo. Danos hoy el pan nuestro de cada día; perdona nuestras ofensas, así como nosotros perdonamos a los que nos ofenden; no nos dejes caer en la tentación y líbranos de mal. Amén.',
      'AveMaría': 'Dios te salve, María, llena eres de gracia; el Señor es contigo; bendita tú eres entre todas las mujeres y bendito es el fruto de tu vientre, Jesús. Santa María, Madre de Dios, ruega por nosotros pecadores, ahora y en la hora de nuestra muerte. Amén.',
      'Gloria': 'Gloria al Padre, y al Hijo, y al Espíritu Santo. Como era en el principio, ahora y siempre, por los siglos de los siglos. Amén.',
      'OhJesúsMío': 'Oh Jesús mío, perdona nuestros pecados, líbranos del fuego del infierno; lleva al cielo a todas las almas, especialmente a las más necesitadas de tu misericordia.',
      'SantoDios': 'Santo Dios, Santo Fuerte, Santo Inmortal, ten piedad de nosotros y del mundo entero.',
    };
    
     static const List<MysteryDetail> mysteries = [
      MysteryDetail(
        title: 'Misterios Gozosos',
        subtitle: 'Se rezan los días Lunes y Sábado',
        imageAsset: 'assets/images/gozosos.png',
        mystery: 'gozoso',
      ),
      MysteryDetail(
        title: 'Misterios Gloriosos',
        subtitle: 'Se rezan los días Miércoles y Domingo',
        imageAsset: 'assets/images/gloriosos.png',
        mystery: 'glorioso',
      ),
      MysteryDetail(
        title: 'Misterios Dolorosos',
        subtitle: 'Se rezan los días Martes y Viernes',
        imageAsset: 'assets/images/dolorosos.png',
        mystery: 'doloroso',
      ),
      MysteryDetail(
        title: 'Misterios Luminosos',
        subtitle: 'Se rezan los días Jueves',
        imageAsset: 'assets/images/luminosos.jpg',
        mystery: 'luminoso',
      ),
    ];
  }
  
 class MysteryDetail {
  final String title;
  final String subtitle;
  final String imageAsset;
  final String mystery; 

  const MysteryDetail({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.mystery,
  });
}

