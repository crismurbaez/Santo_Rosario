  const List<String> prayers = [
    'Padre Nuestro',
    'Ave María',
    'Gloria al Padre',
    'Oh Jesús mío',
    'Santo Dios',
  ];
  const List<String> prayerTexts = [
    'Padre nuestro, que estás en los cielos, santificado sea tu nombre; venga tu reino; hágase tu voluntad, así en la tierra como en el cielo. Danos hoy el pan nuestro de cada día; perdona nuestras ofensas, así como nosotros perdonamos a los que nos ofenden; no nos dejes caer en la tentación y líbranos de mal. Amén.',
    'Dios te salve, María, llena eres de gracia; el Señor es contigo; bendita tú eres entre todas las mujeres y bendito es el fruto de tu vientre, Jesús. Santa María, Madre de Dios, ruega por nosotros pecadores, ahora y en la hora de nuestra muerte. Amén.',
    'Gloria al Padre, y al Hijo, y al Espíritu Santo. Como era en el principio, ahora y siempre, por los siglos de los siglos. Amén.',
    'Oh Jesús mío, perdona nuestros pecados, líbranos del fuego del infierno; lleva al cielo a todas las almas, especialmente a las más necesitadas de tu misericordia.',
    'Santo Dios, Santo Fuerte, Santo Inmortal, ten piedad de nosotros y del mundo entero.',
  ];
  
  //Para el formato del rosario crear un objeto en el cual se guarda su configuración
  //y se puede usar otro objeto para cambiar el origen de la imagen toda vez que se quiera.
  
  const Map<String, String> cuentas = {
  'medalla': 'assets/images/medalla.png', 
  'perla': 'assets/images/perla.png',
  'rosa': 'assets/images/rosa.png',
  'cruz': 'assets/images/cruz.png',
  };

  class Data {
    static const Map<String, String> cuentas = {
      'perla': 'assets/images/perla.png',
      'rosa': 'assets/images/rosa.png',
      'medalla': 'assets/images/medalla.png',
      'cruz': 'assets/images/cruz.png',
    };
  }

  const List<String> perlas = [
    'assets/images/medalla.png', //0 la más grande de todas y desplazada hacia abajo
    'assets/images/perla.png', //1
    'assets/images/perla.png', //2
    'assets/images/perla.png', // 3
    'assets/images/perla.png', //4
    'assets/images/perla.png', //5
    'assets/images/perla.png', //6
    'assets/images/perla.png', //7
    'assets/images/perla.png', //8
    'assets/images/perla.png',  //9
    'assets/images/perla.png', //10
    'assets/images/rosa.png', //11 más grande
    'assets/images/perla.png', //1 
    'assets/images/perla.png', //2
    'assets/images/perla.png', //3
    'assets/images/perla.png', //4
    'assets/images/perla.png', //5
    'assets/images/perla.png', //6
    'assets/images/perla.png', //7
    'assets/images/perla.png', //8
    'assets/images/perla.png', //9
    'assets/images/perla.png', //21 10
    'assets/images/rosa.png', //22 más grande
    'assets/images/perla.png', //1
    'assets/images/perla.png', //2
    'assets/images/perla.png', // 3
    'assets/images/perla.png', //4
    'assets/images/perla.png', //5
    'assets/images/perla.png', //6
    'assets/images/perla.png', //7
    'assets/images/perla.png', //8
    'assets/images/perla.png',  //9
    'assets/images/perla.png', //10 32
    'assets/images/rosa.png', //33 más grande
    'assets/images/perla.png', //1
    'assets/images/perla.png', //2
    'assets/images/perla.png', // 3
    'assets/images/perla.png', //4
    'assets/images/perla.png', //5
    'assets/images/perla.png', //6
    'assets/images/perla.png', //7
    'assets/images/perla.png', //8
    'assets/images/perla.png',  //9
    'assets/images/perla.png', //10 43
    'assets/images/rosa.png', //44 más grande
    'assets/images/perla.png', //1
    'assets/images/perla.png', //2
    'assets/images/perla.png', // 3
    'assets/images/perla.png', //4
    'assets/images/perla.png', //5
    'assets/images/perla.png', //6
    'assets/images/perla.png', //7
    'assets/images/perla.png', //8
    'assets/images/perla.png',  //9
    'assets/images/perla.png', //10 54
  ]; 

    const List<String> nuevasPerlas  = [
    'assets/images/rosa.png',  //0 (más grande)
    'assets/images/perla.png', //1 
    'assets/images/perla.png',  //2
    'assets/images/perla.png', //3
    'assets/images/rosa.png', //4 (más grande)
    'assets/images/cruz.png',   //5 (la más grande)
  ];