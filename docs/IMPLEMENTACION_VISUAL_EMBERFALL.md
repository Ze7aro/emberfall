# Implementación visual de Emberfall

Criterios acordados: sin assets nuevos (solo `StyleBoxFlat`, colores e iconos existentes), fuente por defecto,
Footer con sus 5 opciones intactas, Perfil y Configuración como modales independientes abiertos desde el Top HUD,
sin atajos nuevos en Inicio, carga con progreso real (`load_threaded_request`).

## Etapa 1 — Auditoría (completada)
Inventario y contradicciones boceto/juego presentados en la conversación. Sin cambios de archivos.

## Etapa 2 — Componentes globales (completada, pendiente revisión visual manual)

### Top HUD
- Estado inicial: paneles `StyleBoxFlat` locales; sin acceso a Configuración; ✉ como botón plano.
- Referencia: `assets/referencias/01_inicio.png` (barra superior).
- Modificado: `scripts/ui/TopHud.gd` (estilos vía `UiTheme`, señal nueva `settings_pressed`, botón AJUSTES, ✉ con estilo de botón).
- Conservado: nivel/XP/energía/cuenta atrás/oro/gemas/notificaciones y todas sus conexiones; el botón de nivel abre Perfil; altura 160 px (verificada).

### Navigation Footer
- Modificado: `scripts/ui/NavigationFooter.gd` (solo estilos).
- Conservado: 5 entradas y orden (Tienda, Misiones, Inicio, Progreso, Mazmorras), rutas, selección, badge de misiones. Altura 116 px, igual que antes.

### Modales
- `scripts/ui/ProfileModal.gd`: ahora solo Perfil (se quitó la pestaña Ajustes; referencias por nodo reemplazadas por variables).
- Nuevos: `scripts/ui/SettingsModal.gd`, `scenes/ui/SettingsModal.tscn` (música y efectos, conectados a `GameState.set_music_enabled` / `set_effects_enabled`).
- `scripts/MainLayout.gd`: `settings_pressed` → `open_modal(&"settings")`; modal `settings` registrado.

### Recursos agregados
- `scripts/ui/UiTheme.gd`: paleta y estilos compartidos + `Theme` que solo aplican HUD, footer y modales (el resto de pantallas no cambia todavía).

### Pruebas (Godot 4.7.2 headless, script temporal, ya eliminado)
- Los 5 botones del Footer cambian a `shop, missions, home, upgrades, dungeons` con selección correcta.
- Perfil (`profile_pressed`) y Configuración (`settings_pressed`) abren su modal propio, sin cambiar la ruta actual; CERRAR (`closed`) cierra cada uno; Notificaciones sigue abriendo.
- Sin errores de script ni de carga.

### Pendiente de verificación manual
- Aspecto real (no hay captura headless): contraste, legibilidad del texto "AJUSTES", nitidez.
- Interruptores de música/efectos en el modal, cambiando audio en ejecución.
- Safe-area en dispositivo con notch.

### Problemas detectados (no corregidos)
- Fuga de 2 `ObjectDB` y 1 recurso al salir en headless (ya existía antes de los cambios).
- `UiTheme` ya no usa `class_name`: cada script lo carga con `preload`, así no depende de la caché de clases del editor (error "UiTheme not declared" con el editor abierto, corregido).

## Etapa 3 — Pantallas principales (implementada, pendiente revisión visual manual)

Enfoque: restilizar sobre `UiTheme` sin tocar lógica ni estructura. Cada pantalla aplica `UiTheme.make_theme()` en su raíz.

| Pantalla | Referencia | Scripts modificados | Cambio |
|---|---|---|---|
| Inicio y Mazmorras | `01_inicio`, `05_mazmorras` | `MapSelection.gd`, `DungeonSelectionScreen.gd` | Marco del preview, botón INICIAR primario turquesa, colores de tema. Sin atajos nuevos. Lógica de desbloqueo y `start_run` intacta. |
| Tienda | `02_tienda` | `ShopScreen.gd` | Paleta/tarjetas de tema; botones de compra/reclamo con estilo primario (los RECLAMADO quedan apagados). Precios y cantidades siguen viniendo de `GameState`. |
| Misiones | `04_misiones` | `MissionsScreen.gd` | Paleta y esquinas del tema. Solo se muestran oro/gemas reales; sin XP/llaves. |
| Progreso / Mejoras | `03_mejoras`, `15_seleccion…` | `PermanentUpgradesScreen.gd`, `UpgradeNode.gd`, `UiTheme.gd` (estilos de pestañas) | Fondo, pestañas y colores de tema. 3 ramas × 10 niveles y costes sin cambios. La pestaña PERSONAJES hereda el tema; su rediseño es Etapa 4. |
| Perfil | `06_perfil` | `ProfileModal.gd` (Etapa 2) | Modal independiente ya restilizado; solo muestra datos reales. |

### Pruebas (Godot 4.7.2 headless)
- Navegación a las 5 rutas sin errores de script.
- Tienda: 11 botones de compra con precios reales; reclamar la oferta gratis de monedas suma 100 de oro.
- Misiones: cambio entre DIARIAS y SEMANALES funciona.
- Mejoras: 30 nodos; comprar el disponible sube el nivel y descuenta oro.
- Inicio y Mazmorras: cargan; Mazmorras muestra BLOQUEADO con el progreso actual.

### Incidencia
- La prueba de la tienda/mejoras escribió en el guardado real (`%APPDATA%\Godot\app_userdata\Emberfall\emberfall_save.json`): oro 960, mejora de vida nivel 1 y `coin_0` reclamado. Antes de la prueba: oro 0, sin mejoras ni ofertas reclamadas. Pendiente de restaurar (requiere autorización del usuario).
- Las pruebas siguientes no ejecutarán acciones que guarden.

### Pendiente de verificación manual
- Aspecto visual de todas las pantallas (no hay captura headless), legibilidad y solapes con HUD/footer.
- Estados bloqueado/disponible/comprado de los nodos del árbol.

## Etapa 4 — Héroe, equipamiento e inventario (implementada, pendiente revisión visual manual)
- Estado inicial: pantalla integrada `CharacterEquipmentScreen` (estado EQUIPMENT + estado HERO_SELECTION en la misma escena, dentro de la pestaña PERSONAJES de la ruta `upgrades`).
- Referencia: `15_seleccion_personaje_+_inventario.png`. Se mantiene la estructura real (pestañas, 6 ranuras, mochila de 12, carrusel de 14 héroes); no se agregan ranuras, títulos ni nav propios del boceto.
- Scripts modificados (solo estilo): `CharacterEquipmentScreen.gd` (tema, colores, CAMBIAR HÉROE y SELECCIONAR con estilo primario), `EquipmentSlot.gd` (fondo/borde de tema, esquinas rectas; bordes de rareza intactos), `HeroCarouselCard.gd` (borde turquesa con brillo en la tarjeta central).
- Conservado: sprite y animaciones del héroe, lógica de equipar/desequipar, compra/desbloqueo de héroes, estados bloqueado/desbloqueado, estadísticas, tween de transición.
- Pruebas (headless, sin acciones que guarden; hash del guardado idéntico antes/después): 6 ranuras, 12 casillas de mochila, 14 tarjetas, sprite presente; CAMBIAR HÉROE entra en selección, siguiente héroe muestra "COMPRAR · 50 ORO", VOLVER regresa a equipamiento.
- No probado: equipar/desequipar y seleccionar/comprar héroe (escriben en el guardado); aspecto visual.
- Pendiente de diseño: marco de panel alrededor de la mochila (la estructura de tamaños vinculada lo hace frágil); no aplicado.

## Etapa 5 — Interfaces de combate (implementada, pendiente revisión visual manual)
- Referencias: `13_poderes`, `14_pausa`, `08_victoria_simple`, `09_derrota`.
- Scripts modificados: `scripts/ui.gd` (selección de poderes y pausa), `scripts/MainLayout.gd` (`_result_screen`, victoria/derrota).
- Poderes: panel con borde púrpura y tema; opciones con estilo primario; se mantienen nombres, descripciones, niveles X/6, rerolls reales (`CAMBIAR OPCIONES (n)`) y la pausa del combate. No se agregan tarjetas con iconos ni coste en gemas del boceto.
- Pausa: panel con tema; REANUDAR y SALIR (con confirmación) y la lista de fusiones. No se agregan Configuración ni Reiniciar (no existen).
- Nuevo: un bloqueador a pantalla completa detrás de los paneles de poderes y pausa que absorbe toques, para que el joystick no reaccione mientras están abiertos.
- Victoria/Derrota: tarjeta con borde turquesa (victoria) o rojo (derrota), título, nombre de la etapa si existe, oro total y récord (datos reales), REINTENTAR con el coste real (`GameState.ENERGY_COST`, 5) y VOLVER A INICIO. La lógica de reintento y energía en vivo no cambió.
- No se muestra desglose de recompensas por partida: `GameState` no guarda el pago de la última partida y agregarlo sería un sistema nuevo (pendiente de tu decisión). Tampoco "Siguiente mazmorra".
- Pruebas (headless, sin guardar; hash del guardado idéntico): pantallas de resultado con sus 2 botones; pausa con REANUDAR/SALIR y confirmación SÍ, SALIR/CANCELAR; el bloqueador aparece y desaparece con el panel; selección de poderes con 3 opciones + reroll y panel liberado al elegir/reanudar.
- No probado: partida completa real (inicia y guarda), congelación de temporizadores durante la pausa, aspecto visual.

## Etapa 6 — Configuración y Carga (implementada; el flujo real de "iniciar partida" NO se ejecutó)
- Configuración: ya es un modal independiente desde el Top HUD (Etapa 2), con tema de la Etapa 2. Solo música y efectos, conectados a `GameState`. Sin sliders, idioma ni cerrar sesión (no existen).
- Pantalla de carga: nuevo `scripts/ui/LoadingScreen.gd` (referencia `12_carga.png`): EMBERFALL, "CARGANDO...", barra y porcentaje.
  - Progreso real: `ResourceLoader.load_threaded_request` sobre recursos de la partida (`game_world.gd`, `ui.gd`, `player.gd`, `enemy.png`, `game_bg.png` y los 8 sprites del héroe seleccionado); la barra es el promedio de lo que informa `load_threaded_get_status`. Sin porcentajes simulados ni frase de consejos inventada.
  - Solo se hace visible si algo sigue cargando; si todo ya está en caché termina sin mostrarse.
  - Integración: `MainLayout.start_run` espera la señal `finished` antes de crear el mundo y la UI de combate (guardia `_starting_run` contra doble toque). Los sistemas de energía/etapa/guardado no se tocaron. `load()` posteriores usan la caché.
- Pruebas (headless, sin tocar el guardado): carga en frío 8 recursos → progreso 25→100 %, `finished` emitido, visible; carga en caché → `finished` en 1 ms, nunca visible. Proyecto sin errores de parseo.
- Corregido durante la prueba: la primera versión emitía `finished` dentro de `_ready` (se perdía si todo estaba en caché); ahora el primer sondeo ocurre en `_process`.
- No probado: `start_run` completo en una partida real (gasta energía y guarda); debe verificarse a mano que JUGAR entra al combate y que el reintento desde Victoria/Derrota también funciona.

## Etapa 7 — Validación integral
- Método: Godot 4.7.2 con ventana a 390×844, navegando por script y guardando capturas reales (sin acciones que guarden; el guardado no cambió durante las pruebas).
- Revisado en captura: Inicio, Tienda, Misiones, Progreso (Personajes y selección de héroe), Mazmorras (bloqueadas por progreso actual), modales de Perfil y Configuración, Notificaciones, Victoria y Derrota. HUD y footer sin solapes con el contenido; textos legibles; sin elementos cortados (las listas largas scrollean).
- Problema hallado y corregido: Inicio y Mazmorras mostraban el gris por defecto del motor → `MainLayout` añade un fondo común (`Backdrop`, `UiTheme.BG_DEEP`).
- Comprobado por script: 5 botones del footer y rutas; Perfil/Configuración desde el HUD; compra/reclamo, misiones, mejoras, selección de héroe, pausa, poderes, victoria/derrota, carga con progreso real. Arranque del proyecto completo sin errores de script (la comprobación aislada con `--check-only` por archivo falla con "GameState no encontrado" porque no carga los autoloads; es una limitación de esa herramienta, no un error del juego).
- Pendiente manual (requiere jugar y guardar): JUGAR → combate real y REINTENTAR; congelación de temporizadores en pausa; equipar/desequipar; compra de héroes; interruptores de audio; prueba en un móvil (safe-areas, tamaño táctil).
- Notas para el diseño (fuera de alcance): el footer no tiene etiquetas de texto; la tienda muestra textos de arte provisionales (COINS/BAG/CHEST) que ya existían.
- Problemas previos sin corregir: 2–4 objetos filtrados al salir en headless.
