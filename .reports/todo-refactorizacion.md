# TODO — Refactorización (derivado del análisis de estructura)

Este documento traduce las recomendaciones de [analisis-estructura-proyecto.md](./analisis-estructura-proyecto.md) en tareas concretas y un orden sugerido.

---

## Por dónde conviene empezar

**Recomendación: empezar por extracciones mecánicas y de bajo riesgo**, antes de introducir Provider/Riverpod/Bloc o reescribir el flujo de audio.

### Orden sugerido (primer paso → siguiente)

1. **Primero: extraer `CuentasPainter` (CustomPainter)**  
   - Archivo actual: pantalla del rosario (p. ej. `pray_screen_3.dart` / `pray_screen.dart`).  
   - Destino sugerido: `lib/presentations/widgets/rosary_painter.dart` (o nombre equivalente).  
   - **Por qué aquí:** Es un “corte y pega” con imports; casi no cambia el comportamiento. Reduce cientos de líneas en un solo archivo y hace el resto del refactor más legible.

2. **En paralelo o justo después: `lib/constants/app_constants.dart`**  
   - Sacar delays (p. ej. 15000 ms), factores de escala del layout, strings repetidos si aplica.  
   - **Por qué:** Cambios localizados, fáciles de revisar, beneficio inmediato en mantenibilidad.

3. **Luego: servicio de audio**  
   - `lib/services/audio_service.dart` (o similar) encapsulando `AudioPlayer`, preferencias de volumen/bucle y transiciones de reproducción.  
   - **Por qué:** Es la parte más delicada; conviene hacerla cuando la pantalla ya no arrastra el painter gigante.

4. **Después: utilidad de misterios / día de la semana**  
   - `lib/utils/mystery_utils.dart`: mapeo día → misterio activo, nombre del día, etc., usado desde `home_screen`.  
   - **Por qué:** Despeja lógica de negocio del widget sin depender aún de un state management global.

5. **Más adelante: gestor de estado (Provider, Riverpod o Bloc)**  
   - Cuando la pantalla del rosario y el home compartan reglas o cuando el estado sea difícil de seguir solo con `setState`.

6. **Al final o cuando decidas el alcance: `CalendarScreen`**  
   - Completar funcionalidad (recordatorios, etc.) o ocultar/eliminar la ruta si no se usa.

**Resumen en una frase:** *Empieza por sacar el `CustomPainter` a su archivo y las constantes; es lo que más reduce complejidad con menos riesgo. El audio y el state management vienen después.*

---

## Checklist por fase

### Fase 0 — Preparación (rápida)

- [*] Confirmar nombre canónico de la pantalla del rosario (`pray_screen.dart` vs `pray_screen_3.dart`) y actualizar imports en `app.dart` / `home_screen.dart`.
- [ ] Ejecutar `dart format lib` y dejar el árbol formateado antes de refactors grandes (facilita diffs).
- [ ] Hacer commit o rama de trabajo antes de la Fase 1.

### Fase 1 — Extracción del painter (prioridad inmediata)

- [*] Crear `lib/presentations/widgets/rosary_painter.dart` (o nombre acordado).
- [*] Mover clase `CuentasPainter` y dependencias directas (imports de `dart:ui`, `Data`, etc.).
- [*] Reexportar o importar desde la pantalla del rosario y verificar que dibuja igual.
- [*] Ajustar `shouldRepaint` si hace falta tras el movimiento (sin cambiar lógica salvo bugs evidentes).(no veo necesidad de hacer cambios por ahora)

### Fase 2 — Constantes

- [*] Crear `lib/constants/app_constants.dart`.
- [ ] Mover delays, porcentajes de layout, duraciones de transición, etc.
- [ ] Sustituir literales en pantalla del rosario y, si aplica, en `home_screen`.

### Fase 3 — Audio y preferencias

- [ ] Crear `lib/services/audio_service.dart` (reproducción oraciones + música de fondo, stop/dispose).
- [ ] Crear `lib/services/preferences_service.dart` o capa fina sobre `SharedPreferences` (flags de audio).
- [ ] Conectar la pantalla del rosario al servicio; mantener misma UX que hoy.
- [ ] Sustituir `print()` de depuración por `debugPrint` o un logger mínimo.

### Fase 4 — Errores y UX

- [ ] Sustituir el patrón `_errorMessage != 'Sin Error'` por un modelo claro (enum, sealed class o nullable).
- [ ] Unificar cómo se muestran errores al usuario (SnackBar, banner, diálogo) según gravedad.
- [ ] Revisar `PrayerDialog` cuando `meditation == null` (mensaje útil, sin UI rota).

### Fase 5 — Lógica de negocio fuera de widgets

- [ ] Implementar `lib/utils/mystery_utils.dart` (o `MysteryForWeekday` según diseño).
- [ ] Reducir `HomeScreen` a: leer resultado de la utilidad / provider y pintar.

### Fase 6 — Estado global (opcional pero alineado al análisis)

- [ ] Elegir stack: **Provider** (simple), **Riverpod** (testeable), **Bloc** (eventos explícitos).
- [ ] Crear `mystery_provider` / `rosary_provider` según necesidad real (no antes de necesitarlo).
- [ ] Registrar en `main.dart` o en el árbol bajo `MaterialApp`.

### Fase 7 — Limpieza y datos

- [ ] Eliminar código comentado muerto (transiciones, bloques viejos).
- [ ] Resolver o documentar TODOs en `data.dart` y en el painter (medalla / inicio del rosario).
- [ ] Valorar partir `data.dart` en varios archivos bajo `lib/data/models/` (sin romper exports de un día).

### Fase 8 — CalendarScreen

- [ ] Definir alcance: recordatorio diario, solo UI de prueba, o eliminar entrada desde home.
- [ ] Implementar o quitar navegación según decisión.

### Fase 9 — Calidad y dependencias

- [ ] `flutter analyze` sin warnings nuevos en archivos tocados.
- [ ] Revisar `flutter pub outdated`; actualizar dependencias de a una con prueba manual.
- [ ] Añadir tests unitarios donde haya lógica pura (utils, mapeo día–misterio, parsing simple).

---

## Mapa rápido: análisis → archivo / carpeta

| Recomendación del análisis | Destino sugerido |
|----------------------------|------------------|
| CustomPainter separado | `lib/presentations/widgets/rosary_painter.dart` |
| Constantes | `lib/constants/app_constants.dart` |
| Audio | `lib/services/audio_service.dart` |
| Preferencias | `lib/services/preferences_service.dart` |
| Día / misterios | `lib/utils/mystery_utils.dart` |
| Estado compartido | `lib/providers/` o `lib/bloc/` |
| Modelos partidos | `lib/data/models/*.dart` |

---

## Referencia

- Análisis detallado: [analisis-estructura-proyecto.md](./analisis-estructura-proyecto.md)

---

*Última actualización: generado a partir del análisis de estructura del proyecto Santo Rosario.*
