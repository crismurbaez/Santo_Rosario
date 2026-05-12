# Informe Técnico: Proyecto Santo Rosario

Este documento detalla el análisis exhaustivo del proyecto **Santo Rosario**, abarcando su arquitectura, funcionalidad, diseño y stack tecnológico.

---

## 1. Resumen del Proyecto
**Santo Rosario** es una aplicación móvil desarrollada en **Flutter** diseñada para guiar a los usuarios en la devoción del Santo Rosario. Combina una interfaz visualmente rica con soporte de audio guiado y funcionalidades de personalización avanzadas.

---

## 2. Arquitectura y Estructura de Archivos
El proyecto sigue una estructura modular y organizada, facilitando el mantenimiento y la escalabilidad:

- **`lib/`**: Directorio principal del código fuente.
  - **`constants/`**: Contiene `app_constants.dart`, el corazón del sistema de diseño (colores, dimensiones, estilos glassmorphism).
  - **`presentations/`**: Capa de interfaz de usuario.
    - **`screens/`**: Pantallas principales (`HomeScreen`, `PrayScreen`, `CalendarScreen`).
    - **`widgets/`**: Componentes reutilizables (ej. `RosaryPainter`, `MysteryListItem`).
  - **`services/`**: Lógica de negocio e integraciones externas (Audio, Notificaciones, Preferencias, Reporte de Errores).
  - **`providers/`**: Gestión de estado mediante **Riverpod** (`mystery_provider`, `rosary_provider`).
  - **`models/`**: Definición de estructuras de datos.
  - **`data/`**: Repositorios y fuentes de datos estáticos (textos de oraciones, rutas de audios).
- **`assets/`**: Recursos multimedia.
  - **`images/`**: Iconografía y arte sacro.
  - **`sounds/`**: Audios de oraciones y música ambiental.
  - **`fonts/`**: Tipografías personalizadas (Poppins y Playfair Display).

---

## 3. Funcionalidades Clave
La aplicación destaca por las siguientes capacidades:

1.  **Guía Visual Interactiva**: Un `RosaryPainter` personalizado dibuja el rosario y resalta la cuenta actual dinámicamente.
2.  **Sistema de Audio Dual**: 
    *   **Voz Guiada**: Oraciones grabadas que avanzan automáticamente al finalizar cada cuenta.
    *   **Música de Fondo**: Música ambiental ajustable de forma independiente.
3.  **Persistencia de Progreso**: Permite guardar el avance actual para retomar la oración en el mismo punto más tarde.
4.  **Gestión de Alarmas y Notificaciones**: Sistema integrado para programar recordatorios de oración que abren la app directamente en la pantalla de rezo.
5.  **Tutorial Dinámico**: Guía al usuario mediante mensajes y flechas animadas sobre los controles "glassmorphism".
6.  **Modo "Pantalla Siempre Encendida"**: Utiliza `wakelock_plus` para evitar que el dispositivo se bloquee durante la oración.

---

## 4. Diseño y Estética
La aplicación apuesta por un diseño **Premium** y **Moderno**, alejándose de interfaces genéricas.

### Estilo Visual
- **Glassmorphism**: Uso intensivo de efectos de desenfoque (`BackdropFilter`) y transparencias en la pantalla de rezo para crear una sensación de profundidad y elegancia.
- **Componentes 3D**: Botones y switches con gradientes y sombras que simulan profundidad física (Neumorfismo/Skeuomorfismo moderno).

### Paleta de Colores
- **Home Screen**: `#CFE2F3` (Azul hielo suave) y `#DCE6F1` (Gris azulado), transmitiendo paz y claridad.
- **Pray Screen**: `#1D404C` (Verde azulado profundo / Teal), ideal para la concentración y la oración nocturna.
- **Acentos**: `#F6B565` (Naranja atardecer) para botones de acción principal, proporcionando un contraste cálido.

### Tipografía
- **Títulos**: `Playfair Display` (Serif). Aporta elegancia, tradición y solemnidad.
- **Cuerpo de texto**: `Poppins` (Sans-serif). Garantiza legibilidad óptima y un toque moderno.

---

## 5. Stack Tecnológico
- **Lenguaje**: Dart
- **Framework**: Flutter (v3.x)
- **Gestión de Estado**: Flutter Riverpod
- **Audio**: `just_audio`
- **Notificaciones**: `flutter_local_notifications` y `timezone`
- **Persistencia**: `shared_preferences`
- **Utilidades**: `wakelock_plus`, `flutter_dotenv`, `http`, `uuid`.

---

## 6. Conclusión
**Santo Rosario** es un proyecto maduro que equilibra la tradición espiritual con las tendencias modernas de diseño UI/UX. Su robusta arquitectura de servicios y su cuidada estética lo posicionan como una herramienta de alta calidad para el usuario final.
