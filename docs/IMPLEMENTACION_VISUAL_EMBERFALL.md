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

## Etapa 8 — Layouts acercados a las referencias (solo nodos y estilos)
Criterios: sin imágenes recortadas, sin sistemas ni datos nuevos, footer de 5 opciones, HUD de 2 filas (160 px).
- Componentes nuevos en `UiTheme`: `header(título, subtítulo)` y `section_title(texto, nota)`.
- Footer: etiquetas de texto bajo cada icono (Tienda, Misiones, Inicio, Progreso, Mazmorras) con color de estado activo/inactivo.
- Inicio (`01_inicio`): título EMBERFALL + lema, panel de datos del mapa con "Costo de energía" (`GameState.ENERGY_COST`), botón COMENZAR AVENTURA. Sin Temporada, Eventos ni atajos.
- Mazmorras (`05_mazmorras`): cabecera MAZMORRAS + lema, panel de recompensas/energía/modificador, botón ENTRAR. Siguen siendo 3 mazmorras en carrusel.
- Tienda (`02_tienda`): cabecera, secciones con línea y nota, etiqueta GRATIS en ofertas gratuitas. Precios y cantidades reales.
- Misiones (`04_misiones`): cabecera, pestañas con el temporizador de reinicio a la derecha, panel "Recompensa por actividad" al pie. Solo oro y gemas.
- Progreso (`03_mejoras`, `15_seleccion…`): cabecera PROGRESO que ocupa el área entre HUD y footer; ramas con "NV. n/10"; en Personajes: cabecera EQUIPAMIENTO, héroe en marco, panel ATQ/VIDA y MOCHILA enmarcada.
- Perfil (`06_perfil`): cabecera, "x / y" de experiencia y fichas de Oro, Joyas y Récord (datos reales). Sin clan, ID, logros ni rango.
- Configuración (`11_configuracion_simple`): cabecera + sección AUDIO (solo música y efectos).
- Poderes (`13_poderes`): cabecera ELIGE UN PODER / TU LEYENDA EVOLUCIONA; cada opción en su tarjeta con descripción.
- Pausa (`14_pausa`): título EN PAUSA + lema; REANUDAR y SALIR.
- Victoria/Derrota (`08`, `09`): frase de cabecera, panel con datos reales, botones VOLVER A INICIO y REINTENTAR (con coste de energía) lado a lado.
- No aplicado a propósito: HUD en una sola fila con avatar/nombre/botones "+", footer de 7 botones, 4 ramas y panel de detalle de mejoras, logros/rango/marcos, sliders y idioma, XP/llaves en misiones, "Siguiente mazmorra".
- Verificación: capturas reales a 390×844 de todas las pantallas y modales; footer, modales del HUD y notificaciones re-probados por script. Pendiente manual: partida real, pausa/temporizadores, equipar, audio, móvil.

### Ajustes posteriores (Etapa 8)
- Tienda y Misiones: se quitaron los botones de cerrar (✕); se navega con el footer.
- Mochila: la cuadrícula de 4 columnas queda centrada dentro de su marco.
- Footer/HUD en escritorio: `_safe_area_bottom_inset` (footer) y `_safe_area_top_inset` (HUD) calculaban la diferencia pantalla vs área útil, que en Windows es la barra de tareas y no un inset real. Ahora devuelven 0 fuera de móvil (`OS.has_feature("mobile")`); en móvil siguen igual. Verificado con captura: footer 116 px y el marco de la mochila se ve completo.

## Etapa 9 — Preparación del kit gráfico (híbrido)
- Directorios creados (con `.gitkeep`): `assets/ui/kit/{panels,buttons,progress,slots}`, `assets/ui/icons`, `assets/ui/headers`, `assets/ui/backgrounds`. No se movió ni eliminó ningún recurso.
- `UiTheme`: nueva tabla `KIT` y `UiTheme.kit(id, fallback)` (StyleBoxTexture de nueve cortes si el archivo existe, si no el estilo plano). `make_theme()` y `apply_primary()` la usan; los estilos explícitos por pantalla siguen planos hasta la segunda pasada.
- Inventario de recursos: `docs/RECURSOS_UI_PENDIENTES.md`.
- Validación: proyecto abre sin errores; footer de 5 opciones y modales de Perfil/Configuración intactos (prueba por script); con placeholders temporales (ya eliminados) el tema devolvió StyleBoxTexture para panel y botón primario y cayó al estilo plano donde faltaba el arte, en una pantalla de prueba con capturas.

## Etapa 10 — Integración del UI_KIT_01
Ver la sección "Entrega UI_KIT_01" de `docs/RECURSOS_UI_PENDIENTES.md`. Integrado: paneles (tema, modales, tarjetas de tienda/misiones, mochila), ranura vacía de equipo, iconos de HUD/tienda/equipamiento y badge de notificación del footer. Bloqueado por arte con texto/contenido dibujado: botones, barras, marcos de héroe, ranuras con objeto. Validado con capturas a 390×844; footer de 5 opciones, HUD de 160 px y guardado sin cambios.

## Etapa 11 — Integración de UI_KIT_03, cabeceras y fondos
- `UiTheme`: botones secundarios (tema) y primarios (`apply_primary`) con `UI_KIT_03` (nueve cortes 28/20); `apply_secondary`, `apply_primary_flat` (para botones < 44 px, donde el arte se deforma); `style_bar` (barras del kit solo si miden ≥ 30 px: Carga y experiencia del Perfil; relleno recortado del interior de `barra_progreso_relleno`); `header(..., banner)` con cabecera ilustrada y título encima; `background(archivo, velo)` con fondo ilustrado y velo oscuro.
- Cabeceras: Inicio, Mazmorras, Tienda, Misiones, Progreso (`mejoras_header`) y Perfil.
- Fondos: Inicio, Mazmorras, Tienda, Misiones, Progreso, Victoria, Derrota y Carga.
- Pestañas de Misiones con botones del kit (activa primaria, inactiva secundaria).
- Sin cambios funcionales. Probado: 5 rutas del footer, modales del HUD y notificaciones, HUD 160 px, footer 116 px, guardado idéntico; capturas de todas las pantallas, poderes, pausa, victoria y derrota.
- No integrado (el arte no encaja o trae elementos dibujados): `marco_top_hud_*` (cresta de calavera central y un rótulo "MARCO DEL TOP HUD" dibujado en la esquina), `marco_footer` (cinco arcos y calavera dibujados para un ancho de 905 px), `marco_heroe`, `marco_panel_*` (forma de arco), ranuras de UI_KIT_03 (164×146, más grandes que las ranuras de 64 px; se mantiene UI_KIT_01), pestañas del TabContainer (el arte se deforma; se mantiene el estilo plano), botones de tienda pequeños y opciones de poder (estilo plano). Pendiente: fondo de Héroes/Pausa/Perfil, `UI_KIT_04` (hojas sin recortar).

## Etapa 12 — Integración de UI_KIT_HIGH_PRIORITY y UI_KIT_05
- Top HUD (`TopHud.gd`, `_build_kit`): `top_hud_frame` como fondo y cuatro placas del kit (`hud_resource_xp/energy/coin/gem`, con el icono dibujado en el arte) con los valores a la derecha: nivel y XP (la placa sigue abriendo Perfil), energía con barra fina y cuenta atrás, oro y joyas. Botones de ajustes y correo (`icono_correo`) debajo. Mismas señales y setters; si falta el arte se usa la versión plana anterior. Altura 160 px.
- Footer (`NavigationFooter.gd`): `footer_frame` (cinco arcos) como fondo y `footer_btn_selected` como resalte de la opción activa; 5 opciones, orden, rutas e indicador de misiones sin cambios. Altura 120 px (antes 116; las pantallas reservan ≥ 120).
- Ranuras de equipo: bordes de rareza `rareza_comun/raro/epico` (UI_KIT_05). Tarjetas del carrusel de héroes: `tarjeta_heroe_normal/seleccionada`.
- Carga: logo `logo_emberfall` en lugar del texto.
- Los archivos `top_hud_frame`, `footer_frame` y `footer_btn*` traen dibujado el nombre del archivo debajo del arte; `UiTheme.clean_texture` lo borra en tiempo de ejecución (sin tocar el archivo).
- Probado: 5 rutas del footer, modales del HUD, notificaciones, HUD 160 px, guardado idéntico; capturas de Progreso (equipamiento y selección de héroe), Misiones, Tienda, Configuración y Carga.
- No usado: `fondo_vertical_*` de UI_KIT_05 (112×325, con marco dibujado y menor resolución que los fondos anteriores), `fondo_horizontal_*`, `cabecera_pausa*` (fondo opaco / versión de vista previa), `cabecera_configuracion` (probada; con el título encima se ve recargada en el modal), `barra_fina_*`, `marco_heroe_*`, `hud_btn_*`, `hud_slot_*`, iconos `icon_*` del kit prioritario y `ranura_*` de UI_KIT_05.

## Etapa 13 — UI_KIT_04 (solo lo necesario)
- Revisadas las 98 piezas (adornos, banderas, divisores, efectos, indicadores, iconos de estado, listas/switches, marcadores, selectores, tags, ventanas, punteros). Importadas en Godot.
- Usadas: `lista_switch_on/off` como interruptor de los `CheckButton` (Configuración: música y efectos) y `flechas_navegacion_izq/der` en las flechas del selector de mapas (Inicio y Mazmorras). Recortadas al contenido y escaladas en tiempo de ejecución (`UiTheme.scaled_texture`).
- No usadas (el juego no tiene la funcionalidad o ya está cubierta): iconos de estado (veneno, fuego, hielo…; no hay UI de estados), tags de rareza, etiquetas, banderas, punteros, efectos, ventanas y marcadores, divisores y adornos (posibles usos decorativos futuros).

## Etapa 14 — HUD compacto, botón de inicio y acceso lateral a Misiones
- Top HUD (`TopHud.gd`, reescrito): una sola fila de 68 px como en la referencia: nivel/XP (abre Perfil), energía, oro, joyas, correo y engranaje. Los "+" de energía, oro y joyas emiten `shop_pressed`, que `MainLayout` conecta a `navigate_to(&"shop")` (sin lógica de compra nueva). Se quitó la barra de energía y el texto "PRÓXIMA:"; la cuenta atrás sigue visible. Constantes `UiTheme.HUD_HEIGHT` (68) y `UiTheme.CONTENT_TOP` (76) usadas por Tienda, Misiones, Progreso e Inicio/Mazmorras.
- Inicio: se quitó la línea de recompensas; el botón COMENZAR AVENTURA es ancho, con subtítulo "Explora, lucha, progresa" y chevron (`MapSelection.start_subtitle`, `show_rewards`). Mazmorras conserva sus recompensas y el botón ENTRAR.
- Acceso flotante a Misiones a la izquierda de Inicio (`HomeScreen._build_missions_side`), con el indicador de "algo por reclamar". El footer sigue con sus 5 opciones. No se agregaron "Recompensas" ni "Eventos" (no existen).
- Probado: capturas de Inicio, Tienda, Misiones, Progreso; rutas del footer y modales; guardado sin cambios.

## Etapa 15 — Arte de Tienda (UI_KIT_05) y limpieza de Inicio
- Inicio: se quitó el panel "Costo de energía" (el panel completo se oculta cuando no hay recompensas ni modificador; Mazmorras lo conserva).
- Tienda (`ShopScreen.gd`): iconos por posición de oferta: monedas (`recarga_oro_gratis`, `recarga_oro_baja`, `bolsa_oro_media`, `cofre_oro_bajo/medio/grande`), energía (`recarga_energia_gratuita/media/grande`; solo hay 3 ofertas) y baúles (`baul_comun`, `baul_epico`). Precios, cantidades y lógica sin cambios. Quedan sin usar `marco_heroe_*`, `ranura_bloqueada/deshabilitada`, `rareza_poco_comun/raro` extra y `cabecera_pausa*`.

## Etapa 16 — Cantidades y costos de la Tienda según `02_tienda.png` (cambio de economía autorizado por el usuario)
- Monedas: 100 (gratis), 500, 1200, 2500 (antes 3000), 6500 (antes 6000), 14000 (antes 12000).
- Energía: +20 (gratis), +60 (antes 100), +120 (antes 250). La energía se limita a `MAX_ENERGY` (50).
- Baúles (gemas): Común 150 (antes 100), Épico 400 (antes 300).
- No cambiados: los costos en gemas de monedas y energía (50/120/250/500/1000 y 80/180). El boceto los muestra en USD (0,99 … 74,99, con 3,99 repetido); el juego no tiene compras con dinero real, así que no hay equivalente.

## Etapa 17 — Ofertas con USD y anuncio (solo interfaz)
- `GameState`: las ofertas con clave `"usd"` (monedas 500/1200/2500/6500/14000, energía +60/+120) tienen `cost` -1 y `buy_coin_offer`/`buy_energy_offer` las rechazan (no se pueden comprar con gemas). `"ad_first"` marca 500 monedas y +60 energía.
- `ShopScreen`: esas ofertas muestran `USD x,xx`; las marcadas `ad_first` muestran `VER ANUNCIO` hasta que exista la clave `ad_<tipo>_<índice>` en `claimed_free_offers`. Al tocarlas solo aparece "Próximamente": no se entrega nada. Punto de conexión: `ShopScreen._show_store_soon()`.
- Pendiente: integrar un SDK de pagos y de anuncios recompensados, y marcar `ad_*` al completar el anuncio. Precios USD del boceto (6500 repite 3,99).
- Probado: textos de botones, pulsar cada uno no cambia oro/gemas/energía, compra directa rechazada, guardado idéntico.

## Etapa 18 — Revisión del resto de referencias
Comparadas 01, 03, 04, 05, 08, 09, 13, 14 y 15 con las pantallas actuales.
- Selección de poderes (`13_poderes`): tarjetas lado a lado con icono, nombre, nivel y descripción (icono desde `assets/cuadros_habilidades_emberfall`; se omite si no existe); toda la tarjeta es el botón. Rerolls reales (`CAMBIAR OPCIONES`), sin coste en gemas.
- Árbol de mejoras (`03_mejoras`): iconos en los nodos (corazón, daño, movimiento). Se mantienen las 3 ramas × 10 niveles, sin panel de detalle ni "puntos destacados".
- Victoria/Derrota (`08`, `09`): tarjeta con el marco del kit (tinte rojizo en derrota).
- Sin aplicar a propósito (no existen en el juego): temporada, noticias, recompensas/eventos, XP y llaves en misiones, panel de actividad con 5 baúles, categorías de mejoras y de tienda, mazmorras con estrellas y enemigos, "Continuar/Configuración/Reiniciar" en la pausa, desglose de recompensas por partida, HUD de combate del boceto.
