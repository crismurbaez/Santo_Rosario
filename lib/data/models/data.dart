//Para el formato del rosario crear un objeto en el cual se guarda su configuración
//y se puede usar otro objeto para cambiar el origen de la imagen toda vez que se quiera.

class Data {
  static const Map<String, String> images = {
    'perla': 'assets/images/perla.png',
    'rosa': 'assets/images/rosa.png',
    'medalla': 'assets/images/medalla.png',
    'cruz': 'assets/images/cruz.png',
    'brillo': 'assets/images/brillo.png',
  };

  static const Map<String, String> prayers = {
    'Señal de la Cruz':
        'Por la señal de la Santa Cruz, de nuestros enemigos, líbranos Señor Dios Nuestro. En el nombre del Padre, del Hijo, y del Espíritu Santo. Amén.',
    'Credo':
        'Creo en Dios, Padre todopoderoso, Creador del cielo y de la tierra; y en Jesucristo, su único Hijo, nuestro Señor, que fue concebido por obra y gracia del Espíritu Santo; nació de Santa María Virgen; padeció bajo el poder de Poncio Pilato; fue crucificado, muerto y sepultado; descendió a los infiernos; al tercer día resucitó de entre los muertos; subió a los cielos, y está sentado a la derecha de Dios, Padre todopoderoso; desde allí ha de venir a juzgar a vivos y muertos. Creo en el Espíritu Santo, la santa Iglesia católica, la comunión de los santos, el perdón de los pecados, la resurrección de la carne y la vida eterna. Amén.',
    'Pésame':
        'Yo confiezo ante Dios Todopoderoso y ante ustedes hermanos que he pecado mucho, de pensamiento, palabra, obra y omisión. Por mi culpa, por mi culpa, por mi gran culpa. Por eso ruego a Santa María siempre Virgen, a los ángeles, a los Santos y a ustedes hermanos, que intercedan por mí ante Dios Nuestro Señor Jesucristo. Amén.',
    'Padre Nuestro':
        'Padre nuestro, que estás en los cielos, santificado sea tu nombre; venga tu reino; hágase tu voluntad, así en la tierra como en el cielo. Danos hoy el pan nuestro de cada día; perdona nuestras ofensas, así como nosotros perdonamos a los que nos ofenden; no nos dejes caer en la tentación y líbranos de mal. Amén.',
    'Ave María':
        'Dios te salve, María, llena eres de gracia; el Señor es contigo; bendita tú eres entre todas las mujeres y bendito es el fruto de tu vientre, Jesús. Santa María, Madre de Dios, ruega por nosotros pecadores, ahora y en la hora de nuestra muerte. Amén.',
    'Gloria':
        'Gloria al Padre, y al Hijo, y al Espíritu Santo. Como era en el principio, ahora y siempre, por los siglos de los siglos. Amén.',
    'Oh Jesús Mío':
        'Oh Jesús mío, perdona nuestros pecados, líbranos del fuego del infierno; lleva al cielo a todas las almas, especialmente a las más necesitadas de tu misericordia.',
    'María Madre de Gracia':
        'María Madre de Gracia y Madre de Misericordia, en la vida y en la muerte, ampáranos Oh! Gran Señora. Cubre con tu Manto a mis hijos, a mi familia y a mis amigos. Amén.',
    'Intenciones del Papa':
        'Pedimos por la intenciones del Papa, por las almas del purgatorio, por los pecadores en todas partes, por los pecadores en la iglesia universal, por los de mi propio hogar y dentro de mi familia.',
    'Dios te Salve':
        'Dios te salve Reina y Madre de Misericordia, vida dulzura y esperanza nuestra. Dios te salve, a ti clamamos los desterrados hijos de Eva, a tí suspiramos gimiendo y llorando en este valle de lágrimas. Ea, pues, Señora abogada nuestra, vuelve a nosotros esos tus ojos misericordiosos; y después de este destierro muéstranos a Jesús, fruto bendito de tu vientre. Oh! Clementísima, Oh! Piadosa, Oh! Dulce Virgen María! Ruega por nosostros Santa Madre de Dios, para que seamos dignos de alcanzar las promesas y Gracias, de Nuestro Señor Jesucristo. Amén.',
    'Santo Dios':
        'Santo Dios, Santo Fuerte, Santo Inmortal, ten piedad de nosotros y del mundo entero.',
  };
  static const Map<String, String> prayersSounds = {
    'Señal de la Cruz': 'assets/sounds/Senal_de_la_cruz.mp3',
    'Credo': 'assets/sounds/Credo.mp3',
    'Pésame': 'assets/sounds/Pesame.mp3',
    'Padre Nuestro': 'assets/sounds/Padre_Nuestro.mp3',
    'Ave María': 'assets/sounds/Ave_Maria.mp3',
    'Gloria': 'assets/sounds/Gloria.mp3',
    'Oh Jesús Mío': 'assets/sounds/Oh_Jesus_mio.mp3',
    'María Madre de Gracia': 'assets/sounds/Maria_Madre_de_Gracia.mp3',
    'Intenciones del Papa': 'assets/sounds/Intenciones_del_papa.mp3',
    'Dios te Salve': 'assets/sounds/Dios_te_Salve.mp3',
    'gozosos1': 'assets/sounds/gozosos1.mp3',
    'gozosos2': 'assets/sounds/gozosos2.mp3',
    'gozosos3': 'assets/sounds/gozosos3.mp3',
    'gozosos4': 'assets/sounds/gozosos4.mp3',
    'gozosos5': 'assets/sounds/gozosos5.mp3',
    'gloriosos1': 'assets/sounds/gloriosos1.mp3',
    'gloriosos2': 'assets/sounds/gloriosos2.mp3',
    'gloriosos3': 'assets/sounds/gloriosos3.mp3',
    'gloriosos4': 'assets/sounds/gloriosos4.mp3',
    'gloriosos5': 'assets/sounds/gloriosos5.mp3',
    'dolorosos1': 'assets/sounds/dolorosos1.mp3',
    'dolorosos2': 'assets/sounds/dolorosos2.mp3',
    'dolorosos3': 'assets/sounds/dolorosos3.mp3',
    'dolorosos4': 'assets/sounds/dolorosos4.mp3',
    'dolorosos5': 'assets/sounds/dolorosos5.mp3',
    'luminosos1': 'assets/sounds/luminosos1.mp3',
    'luminosos2': 'assets/sounds/luminosos2.mp3',
    'luminosos3': 'assets/sounds/luminosos3.mp3',
    'luminosos4': 'assets/sounds/luminosos4.mp3',
    'luminosos5': 'assets/sounds/luminosos5.mp3',
  };
  static const List<MysteriesMeditations> meditations = [
    MysteriesMeditations(
      mystery: 'gozosos',
      order: 1,
      meditation: 'La Anunciación del Arcángel Gabriel a María',
      scriptural:
          'Lucas 1:26-38, El ángel Gabriel se presenta a María y le anuncia que será la Madre del Salvador. Ella se humilla diciendo: "He aquí la esclava del Señor; hágase en mí según tu palabra.',
      image: 'assets/images/gozosos1.png',
    ),
    MysteriesMeditations(
      mystery: 'gozosos',
      order: 2,
      meditation: 'La Visitación de María a su prima Isabel',
      scriptural:
          'Lucas 1:39-56, María visita a Isabel, quien la reconoce como la Madre del Señor. María proclama el Magnificat, alabando las maravillas de Dios.',
      image: 'assets/images/gozosos2.png',
    ),
    MysteriesMeditations(
      mystery: 'gozosos',
      order: 3,
      meditation: 'El Nacimiento del Hijo de Dios',
      scriptural:
          'Lucas 2:1-20, María da a luz a Jesús en Belén, envuelto en pañales y acostado en un pesebre.',
      image: 'assets/images/gozosos3.png',
    ),
    MysteriesMeditations(
      mystery: 'gozosos',
      order: 4,
      meditation: 'La Presentación del Niño Jesús en el Templo',
      scriptural:
          'Lucas 2:22-40, María y José presentan a Jesús en el Templo, donde Simeón y Ana lo reconocen como el Mesías.',
      image: 'assets/images/gozosos4.png',
    ),
    MysteriesMeditations(
      mystery: 'gozosos',
      order: 5,
      meditation: 'El Encuentro de Jesús en el Templo',
      scriptural:
          'Lucas 2:41-52, Jesús, a los doce años, se queda en el Templo hablando con los doctores de la ley, y María y José lo encuentran después de tres días de búsqueda.',
      image: 'assets/images/gozosos5.png',
    ),
    MysteriesMeditations(
      mystery: 'gloriosos',
      order: 1,
      meditation: 'La Resurrección de Jesús',
      scriptural:
          'Mateo 28:1-10, Jesús resucita de entre los muertos, apareciéndose primero a María Magdalena y luego a los discípulos.',
      image: 'assets/images/gloriosos1.png',
    ),
    MysteriesMeditations(
      mystery: 'gloriosos',
      order: 2,
      meditation: 'La Ascensión de Jesús al Cielo',
      scriptural:
          'Hechos 1:9-11, Jesús asciende al cielo en presencia de sus discípulos, prometiendo enviar el Espíritu Santo.',
      image: 'assets/images/gloriosos2.png',
    ),
    MysteriesMeditations(
      mystery: 'gloriosos',
      order: 3,
      meditation: 'La Venida del Espíritu Santo sobre los Apóstoles',
      scriptural:
          'Hechos 2:1-4, En Pentecostés, el Espíritu Santo desciende sobre los apóstoles, dándoles valentía para predicar el Evangelio.',
      image: 'assets/images/gloriosos3.png',
    ),
    MysteriesMeditations(
      mystery: 'gloriosos',
      order: 4,
      meditation: 'La Asunción de María al Cielo',
      scriptural:
          'Apocalipsis 12:1-6, María es llevada al cielo en cuerpo y alma.',
      image: 'assets/images/gloriosos4.png',
    ),
    MysteriesMeditations(
      mystery: 'gloriosos',
      order: 5,
      meditation: 'La Coronación de María como Reina del Cielo y de la Tierra',
      scriptural:
          'Apocalipsis 12:1-6, María es coronada como Reina del Cielo y de la Tierra, intercediendo por nosotros ante su Hijo.',
      image: 'assets/images/gloriosos5.png',
    ),
    MysteriesMeditations(
      mystery: 'dolorosos',
      order: 1,
      meditation: 'La Oración de Jesús en el Huerto de Getsemaní',
      scriptural:
          'Mateo 26:36-46, Jesús ora en el Huerto de Getsemaní, enfrentando su pasión y muerte inminente.',
      image: 'assets/images/dolorosos1.png',
    ),
    MysteriesMeditations(
      mystery: 'dolorosos',
      order: 2,
      meditation: 'La Flagelación de Jesús',
      scriptural:
          'Mateo 27:26, Jesús es azotado y humillado por los soldados romanos antes de su crucifixión.',
      image: 'assets/images/dolorosos2.png',
    ),
    MysteriesMeditations(
      mystery: 'dolorosos',
      order: 3,
      meditation: 'La Coronación de Espinas',
      scriptural:
          'Mateo 27:27-31, Jesús es coronado con una corona de espinas, burlándose de su realeza.',
      image: 'assets/images/dolorosos3.png',
    ),
    MysteriesMeditations(
      mystery: 'dolorosos',
      order: 4,
      meditation: 'El Camino del Calvario',
      scriptural:
          'Lucas 23:27-31, Jesús carga su cruz hacia el Calvario, encontrándose con las mujeres de Jerusalén que lloran por él.',
      image: 'assets/images/dolorosos4.png',
    ),
    MysteriesMeditations(
      mystery: 'dolorosos',
      order: 5,
      meditation: 'La Crucifixión y Muerte de Jesús',
      scriptural:
          'Lucas 23:33-46, Jesús es crucificado y muere en la cruz por nuestros pecados, entregando su espíritu al Padre.',
      image: 'assets/images/dolorosos5.png',
    ),
    MysteriesMeditations(
      mystery: 'luminosos',
      order: 1,
      meditation: 'El Bautismo de Jesús en el Jordán',
      scriptural:
          'Mateo 3:13-17, Jesús es bautizado por Juan el Bautista en el río Jordán, donde el Espíritu Santo desciende sobre él y se escucha la voz del Padre.',
      image: 'assets/images/luminosos1.png',
    ),
    MysteriesMeditations(
      mystery: 'luminosos',
      order: 2,
      meditation: 'La Autorrevelación de Jesús en las Bodas de Caná',
      scriptural:
          'Juan 2:1-11, Jesús realiza su primer milagro convirtiendo agua en vino en las bodas de Caná, manifestando su gloria y fortaleciendo la fe de sus discípulos.',
      image: 'assets/images/luminosos2.png',
    ),
    MysteriesMeditations(
      mystery: 'luminosos',
      order: 3,
      meditation:
          'La Predicación del Reino de Dios y la Invitación a la Conversión',
      scriptural:
          'Mateo 4:17, Jesús comienza su ministerio predicando el Reino de Dios y llamando a la conversión, invitando a todos a seguirlo.',
      image: 'assets/images/luminosos3.png',
    ),
    MysteriesMeditations(
      mystery: 'luminosos',
      order: 4,
      meditation: 'La Transfiguración de Jesús en el Monte Tabor',
      scriptural:
          'Mateo 17:1-9, Jesús se transfigura en el monte Tabor, mostrando su gloria divina a Pedro, Santiago y Juan, y siendo confirmado por la voz del Padre.',
      image: 'assets/images/luminosos4.png',
    ),
    MysteriesMeditations(
      mystery: 'luminosos',
      order: 5,
      meditation: 'La Institución de la Eucaristía',
      scriptural:
          'Mateo 26:26-29, En la Última Cena, Jesús instituye la Eucaristía, entregando su cuerpo y sangre a sus discípulos como alimento espiritual.',
      image: 'assets/images/luminosos5.png',
    ),
  ];

  static const List<MysteryDetail> mysteries = [
    MysteryDetail(
      title: 'Misterios Gozosos',
      subtitle: 'Lunes y Sábado',
      imageAsset: 'assets/images/gozosos1.png',
      mystery: 'gozosos',
    ),
    MysteryDetail(
      title: 'Misterios Gloriosos',
      subtitle: 'Miércoles y Domingo',
      imageAsset: 'assets/images/gloriosos1.png',
      mystery: 'gloriosos',
    ),
    MysteryDetail(
      title: 'Misterios Dolorosos',
      subtitle: 'Martes y Viernes',
      imageAsset: 'assets/images/dolorosos1.png',
      mystery: 'dolorosos',
    ),
    MysteryDetail(
      title: 'Misterios Luminosos',
      subtitle: 'Jueves',
      imageAsset: 'assets/images/luminosos1.png',
      mystery: 'luminosos',
    ),
  ];
  //TODO: para que se pueda cambiar el rosario de acuerdo a la configuración
  //TODO: agregar otra capa donde ponga cada elemeto que va a ser parte del rosario
  static int get rosaryCircleBeadCount => rosaryDetailsCircle.fold(0, (sum, item) => sum + item.count);
  static const List<RosaryBeadGroup> rosaryDetailsCircle = [
    RosaryBeadGroup(
      cuenta: 'medalla',
      count: 1,
      order: 1,
      width: 'large',
      height: 'large',
      prayers: [
        'Señal de la Cruz',
        'Credo',
        'Pésame',
        'Misterio',
        'Padre Nuestro',
      ],
    ),
    RosaryBeadGroup(
      cuenta: 'perla',
      count: 10,
      order: 1,
      width: 'basic',
      height: 'basic',
      prayers: ['Ave María'],
    ),
    RosaryBeadGroup(
      cuenta: 'rosa',
      count: 1,
      order: 2,
      width: 'medium',
      height: 'medium',
      prayers: [
        'Gloria',
        'Oh Jesús Mío',
        'María Madre de Gracia',
        'Misterio',
        'Padre Nuestro',
      ],
    ),
    RosaryBeadGroup(
      cuenta: 'perla',
      count: 10,
      order: 2,
      width: 'basic',
      height: 'basic',
      prayers: ['Ave María'],
    ),
    RosaryBeadGroup(
      cuenta: 'rosa',
      count: 1,
      order: 3,
      width: 'medium',
      height: 'medium',
      prayers: [
        'Gloria',
        'Oh Jesús Mío',
        'María Madre de Gracia',
        'Misterio',
        'Padre Nuestro',
      ],
    ),
    RosaryBeadGroup(
      cuenta: 'perla',
      count: 10,
      order: 3,
      width: 'basic',
      height: 'basic',
      prayers: ['Ave María'],
    ),
    RosaryBeadGroup(
      cuenta: 'rosa',
      count: 1,
      order: 4,
      width: 'medium',
      height: 'medium',
      prayers: [
        'Gloria',
        'Oh Jesús Mío',
        'María Madre de Gracia',
        'Misterio',
        'Padre Nuestro',
      ],
    ),
    RosaryBeadGroup(
      cuenta: 'perla',
      count: 10,
      order: 4,
      width: 'basic',
      height: 'basic',
      prayers: ['Ave María'],
    ),
    RosaryBeadGroup(
      cuenta: 'rosa',
      count: 1,
      order: 5,
      width: 'medium',
      height: 'medium',
      prayers: [
        'Gloria',
        'Oh Jesús Mío',
        'María Madre de Gracia',
        'Misterio',
        'Padre Nuestro',
      ],
    ),
    RosaryBeadGroup(
      cuenta: 'perla',
      count: 10,
      order: 5,
      width: 'basic',
      height: 'basic',
      prayers: ['Ave María'],
    ),
  ];
  static int get rosaryExtensionBeadCount => rosaryDetailsExtension.fold(0, (sum, item) => sum + item.count);
  static const List<RosaryBeadGroup> rosaryDetailsExtension = [
    RosaryBeadGroup(
      cuenta: 'rosa',
      count: 1,
      order: 6,
      width: 'medium',
      height: 'medium',
      prayers: [
        'Gloria',
        'Oh Jesús Mío',
        'María Madre de Gracia',
        'Intenciones del Papa',
        'Padre Nuestro',
      ],
    ),
    RosaryBeadGroup(
      cuenta: 'perla',
      count: 3,
      order: 6,
      width: 'basic',
      height: 'basic',
      prayers: ['Ave María'],
    ),
    RosaryBeadGroup(
      cuenta: 'rosa',
      count: 1,
      order: 6,
      width: 'medium',
      height: 'medium',
      prayers: ['Gloria', 'Dios te Salve'],
    ),
    RosaryBeadGroup(
      cuenta: 'cruz',
      count: 1,
      order: 6,
      width: 'largest',
      height: 'largest',
      prayers: ['Señal de la Cruz'],
    ),
  ];

  static List<RosaryBeadStepInfo>? _rosaryBeadStepsCache;
  static List<RosaryMysteryAnchorInfo>? _rosaryMysteryAnchorsCache;

  /// Oraciones y orden de misterio por índice de cuenta (coincide con [CuentasPainter.counter]).
  static List<RosaryBeadStepInfo> get rosaryBeadSteps {
    _rosaryBeadStepsCache ??= _buildRosaryBeadSteps();
    return _rosaryBeadStepsCache!;
  }

  /// Índices de cuenta + índice de oración «Misterio» para saltos de misterio.
  static List<RosaryMysteryAnchorInfo> get rosaryMysteryAnchors {
    _rosaryMysteryAnchorsCache ??= _computeRosaryMysteryAnchors();
    return _rosaryMysteryAnchorsCache!;
  }

  static List<RosaryBeadStepInfo> _buildRosaryBeadSteps() {
    final out = <RosaryBeadStepInfo>[];
    for (final d in rosaryDetailsCircle) {
      for (var i = 0; i < d.count; i++) {
        out.add(RosaryBeadStepInfo(prayers: d.prayers, orderMystery: d.order));
      }
    }
    for (final d in rosaryDetailsExtension) {
      for (var i = 0; i < d.count; i++) {
        out.add(RosaryBeadStepInfo(prayers: d.prayers, orderMystery: d.order));
      }
    }
    return out;
  }

  static List<RosaryMysteryAnchorInfo> _computeRosaryMysteryAnchors() {
    final steps = rosaryBeadSteps;
    final out = <RosaryMysteryAnchorInfo>[];
    for (var i = 0; i < steps.length; i++) {
      final ix = steps[i].prayers.indexOf('Misterio');
      if (ix >= 0) {
        out.add(RosaryMysteryAnchorInfo(beadIndex: i, misterioPrayerIndex: ix));
      }
    }
    return out;
  }
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

class RosaryBeadGroup {
  final String cuenta;
  final int count;
  final int order;
  final String width;
  final String height;
  final List<String> prayers;

  const RosaryBeadGroup({
    required this.cuenta,
    required this.count,
    required this.order,
    required this.width,
    required this.height,
    required this.prayers,
  });
}


/// Una cuenta del rosario (misma secuencia que expande `CuentasPainter`).
class RosaryBeadStepInfo {
  final List<String> prayers;
  final int orderMystery;

  const RosaryBeadStepInfo({required this.prayers, required this.orderMystery});
}

/// Posición de la oración «Misterio» dentro de una cuenta.
class RosaryMysteryAnchorInfo {
  final int beadIndex;
  final int misterioPrayerIndex;

  const RosaryMysteryAnchorInfo({
    required this.beadIndex,
    required this.misterioPrayerIndex,
  });
}

class MysteriesMeditations {
  final String mystery;
  final int order;
  final String meditation;
  final String scriptural;
  final String image;

  const MysteriesMeditations({
    required this.mystery,
    required this.order,
    required this.meditation,
    required this.scriptural,
    required this.image,
  });
}
