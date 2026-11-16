# Emberfall

Roguelike de supervivencia 2D vertical (390 × 844) hecho en Godot 4.7, para Android. Gratis, con compras opcionales y anuncios recompensados. Español e inglés.

## Ejecutar

1. Abrir `project.godot` en Godot 4.7.
2. Ejecutar el proyecto (escena raíz `MainLayout`).
3. En escritorio se mueve con las flechas; en el teléfono, con un joystick que aparece donde se toca la pantalla.

En escritorio la tienda funciona en modo simulado: las compras y los anuncios se completan solos y muestran el prefijo `[simulada]`.

## Pruebas

Las dos se ejecutan sin abrir el editor y devuelven código 0 si todo está bien. Ninguna altera el progreso guardado.

```
godot --headless --path . --script tools/run_tests.gd
godot --headless --path . --script tools/check_translations.gd
```

- `run_tests.gd`: energía, catálogo y entregas de la tienda, anuncios de un solo uso, misiones y puntos de actividad, mejoras permanentes, idioma y partidas guardadas (guardar, salir, reanudar, subida de nivel y jefe pendientes, derrota y abandono sin premio doble, instantáneas dañadas).
- `check_translations.gd`: recorre todas las pantallas en inglés y lista los textos que quedaron sin traducir.

Lo que no cubren: el combate en sí, las compras y los anuncios reales (solo se pueden probar en un teléfono con el juego subido a Play) y el rendimiento.

## Generar la versión para Google Play

```
powershell -ExecutionPolicy Bypass -File tools\build_release.ps1 -VersionCode 2
```

Produce `build/android/Emberfall.aab` firmado. La clave de firma vive fuera del repositorio (`%USERPROFILE%\.emberfall\`) y la contraseña se escribe en el momento; nunca se guarda en el proyecto. Google Play exige un `VersionCode` mayor en cada envío. La clave se crea una sola vez con `tools\create_release_keystore.ps1`.

Requiere la plantilla de compilación de Android (`Proyecto > Instalar plantilla de compilación de Android`), JDK 21 y el SDK de Android.

## Arquitectura

- `scripts/MainLayout.gd`: controlador raíz. Mantiene la barra superior y el pie de navegación, y cambia de pantalla con `navigate_to(route_id)` y de modal con `open_modal(id)`.
- Autoloads (`scripts/systems/`):
  - `GameState`: todo el estado persistente (energía, oro, gemas, héroes, equipo, misiones, campaña, ajustes). Guarda en `user://emberfall_save.json` con escritura atómica y respaldo. Ahí vive también la partida en curso (`active_run`), para poder cerrar el juego y reanudarla desde Inicio.
  - `Monetization`: compras (Google Play Billing) y anuncios recompensados (AdMob) con el formulario de consentimiento de Google. Las pantallas solo llaman a `buy()` y `show_rewarded()`.
  - `Localization`: idioma del juego.
  - `MusicDirector` y `SfxPlayer`: música por contexto y efectos.
- `scripts/game_world.gd`: el bucle de una partida (enemigos, experiencia, habilidades, jefe). `scripts/ui.gd` dibuja su HUD, la subida de nivel y la pausa.
- Partidas guardadas: `game_world.capture_snapshot()` describe la partida con datos simples (sin nodos) y `GameState` la escribe junto con el perfil en cada guardado: al pausar, al perder el foco, al subir de nivel, al aparecer el jefe y cada 20 s de juego. Reanudar no cobra energía ni repite el arma inicial; la partida vuelve en pausa (o en la misma elección de nivel). Los disparos y avisos que estaban en el aire no se guardan. Al ganar, perder o abandonar, la partida se borra en la misma escritura que entrega las recompensas. `scripts/systems/run_snapshot.gd` lee los valores con tolerancia a datos dañados.
- `scripts/components/`: jugador, enemigos, proyectiles y efectos visuales.
- `scripts/data/`: catálogos de habilidades, equipo, mejoras, bestiario y héroes. Los héroes se definen en `resources/characters/*.tres`.
- `scripts/ui/`: pantallas y modales, construidos por código con el tema de `UiTheme.gd`.
- `assets/`: ordenados por tema; el detalle está en `assets/README.md`.

### Idiomas

El juego está escrito en español: los textos del código son la fuente. El inglés sale de `scripts/data/translations_en.gd`, una tabla español → inglés que Godot consulta sola cada vez que un `Label` o `Button` muestra un texto, así que las pantallas no llaman a `tr()`.

- Para un texto nuevo: escribirlo en español en el código y agregar su línea a la tabla. `check_translations.gd` avisa si falta.
- Los textos con partes variables usan la misma plantilla que el código: `"NIVEL %d": "LEVEL %d"`.
- El texto dibujado a mano con `draw_string()` sí tiene que pasar por `Localization.t()`.
- El idioma se elige en Configuración (automático, español o inglés). En automático, los dispositivos en español ven el original y el resto ve inglés.

### Tienda

Los paquetes están en `COIN_OFFERS` y `ENERGY_OFFERS` de `GameState`. El `id` de cada paquete de pago es el identificador del producto en Play Console. El precio que ve el jugador es el que devuelve Google en su moneda; el del catálogo solo se muestra mientras no hay conexión con la tienda.

| Producto | Contenido | Precio de referencia |
|---|---|---|
| `recarga_oro_baja` | 500 monedas (la primera vez, con anuncio) | USD 0,99 |
| `recarga_oro_media` | 1.200 monedas | USD 1,99 |
| `bolsa_oro_media` | 3.200 monedas | USD 4,99 |
| `cofre_oro_medio` | 7.000 monedas | USD 9,99 |
| `cofre_oro_grande` | 15.000 monedas | USD 19,99 |
| `recarga_energia_media` | 60 de energía (la primera vez, con anuncio) | USD 0,99 |
| `recarga_energia_grande` | 150 de energía | USD 1,99 |

## Contenido

- 14 héroes con animaciones y arma propias. Cada arma se desbloquea para todos con un desafío y tiene su evolución.
- 12 habilidades activas y 12 pasivas, 6 espacios de cada una, nivel máximo 5 y una evolución por activa.
- Campaña de 10 etapas y 3 mazmorras con modificadores, 3 jefes, élites, hordas y un mini-jefe.
- Equipo: 6 espacios, 24 objetos, 6 rarezas, 3 sets con bonus, forja y fusión.
- 22 mejoras permanentes, misiones diarias y semanales con cofres de actividad, Códex y bestiario.
- Configuración: música, efectos, vibración, menos movimiento, tamaño del joystick e idioma. Créditos, licencias y política de privacidad.

## Documentación

- `docs/tienda/ficha_google_play.md`: textos de la ficha, formularios de Play Console y lista de pendientes para publicar.
- `docs/legal/`: política de privacidad (publicada en https://ze7aro.github.io/emberfall-privacy/).
- `docs/PLAN_FINALIZACION.md`: plan de arte y contenido.

## Pendiente antes de publicar

- Probar en un teléfono real: rendimiento, controles, compras y anuncios.
- Unidad de anuncio recompensado real en `Monetization.REWARDED_UNIT` (hoy usa la de prueba de Google).
- Crear los productos de la tabla en Play Console.
- Gráfico destacado y capturas para la ficha.
