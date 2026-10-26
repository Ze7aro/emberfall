# Plan de implementación de assets — Emberfall

Fecha: 24 de septiembre de 2026. Estado: implementación parcial; pendiente revisión visual integral y validación de todas las pantallas.

## Avance de implementación

La base compartida ya utiliza la paleta y los recursos de `pixel_simple_v1`. Se migraron el fondo y footer del layout, el HUD, barras, iconos y controles de pausa, además de los componentes principales de inicio, tienda, equipo, misiones, mejoras, mazmorras/mapas y corazones de partida. Se conserva la lógica de juego y las rutas de navegación. El 24 de septiembre se incorporó el set entregado en `assets/ui/emberfall_icons_transparent_2026-09-24/`: controles, avisos, recursos y productos de tienda se empaquetaron en sus rejillas nativas; la navegación previamente aprobada se conservó.

El empaquetador ahora respeta las piezas que ya están en su rejilla nativa, calcula los límites visibles píxel a píxel y el catálogo tiene más espacio para mostrar las barras. Las 20 piezas de `icons/` y `shop/` se armonizaron con `navigation/` y su procedencia local quedó registrada. El kit continúa en revisión: quedan recursos heredados `review_pending`, ventanas y pantallas secundarias por revisar, además de las capturas y pruebas de tamaños enumeradas abajo.

## Objetivo y alcance

Estandarizar la interfaz del juego con `assets/ui/pixel_simple_v1/`: fondos, paneles, botones, HUD, navegación, iconos, barras, tienda, equipo y ventanas. La implementación debe conservar señales, rutas, datos del jugador, precios, recompensas, reglas de combate y persistencia.

El kit es de interfaz. Personajes, enemigos, mapas, animaciones y efectos del mundo conservan sus recursos; su renovación artística requeriría otro alcance. Este documento define el trabajo futuro y no implica que las pantallas ya estén migradas.

## Situación observada

- `project.godot` arranca `scenes/MainLayout.tscn`, usa una vista de 390 × 844 y ya configura filtrado nearest.
- `scripts/ui/UiTheme.gd` concentra parte del estilo, pero mantiene una paleta verde y azul, estilos planos y referencias a kits anteriores. `kit_available()` devuelve siempre `false`.
- `scripts/MainLayout.gd` crea el fondo y carga los cinco iconos antiguos del footer directamente.
- `TopHud.gd` utiliza otro directorio de arte y `HudFillBar.gd` para las barras. Hay estilos y cargas locales en las pantallas que pueden prevalecer sobre el tema compartido.
- El kit exportado contiene 45 assets base, 15 estados de barras, tema y estilos. `integration.json` ofrece el mapa inicial de sustituciones.
- La preparación previa no equivale a aprobación visual completa: `prompts.json` conserva entradas `review_pending` y procedencias antiguas, mientras el estado global declara `complete`. Los 20 PNG recientes se construyeron mediante `tools/generate_pixel_ui_assets.py`; debe registrarse esa procedencia real.
- El render actual de `preview.png` recorta parte de las barras por el borde derecho. Debe corregirse el catálogo antes de usarlo como evidencia de aceptación.

## Reglas visuales y técnicas

1. Usar la paleta de `integration.json`: fondo #101321, interior #141827, piedra #55446e/#87739f, acento #42d8e8 y texto #ecedf4. Conservar colores semánticos de vida, experiencia, energía y rareza.
2. Mantener proporciones y nearest para sprites; preferir escalas enteras. No estirar iconos para llenar rectángulos.
3. Aplicar nueve segmentos a paneles, tarjetas y botones. El footer con cinco compartimentos requiere comprobar que las cinco áreas siguen alineadas; no tratarlo automáticamente como un panel genérico.
4. Separar tamaño del dibujo y área interactiva: controles táctiles de al menos 44 × 44 unidades de interfaz, aunque el icono mida 24 px.
5. Mantener cantidades, precios, nivel y porcentajes como texto dinámico. Evitar duplicar símbolos que ya existen dentro de un asset, como el botón `add`.
6. Usar pista y relleno independientes. El relleno debe recortarse de forma continua según el valor real, sin limitarse a los cinco PNG de referencia.
7. Centralizar rutas y estilos en la capa compartida. Duplicar los recursos compartidos antes de modificar márgenes o modulación para un control particular.
8. Las decoraciones no deben interceptar clics ni tapar etiquetas. Mantener foco visible, estados deshabilitados y áreas seguras.

## Fases y orden de ejecución

### 0. Revisar y conciliar el kit

Archivos: `assets/ui/pixel_simple_v1/prompts.json`, `manifest.json`, `integration.json`, `STATUS.md`, `README.md`, `tools/build_pixel_ui_kit.gd`, `scripts/ui/PixelUiKitCatalog.gd` y `tools/render_pixel_ui_catalog.gd`.

- [x] Conservar una copia de los assets y metadatos que se sustituyan. La entrega del 24 de septiembre se respalda en `artifacts/ui_assets_style_backup_2026-09-24/`.
- [ ] Revisar las 45 piezas sobre fondo oscuro y transparente, a tamaño lógico y ampliado con nearest.
- [ ] Contrastar las 20 piezas recientes con `PROMPTS_PENDIENTES.md`: dirección del chevrón, rombo de cuatro facetas, dos botas distinguibles, cofre en tres cuartos, borde de barra de 2 px y fondo sin marco visible con centro tranquilo.
- [ ] Registrar por pieza origen real, prompt aplicable, estado de revisión y defectos pendientes. No aprobar automáticamente por tener dimensiones correctas.
- [x] Revisar el empaquetador: preserva fuentes en rejilla nativa y calcula límites visibles píxel a píxel.
- [x] Ampliar el catálogo para mostrar mejor los recursos y las familias de barras.
- [ ] Resolver correspondencias semánticas: el mapa actual usa `character` para misiones e `inventory` para mejoras. Conservar rutas actuales y presentar cualquier cambio de símbolo que requiera decisión visual.
- [ ] Identificar controles sin asset específico —ajustes, interruptores, sliders, pestañas— y definir su estilo con recursos existentes; consultar antes de encargar arte nuevo o cambiar su significado.

Criterio de salida: catálogo completo, lista explícita de piezas aceptadas o pendientes y metadatos coherentes. Si una pieza exige interpretar detalles ambiguos del prompt, detener su implementación y consultar al usuario.

### 1. Crear la base visual compartida

Archivos: `scripts/ui/UiTheme.gd`, `assets/ui/pixel_simple_v1/pixel_theme.tres`, `styles/` y consumidores de `UiTheme`.

- [x] Adaptar `UiTheme` para centralizar el tema pixel, los estilos y los iconos principales.
- [x] Sustituir las referencias de tema compartido a kits antiguos y habilitar detección de recursos.
- [ ] Revisar firmas que devuelven `StyleBoxFlat` y consumidores que acceden a propiedades exclusivas de ese tipo antes de introducir `StyleBoxTexture`.
- [x] Migrar helpers de panel, ranura, tarjeta, botones primario/secundario y barras; completar revisión de cada estado visual durante QA.
- [ ] Revisar overrides de cada pantalla: aplicar el tema raíz por sí solo no los sustituye.
- [ ] Definir tamaños tipográficos por función conservando legibilidad móvil; no adoptar sin revisión los 12 px por defecto del tema exportado.

Criterio de salida: componentes compartidos consistentes y cargables, sin reactivar arte antiguo por fallback silencioso.

### 2. Migrar estructura, HUD y navegación

Archivos: `scripts/MainLayout.gd`, `scenes/MainLayout.tscn`, `scripts/ui/TopHud.gd`, `HudFillBar.gd`, `NavigationFooter.gd` y sus escenas.

- [x] Aplicar fondo común en el layout, respetando HUD y footer.
- [x] Sustituir marco, placa de nivel, recursos y barras del HUD con el kit.
- [x] Mantener relleno continuo y fuente de datos actual; queda probar visualmente valores extremos e intermedios. Energía conserva máximo 25.
- [x] Reemplazar los cinco iconos y marco del footer conservando rutas y señales; verificar visualmente selección a opacidad 0,5 en QA.
- [ ] Mantener regiones interactivas alineadas con cada compartimento y contenido sin solapamiento a 390 × 844.

Criterio de salida: navegación entre las cinco rutas, actualización de recursos y llenado continuo con presentación uniforme.

### 3. Migrar pantallas y componentes

| Área | Archivos principales bajo `scripts/ui/` | Sustituciones |
| --- | --- | --- |
| Inicio | `HomeScreen.gd`, `HeroCarouselCard.gd`, `HeartsRow.gd` | Paneles, tarjetas, acciones, avisos y corazón; conservar retratos y animaciones |
| Tienda | `ShopScreen.gd` | Arte de ofertas según `integration.json`, monedas, energía, cofres, precios dinámicos y estados de compra |
| Equipo | `CharacterEquipmentScreen.gd`, `EquipmentSlot.gd` | Seis iconos de equipo, ranuras, selección, bloqueo y rarezas |
| Misiones | `MissionsScreen.gd` | Paneles, progreso, recompensa y marca de reclamado |
| Mejoras | `PermanentUpgradesScreen.gd`, `UpgradeNode.gd` | Tarjetas, nodos, bloqueo, costes y selección |
| Mazmorras y mapas | `DungeonSelectionScreen.gd`, `MapSelection.gd` | Paneles, flechas, acción de entrada, requisitos y estados bloqueados |

- [x] Migrar componentes principales de inicio, tienda, equipo, misiones, mejoras y selección de mazmorras/mapas, usando helpers comunes.
- [ ] Eliminar sustitutos de iconos mediante emojis o caracteres decorativos cuando exista un recurso equivalente.
- [x] Mapear las ofertas por identificador estable, evitando depender de posiciones de arrays para elegir el dibujo.
- [ ] Conservar el contenido y la semántica de las acciones; no modificar balances ni condiciones de compra para facilitar una captura.

Criterio de salida por pantalla: vista normal, vacía, bloqueada y deshabilitada coherentes cuando correspondan, sin textos cortados ni acciones perdidas.

### 4. Migrar ventanas, carga e interfaz de partida

Archivos: `ProfileModal.gd`, `SettingsModal.gd`, `NotificationsModal.gd`, `LoadingScreen.gd`, `RuneBackdrop.gd` bajo `scripts/ui/`; revisar además `scripts/ui.gd` y `scripts/game_world.gd` para localizar los elementos activos durante la partida.

- [ ] Unificar paneles, cierre, botones, listas y controles de ventanas.
- [ ] Revisar fondos locales que oculten el fondo común o introduzcan otra dirección visual.
- [x] Aplicar iconos de vida, daño, velocidad, objetivo, pausa y reproducir donde coinciden con su función.
- [x] Migrar barras y controles principales del HUD de partida y pausa; ventanas, resultados y recompensas requieren revisión adicional.
- [x] Actualizar `TopHudAssetPreview.gd` para que use el kit vigente.

Criterio de salida: toda superficie de UI accesible usa el mismo lenguaje visual, también durante transiciones y partida.

### 5. Validación y entrega

- [ ] Ejecutar preparación en secuencia: empaquetar PNG → importar en Godot → generar tema → renderizar catálogo. No ejecutar importación y generación del tema simultáneamente.
- [ ] Comprobar errores de carga y referencias en las escenas migradas, además de la ausencia de texturas nulas.
- [ ] Revisar a 390 × 844, 360 × 800 y 430 × 932: contenido, scroll, áreas seguras, foco y legibilidad. Comprobar un tamaño de escritorio para detectar estiramientos.
- [ ] Capturar todas las pantallas principales y ventanas representativas, junto con las barras a 0/25/50/75/100 % y un valor no prefijado.
- [ ] Comprobar navegación, selección, cierre de ventanas, actualización del HUD, pausa y reanudación. Validar compras y recompensas sólo con datos de prueba recuperables.
- [ ] Buscar cargas activas de kits anteriores y overrides incompatibles; documentar cualquier excepción justificada.
- [ ] Revisar que paneles y botones mantengan esquinas mediante nueve segmentos y que el filtrado nearest se conserve en los controles.
- [ ] Actualizar manifiestos, documentación y ZIP únicamente con el estado realmente revisado. Guardar un paquete nuevo identificable, conservando el anterior hasta aceptar la migración.

Criterio final: todas las superficies inventariadas migradas, capturas completas, ausencia de errores de recursos y comportamiento de juego preservado. La existencia del ZIP o del tema por sí sola no cumple este criterio.

## Entregas y reversión

Orden: revisión del kit → tema compartido → layout/HUD/footer → pantallas → ventanas y partida → validación final. Registrar cada entrega por separado para que pueda revertirse sin afectar las demás ni cambios ajenos.

Conservar assets antiguos mientras existan consumidores. Retirarlos sólo después de revisar referencias y aceptar visualmente la migración; no incluir una limpieza masiva dentro del cambio de tema.

Las siguientes tareas son completar la revisión visual de piezas y pantallas, migrar ventanas secundarias y cerrar la validación en varios tamaños antes de considerar aceptada la migración.
