# Lista de comprobaciones: audio de oraciones y avance automático

Úsala como checklist manual (dispositivo o emulador). Marca ✅ / ❌ y anota modelo de dispositivo y build (debug/release) si algo falla.

**Comportamiento esperado por defecto** (salvo donde se indica lo contrario):

- Tras reproducir **hasta el final** un audio de oración estando **`_isplaying`** y audio de oraciones **activado**, la app debe **avanzar a la siguiente oración** y **arrancar su audio solo**, sin pulsar «siguiente».
- Al **pausar** el reproductor principal durante una oración, **no** debe avanzarse la oración al reanudar por el solo hecho de reproducir/stop sin un fin natural de archivo (salvo comportamiento específico documentado).
- Cambiar solo el **orden de la oración dentro de la misma cuenta** debe seguir cargando el **clip correcto** para esa cuenta y ese índice.

---

## 1. Configuración previa en cada serie de pruebas

| # | Comprobación | OK |
|---|----------------|-----|
| 1.1 | Pantalla siempre encendida / permisos: no bloquear el test | ☐ |
| 1.2 | Volumen del dispositivo > 0; silenciar no confundido con bug | ☐ |
| 1.3 | Probar al menos una vez **debug** y una vez **release** (opcional pero recomendado) | ☐ |

---

## 2. Una sola cuenta con varias oraciones (retrocesos de texto)

Casos donde cambia **`_orderPrayer`** pero **no** el contador **`_counter`** (misma cuenta en el rosario).

| # | Escenario | Pasos | Esperado |
|---|-----------|--------|----------|
| 2.1 | Primera oración → segunda | Encender play; dejar reproducir primera oración hasta el silencio / fin evidente | Pasa solo a segunda oración **y se oye la segunda**. |
| 2.2 | Segunda → tercera | Sin tocar siguiente | Igual cadena hasta la última oración de esa cuenta. |
| 2.n | Antepenúltima → última de la cuenta | Idem | Sin corte audible de la penúltima; sin pasar dos oraciones seguidas. |
| 2.last | Ultima oración → siguiente **cuenta** | Dejar reproducir hasta el final la última oración del bloque | Debe **`_counter`** avanzar (nueva cuenta) y **`_orderPrayer`** volver coherentemente según modelo de datos — audio de la nueva primera oración debe arrancar si el modo automático está activo. |

**Qué observar si falla:** salta una oración; repite la misma; silencio hasta pulsar siguiente; cortes al cargar nueva pista; banner de error de audio.

---

## 3. Primera entrada en la pantalla de rezo

| # | Escenario | Pasos | Esperado |
|---|-----------|--------|----------|
| 3.1 | Arranque en primera oración del rosario elegido | Abrir desde elección de misterio; dar play cuando las imágenes ya carguen | Solo el primer clip (o comportamiento estable si no hay play automático hasta pulsar — lo que defináis como UX). |
| 3.2 | Restaurar avance guardado (si aplicáis snapshot) | Cerrar app con progreso a mitad cuenta; volver a entrar | Restaura índices; al dar play parte del clip correcto; avance hasta fin funciona igual que 2.* |

---

## 4. Pausa, play y audio ON/OFF

| # | Escenario | Pasos | Esperado |
|---|-----------|--------|----------|
| 4.1 | Pausar a mitad de oración | Pausar; reanudar | Continúa misma oración; **no** salta índice. |
| 4.2 | Audio de oraciones desactivado desde menú | Desactivar; reactivar en misma cuenta | Primera pulsación después de activar debe cargar clip actual sin doble disparo audible. |
| 4.3 | Pantalla pause global | Pausar toda sesión tras fin de archivo | Solo avanza en fin natural cuando play está ON (no debe avanzar con player parado ficticio). |

---

## 5. Música de fondo y «Señal de la cruz»

| # | Escenario | Pasos | Esperado |
|---|-----------|--------|----------|
| 5.1 | Gloria / oración inicial con retraso largo | Música de fondo activa desde el primer uso | Si existe retardo especial para cierto asset (`delayMusic`), debe ser **solo** ese clip — no otros. |
| 5.2 | Sin música de fondo | Desactivar Ave María fondo donde aplique | Oraciones siguientes sin retardos fantasmas. |

---

## 6. Navegación manual vs automática

| # | Escenario | Pasos | Esperado |
|---|-----------|--------|----------|
| 6.1 | Flecha «siguiente» durante reproducción | Pulsar siguiente a mitad de audio | Nueva oración cargada sin crasheo; siguiente avance puede ser manual o reinicio de clip según modelo. |
| 6.2 | Solo automático después de último siguiente manual | Varios Manuales; luego dejar reproducir hasta fin natural | Siguientes pasos siguen cadena automática sin quedar bloqueado. |
| 6.3 | Retroceso de oración (si existe) | Volver atrás dentro de cuenta | Índices y archivo coherente; siguiente play no debe “saltarse” índices. |

---

## 7. Misterios / saltos entre décadas / botón misterio (si están en uso)

| # | Escenario | Pasos | Esperado |
|---|-----------|--------|----------|
| 7.1 | Etiqueta «Misterio» y audio específico | Llegar a oración etiquetada Misterio | Reproduce recurso **`mysterio+N`** esperado (`Data.prayersSounds`), no archivo genérico equivocado. |
| 7.2 | Cambio visual de número de misterio (pastilla/UI) | Comprobar después de navegar década | Etiquetas alineadas con `_orderMystery` / lógica de pastilla (`_mysteryGlassLabel*` en código). |

---

## 8. Errores, interrupciones y sistema

| # | Escenario | Pasos | Esperado |
|---|-----------|--------|----------|
| 8.1 | Cortar sesión audio (Bluetooth, llamada entrante si aplica) | Simular pérdida de foco/audio | Mensaje esperado (`PlayerInterrupted` / esperado por `_isExpectedAudioInterruption`), sin estado bloqueante que impida volver a play. |
| 8.2 | Asset corrupto/faltante (solo entorno desarrollo) | Forzar nombre erróneo en branch de prueba | Error reportado pero app no queda sin avanzar todas las siguientes oraciones después de cerrar/error. |

---

## 9. Regresiones típicas a vigilar (del análisis histórico)

Anotar **sí/no** después de cada build relevante:

- [ ] **Doble paso**: al terminar oración **N**, pasa solo a **N+1**, no **N+2**.
- [ ] **Sin avanzar solo**: termina oración pero no arranca siguiente hasta flecha siguiente.
- [ ] **`Connection aborted` / errores redundantes en email** sólo ante fallos reales de carga/red.
- [ ] **`_audioRequestId`**: pulsaciones rápidas en play/pistas no colapsan siguiente oración incorrecta.

---

## 10. Datos útiles cuando reportes un fallo

Copiar/pegar cuando abras issue o cuando depures:

- Versión Flutter / modelo / Android o iOS.
- Debug vs release.
- Secuencia mínima: «Desde cuenta X oración Y, dejé reproducir hasta el final…».
- Si aparece banner/snackbar/email de error, texto técnico (si lo hubiera).
