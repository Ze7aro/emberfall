# Emberfall — Plan de finalización

Fecha: 30 de octubre de 2026. Basado en la lectura del código y de los assets de `main` (`a027586`). No incluye una partida jugada ni pruebas en un dispositivo.

## 1. Diagnóstico rápido

El esqueleto del juego está completo: menú, metaprogresión, misiones, equipo, campaña de 10 escenarios, 5 arquetipos de enemigo, jefe con 3 patrones, audio y fusiones con efecto real. Lo que lo separa de un juego terminado es esto:

1. **El combate se ve como un prototipo.** Hay un solo sprite de enemigo (`assets/characters/enemy.png`) teñido de 5 colores. El suelo es un `ColorRect` plano. Los orbes, los proyectiles del jefe y los estados alterados son círculos dibujados con `draw_circle`.
2. **Hay arte terminado que no se usa.** Los 3 jefes de `assets/Emberfall_Jefes_Simplificados/` (Coloso Rúnico, Guardián Hueco y Matriarca de Ceniza) no se cargan en ningún lado: el jefe es `enemy.png` con tinte. Tampoco se usan en combate `assets/environment/game_bg.png`, `assets/fusions/*` ni `assets/powers/*`. Entre los iconos de `cuadros_habilidades_emberfall/` también hay varios sin usar: dash, revivir, rerolls, daño a jefes, probabilidad de oro/poción, experiencia ganada, invencible tras daño y velocidad de proyectil.
3. **El sistema de habilidades no obliga a decidir.** No hay límite de espacios: con suficiente nivel tenés todo. Las pasivas son en su mayoría +X% genéricos. Las fusiones piden dos activas a nivel 5, algo difícil de alcanzar con la alternancia activa/pasiva. Encima, tres activas (Ventisca, Bomba Venenosa y Congelamiento) no tienen icono, y Onda Orbital reutiliza el icono de Área.
4. **El jugador no ve su build.** El HUD solo muestra nivel, XP, corazones y tiempo. Las habilidades aparecen únicamente en la pausa, y solo como fusiones.

## 2. Nuevo sistema de habilidades

### 2.1 Referencias del género

| Juego | Patrón que vale la pena copiar |
|---|---|
| Vampire Survivors | Arma al nivel máximo + su pasiva emparejada = **evolución**. Casi cada pasiva existe para evolucionar un arma, así que toda elección importa. Hay 6 espacios de armas y 6 de pasivas. |
| Halls of Torment | Las habilidades secundarias salen de pergaminos que sueltan los élites. Las mejor valoradas son las auras (Radiant Aura), los orbes orbitales (Astronomer's Orbs) y los proyectiles automáticos (Arcane Splinters). |
| Brotato / 20 Minutes Till Dawn | Las pasivas cambian el comportamiento (rebote, perforación, quemadura en cadena), no solo un número. |
| Hades | Las bendiciones tienen elemento y estado propios, y las combinaciones dobles aparecen como cartas especiales. |

El conjunto de arquetipos que se repite en todos ellos es: proyectil dirigido, proyectil direccional, orbitales, aura, zona en el suelo, bumerán, latigazo o barrido, rayo en cadena, meteoro aleatorio, proyectil que rebota, invocación, escudo y nova.

### 2.2 Reglas propuestas

- **El ataque básico deja de ser una habilidad.** Hoy `directed` ocupa un espacio y es el ataque del héroe. Pasa a mejorarse solo con pasivas y con el equipo, y cada héroe conserva su sprite y su estado garantizado.
- **4 espacios de activas y 4 de pasivas.** Con 6 y 6 una partida de 12 minutos en el móvil no llega a llenarlos. Cuando los espacios están llenos, solo se ofrecen mejoras de lo que ya tenés.
- **Nivel máximo 5** para activas y pasivas (hoy es 6).
- **Evolución:** activa al nivel 5 + su pasiva emparejada (a cualquier nivel). En la siguiente subida, o al abrir un cofre de élite, aparece una carta dorada de evolución. La activa se transforma y libera su potencial.
- **Se quita la alternancia rígida activas/pasivas.** Cada subida ofrece 3 cartas mezcladas (4 con la mejora permanente "Suerte"), con más peso para lo que ya tenés.
- **Opciones en la subida de nivel:** Cambiar (ya existe), **Descartar** (la carta no vuelve en la partida) y **Saltar** (da un poco de oro o cura).
- **Los estados vienen de las armas.** Se eliminan las pasivas "probabilidad de veneno, quemadura y congelamiento". El fuego quema, el hielo congela, el veneno envenena y el rayo electrocuta (un nuevo estado: el siguiente golpe recibido hace +25 % de daño).

### 2.3 Activas (12)

| # | Nombre | Arquetipo (equivalente en el género) | Comportamiento | Mejora por nivel | Evolución (+ pasiva) |
|---|---|---|---|---|---|
| 1 | **Dagas Rúnicas** | Direccional (Knife) | Ráfaga rápida hacia donde mirás | +1 daga, +daño | **Tormenta de Filos** (+ Celeridad): sin enfriamiento y perforan |
| 2 | **Lunas Orbitales** *(ya existe)* | Orbital (King Bible) | Lunas que giran a tu alrededor | +1 luna, +radio | **Eclipse Eterno** (+ Duración): giran siempre y empujan a los enemigos |
| 3 | **Aura Ígnea** *(Fuego Constante)* | Aura (Garlic/Radiant) | Daño continuo cerca tuyo y quemadura | +radio, +daño | **Corona Solar** (+ Vitalidad): aura más grande y fuerte; cura medio corazón cada 6 s mientras quema |
| 4 | **Cadena Eléctrica** *(ya existe)* | Cadena | Rayo que salta entre enemigos y electrocuta | +1 salto | **Tormenta Viva** (+ Amplitud): saltos ilimitados en el radio |
| 5 | **Frasco Tóxico** *(Bomba Venenosa)* | Zona (Santa Water) | Charco venenoso | +tamaño, +duración | **Plaga Abisal** (+ Área): los charcos persiguen a los enemigos |
| 6 | **Ventisca** *(ya existe)* | Zona de control | Zona que ralentiza y congela | +radio | **Invierno Perpetuo** (+ Armadura): sigue al jugador y congela por completo |
| 7 | **Hacha Bumerán** | Bumerán (Cross/Axe) | Va y vuelve atravesando | +1 hacha | **Torbellino de Acero** (+ Fuerza): las hachas giran en espiral |
| 8 | **Tajo Sombrío** | Barrido (Whip) | Corte horizontal a ambos lados | +ancho, +daño | **Guadaña del Vacío** (+ Crítico): las bajas por crítico explotan |
| 9 | **Lluvia de Meteoros** | Impacto aleatorio (Meteor Strike) | Meteoros marcados en el suelo, daño en área | +1 meteoro | **Cataclismo** (+ Enfriamiento): un meteoro gigante cada 10 s |
| 10 | **Esquirla Errante** | Rebote (Runetracer) | Proyectil que rebota en los bordes de la pantalla | +rebotes | **Prisma Infinito** (+ Velocidad de proyectil): se divide en 3 al rebotar |
| 11 | **Familiar Espectral** | Invocación | Espíritu que dispara a su objetivo | +1 familiar | **Legión Espectral** (+ Magnetismo): +2 familiares, disparan el doble y +60 px de recolección |
| 12 | **Égida Rúnica** | Defensa | Escudo que bloquea un golpe cada X s | -enfriamiento | **Bastión** (+ Regeneración): al romperse lanza una nova que empuja |

La Explosión de Área actual pasa a ser la nova de Égida/Bastión y el estallido de Cataclismo. Así se conserva su arte (`explosion_area`).

### 2.4 Pasivas (12)

Todas tienen ya un icono en `assets/cuadros_habilidades_emberfall/`, salvo Armadura.

| Pasiva | Efecto por nivel | Icono existente | Evoluciona a |
|---|---|---|---|
| Fuerza | +10 % de daño | `daño.png` | Hacha Bumerán |
| Vitalidad | +1 corazón | `corazon_extra.png` | Aura Ígnea |
| Regeneración | +0,1 medio corazón/s | `corazon_extra_II.png` | Égida |
| Armadura | +8 % de probabilidad de bloquear un golpe | **falta** | Ventisca |
| Celeridad | +8 % de velocidad de ataque | `velocidad_de_ataque.png` | Dagas |
| Enfriamiento | -8 % de reutilización | `cooldown.png` | Meteoros |
| Área | +10 % de tamaño | `area.png` | Frasco Tóxico |
| Duración | +15 % de duración | `duracion.png` | Lunas |
| Amplitud (Cantidad) | +1 proyectil | `proyectiles.png` | Cadena |
| Velocidad de proyectil | +15 % | `velocidad_de_proyectil.png` | Esquirla |
| Crítico | +8 % de probabilidad y +20 % de daño | `probabilidad_de_critico.png` | Tajo |
| Magnetismo | +35 px de recolección | `area_recoleccion_experiencia.png` | Familiar |

Velocidad de movimiento, Perforación y Codicia salen del pool de la partida y pasan a ser mejoras permanentes (ver 4.2).

### 2.5 Fusiones

Las 5 fusiones actuales se reemplazan por las 12 evoluciones. Se pueden conservar 2 o 3 **uniones** raras de dos activas evolucionadas (por ejemplo Corona Solar + Tormenta Viva = "Sol del Trueno") como objetivo de final de partida. Ya existen iconos para eso en `assets/fusions/` (ash_sun, infinite_storm, broken_sky…).

## 3. Mejoras gráficas y visuales

| Prioridad | Mejora | Estado actual | Qué hacer |
|---|---|---|---|
| P1 | **Usar los 3 jefes** | El jefe es `enemy.png` teñido | Coloso (capítulo 1), Guardián (capítulo 2) y Matriarca (capítulo 3) con idle y 2 poses de ataque. Implementar los patrones de su README: barrido en arco, abanico de 3 runas, cono de fuego y zonas retardadas |
| P1 | **Enemigos propios por arquetipo** | 1 sprite, 5 tintes | 5 sprites con 2–3 frames de caminata. Variante de bioma más adelante |
| P1 | **Suelo de combate** | `ColorRect` + 2 elipses | Tileset de suelo repetible por bioma (3) y decorados dispersos. Mapa infinito con loseta que se repite, en lugar del límite de ±760 px |
| P1 | **Recolectables con sprite** | Círculos azules y dorados | Gemas de XP en 3 tamaños, moneda, cofre, poción, imán |
| P1 | **Barra de build en el HUD** | No existe | Fila de 4+4 iconos pequeños con el nivel, debajo de la XP |
| P2 | Feedback de impacto | Flash, número y temblor de 0,1 s | Retroceso de enemigos, pausa de impacto de 30 ms en críticos y jefes, parpadeo blanco, partículas de muerte |
| P2 | Muerte de enemigos | `queue_free` instantáneo | Desintegración de 3 frames o partículas de ceniza |
| P2 | Estados alterados | Círculo translúcido | Icono pequeño sobre el enemigo y partícula (llama, gota, cristal, chispa) |
| P2 | Proyectiles del jefe y tiradores | `draw_circle` rojo | Sprite de runa o bola de fuego con rastro |
| P2 | Telegrafiado del jefe | Línea y arco dibujados | Marca en el suelo con sprite (zona rúnica que se llena) |
| P2 | Héroe | Caminata y ataque | Frames de golpe recibido y de muerte. Sombra elíptica bajo todas las entidades |
| P3 | Iluminación | Ninguna | `CanvasModulate` oscuro con `PointLight2D` en el héroe, las auras y los proyectiles: encaja con la paleta violeta/turquesa |
| P3 | Viñeta y niebla de bioma | — | Shader de viñeta y partículas de ambiente (ceniza, nieve, esporas) |

## 4. Mejoras funcionales y funcionalidades que faltan

### 4.1 Dentro de la partida
- **Élites y cofres:** un élite cada 90–120 s, más grande, con aura y más vida. Suelta un cofre que da evolución o 1–3 mejoras, con animación de apertura (ya existe `chest_open.wav`).
- **Oleadas con eventos:** hordas en anillo, enjambres en fila y un mini-jefe a los 6 minutos. Hoy solo se acelera el intervalo de aparición.
- **Recolectables especiales:** poción (cura 1 corazón), imán (atrae toda la XP) y bomba (limpia la pantalla). El icono `probabilidad_de_pocion.png` ya existe.
- **Fusión de orbes de XP** cuando hay demasiados en pantalla (rendimiento y legibilidad).
- **Resultado detallado:** tiempo, bajas, nivel, daño por habilidad (ranking), oro ganado y próximo objetivo. Hoy es una tarjeta simple.
- **La pausa muestra la build completa** y las estadísticas finales, no solo las fusiones.
- **Rendimiento:** colisiones de proyectiles en O(n·m) con `duplicate()` por frame. Pasar a `Area2D` o a una rejilla espacial, y usar un pool de enemigos, orbes y números de daño.

### 4.2 Metaprogresión
- **Mejoras permanentes al estilo PowerUps de VS:** pasar de 3 ramas a una cuadrícula que use los iconos ya hechos: daño, vida, armadura, velocidad, área, enfriamiento, duración, cantidad, magnetismo, crecimiento de XP, codicia de oro, suerte, revivir, rerolls, descartes, daño a jefes e invencibilidad tras el daño.
- **Desbloqueo de habilidades:** empezar con 6 activas y desbloquear las otras 6 con logros ("Mata 500 enemigos con fuego" desbloquea Lluvia de Meteoros). Esto da objetivos de largo plazo.
- **Arma o pasiva inicial por héroe**, que sea su identidad: Vaelor empieza con Aura Ígnea, Azyren con Ventisca, Orven con Frasco Tóxico, Sylven con Esquirla, Theron con Égida y Mordrak con Tajo.
- **Bestiario y códex** de habilidades y evoluciones descubiertas: rejugabilidad barata.

### 4.3 Calidad y lanzamiento (pendiente del roadmap)
- Preset de exportación Android, botón Atrás, pausa al perder el foco y áreas seguras.
- Ajustes de vibración, reducción de temblor y destellos, y tamaño del joystick.
- El README está desactualizado: dice que no hay audio, y `SfxPlayer` y `MusicDirector` ya existen.
- El panel de subida de nivel tiene la posición fija `(20, 190)`: anclarlo para que se adapte a otras resoluciones.

## 5. Orden recomendado

1. **Habilidades** (sección 2): espacios, evoluciones, 5 activas nuevas y estados por arma. Es el núcleo de la rejugabilidad.
2. **Barra de build en el HUD y nueva carta de subida de nivel**, con iconos.
3. **Jefes con su sprite** y sus patrones (el arte ya está).
4. **Enemigos, suelo y recolectables** con el arte generado en la sección 6.
5. **Élites, cofres y eventos de oleada.**
6. **Feedback de impacto, muertes e iluminación.**
7. **Mejoras permanentes en cuadrícula y desbloqueos por logros.**
8. Resultado detallado, rendimiento y Android.

## 6. Prompts de generación

### 6.0 Bloque de estilo (pegarlo al inicio de cada prompt)

> Pixel art 2D, dark fantasy, top-down 3/4 view like Vampire Survivors / Halls of Torment. Limited palette: deep purples (#1a1028, #3b2457, #6b4a8f), dark slate (#17232a), glowing cyan/teal runes (#2de1d0, #7ff5ea), small accents of ember orange (#ff9f4a) only where the element is fire. Thick 1–2 px dark outline (#0d0816), crisp pixels, no anti-aliasing, no gradients, no text, no watermark. Fully transparent background (PNG alpha). Centered subject, consistent light from top-left.

Usar el sprite de Vaelor (`variante_01_baculo (Vaelor)/walk_right_00.png`) y el Coloso Rúnico como imágenes de referencia de estilo cuando la herramienta lo permita.

### 6.1 Iconos de habilidades (24 activas y evoluciones + 1 pasiva)

**Estado:** integrados las 12 activas, Armadura y 10 evoluciones. Faltan **Invierno Perpetuo** (`assets/habilidades_iconos/evo_invierno_perpetuo.png`) y **Legión Espectral** (`evo_legion_espectral.png`); mientras tanto usan el ícono de su activa.

**Dónde van:** `assets/habilidades_iconos/<id>.png` y `evo_<id>.png` (ids en `scripts/data/ability_catalog.gd`: daggers, orbital, fire, chain, poison_bomb, blizzard, boomerang, slash, meteor, shard, familiar, aegis, armor…). El juego los toma solos; mientras falten, usa el icono anterior o una ficha con la inicial.

Mismo marco que `cuadros_habilidades_emberfall/daño_critico.png`. Lo ideal es generar 1 icono por imagen o una lámina de 4×4 y recortarla con `tools/extract_icon_sheets.py`.

> [ESTILO] Square ability icon, 256×256. Ornate octagonal purple stone frame with small cyan gem studs at the corners and edges (same frame on every icon), dark navy inner background. Inside, a single bold readable symbol: **{SÍMBOLO}**. Symbol in glowing {COLOR} with 2–3 shades, readable at 48 px.

| Icono | {SÍMBOLO} | {COLOR} |
|---|---|---|
| Dagas Rúnicas | three thin rune-engraved daggers fanned out flying right | cyan |
| Lunas Orbitales | small crescent moons orbiting a central dot on an elliptical ring | pale cyan |
| Aura Ígnea | a ring of flames encircling a small figure silhouette | ember orange |
| Cadena Eléctrica | zig-zag lightning bolt connecting three dots | electric cyan |
| Frasco Tóxico | round glass flask with bubbling green liquid and skull mark | toxic green |
| Ventisca | swirling snowflake with wind streaks | icy white-blue |
| Hacha Bumerán | spinning double-bladed axe with curved return arrow | steel + cyan |
| Tajo Sombrío | wide horizontal crescent slash mark | violet |
| Lluvia de Meteoros | three falling flaming rocks with trails, diagonal | ember orange |
| Esquirla Errante | a crystal shard bouncing in a zig-zag between two walls | cyan-magenta |
| Familiar Espectral | small hooded ghost spirit with glowing eyes | pale teal |
| Égida Rúnica | round shield with a glowing rune in the center | cyan |
| Armadura (pasiva) | a chestplate with a rune rivet | steel grey + cyan |
| *Evoluciones* | la misma idea, con **marco dorado** (#e8b84a en lugar de las gemas cian), símbolo más grande y halo: Tormenta de Filos (anillo de dagas), Eclipse Eterno (eclipse negro con corona cian), Corona Solar (sol de fuego con corona), Tormenta Viva (nube de tormenta con 5 rayos), Plaga Abisal (calavera de veneno que gotea), Invierno Perpetuo (cristal de hielo con forma de corona), Torbellino de Acero (espiral de hachas), Guadaña del Vacío (guadaña violeta), Cataclismo (meteoro gigante partiendo el suelo), Prisma Infinito (prisma que divide un haz en 3), Legión Espectral (3 fantasmas), Bastión (escudo con nova expandiéndose) | — |

### 6.2 Enemigos (5 arquetipos × 3 frames de caminata)

**Dónde van:** `assets/enemigos/<arquetipo>/walk_00.png`, `walk_01.png`, `walk_02.png` (cuadros sueltos, fondo transparente, mismo tamaño y el personaje en la misma posición en los tres). Carpetas: `chaser`, `fast`, `tank`, `shooter`, `charger` y, opcional, `elite`. Si sale una tira de 3, guardala como `sheet.png` en la misma carpeta y la corto yo.

> [ESTILO] Sprite sheet, 3 frames in a single row, each frame 256×256, of a **{ENEMIGO}** walking toward the camera (slight 3/4 down view). Same character in every frame, only legs/arms shift for a walk cycle. Silhouette must read clearly at 56 px. Glowing cyan rune accents.

| Arquetipo | {ENEMIGO} |
|---|---|
| CHASER | hunched shadow ghoul made of dark stone with two glowing red eyes and cyan-crystal claws (evolution of the current enemy design) |
| FAST | small, thin, four-legged void imp with long ears and a trailing wisp tail, leaning forward |
| TANK | wide armored stone brute with a huge rune-inscribed shoulder slab, short legs, very heavy |
| SHOOTER | floating hooded cultist holding a small glowing orb, robes ending in smoke instead of legs |
| CHARGER | horned beetle-like beast with a battering-ram head and glowing orange cracks |
| ÉLITE (opcional) | same as CHASER but 1.5× bulkier, golden rune crown, purple flame aura |

Variantes de bioma: repetir el mismo prompt cambiando a "verdant moss and roots" (capítulo 2) o "ember cracks and ash" (capítulo 3).

### 6.3 Suelo y decorados (3 biomas)

**Dónde van:** `assets/suelo/cap1_criptas.png`, `cap2_cavernas.png` y `cap3_forja.png`. Los decorados sueltos en `assets/suelo/decorados/` (`pilar.png`, `calaveras.png`, `cristal.png`, `lapida.png`, `brasero.png`, `huesos.png`, `roca.png`, `circulo_runico.png`); si sale una lámina, `decorados/lamina.png`.

> [ESTILO] Seamless tileable top-down floor texture, 256×256, edges must tile perfectly on all four sides. **{BIOMA}**. Low contrast and dark (it's a background — characters must pop on top of it), subtle variation, no large landmarks.

- Capítulo 1, Criptas: "dark violet flagstone dungeon floor with thin cracks and very faint cyan rune lines"
- Capítulo 2, Cavernas heladas: "dark teal cave rock floor with patches of frost and small ice crystals"
- Capítulo 3, Forja/Magma: "dark basalt floor with thin glowing ember-orange cracks and ash"

Decorados (lámina de 8, 128×128 cada uno, fondo transparente): "broken rune pillar, skull pile, glowing cyan crystal cluster, cracked tombstone, brazier with violet flame, bones, small rock, rune floor circle".

### 6.4 Recolectables

**Estado:** integrados (`recolectable_01`–`10`): gemas de XP en 3 tamaños según el valor, moneda y pila de monedas, poción, imán, bomba y cofre. El cofre épico usa el mismo cofre teñido de violeta; si querés uno propio, guardalo como `recolectable_19.png` (hoy es una copia del cofre). El juego 11–20 está duplicado y no se usa salvo el 19.

**Dónde van:** recortar cada objeto a su propio PNG en `assets/pickups/`: `chest.png`, `chest_epic.png`, `potion.png`, `magnet.png`, `bomb.png` (el juego los toma solos). Mientras falten, el cofre y la poción usan íconos de la UI y el imán y la bomba se dibujan por código. El cofre épico es el mismo cofre con herrajes dorados y gemas violetas: agregarlo como celda (11) del prompt.

> [ESTILO] Sprite sheet, single row, each cell 64×64, small game pickups: (1) small cyan XP gem, (2) medium teal XP gem, (3) large violet XP gem with sparkle, (4) gold coin, (5) stack of 3 gold coins, (6) red health potion bottle, (7) horseshoe magnet with cyan glow, (8) round black bomb with lit fuse, (9) closed wooden-and-iron treasure chest with rune lock, (10) same chest opened with golden light.

### 6.5 VFX de las habilidades nuevas (tiras de 3–4 frames, como las actuales)

> [ESTILO] Sprite sheet of a game VFX animation, **{N} frames** in a single row, each frame {TAM}, transparent background, glowing additive-looking colors on transparent background: **{EFECTO}**.

| Efecto | {N} | {TAM} | {EFECTO} |
|---|---|---|---|
| Daga | 2 | 64×64 | thin cyan rune dagger pointing right, with a short light trail |
| Hacha bumerán | 4 | 128×128 | spinning double axe, rotation frames 0°/90°/180°/270°, cyan edge glow |
| Tajo | 4 | 256×128 | wide horizontal violet crescent slash growing then fading |
| Meteoro: marca | 3 | 128×128 | ground target circle with runes filling in from outside to center, orange |
| Meteoro: caída e impacto | 4 | 256×256 | flaming rock falling, then impact crater burst with debris |
| Esquirla | 2 | 64×64 | spinning cyan-magenta crystal shard |
| Familiar | 3 | 96×96 | floating small hooded ghost, idle bob, glowing teal eyes |
| Égida | 3 | 192×192 | translucent cyan hexagon-rune bubble shield shimmering |
| Electrocutado (estado) | 3 | 64×64 | small crackling cyan sparks |
| Iconos de estado | 1×4 | 32×32 | tiny flame, poison drop, ice crystal, lightning spark |
| Proyectil enemigo | 3 | 48×48 | small violet rune orb with dark core and short tail |
| Telegrafiado del jefe | 3 | 256×256 | ground warning rune circle filling with red-orange glow |
| Muerte de enemigo | 4 | 128×128 | dark creature dissolving into purple ash particles and cyan sparks |

Evoluciones: reutilizar la tira de su activa con un recoloreado dorado/blanco y escala ×1,5 desde el código. Solo vale la pena generar arte aparte para Cataclismo (meteoro gigante) y Corona Solar.

### 6.6 Héroes (opcional, 14 o los 6 de lanzamiento)

> [ESTILO] Same character as the reference image, 2 frames 256×256 in a row: (1) hit reaction — leaning back, white flash on body; (2) defeated — collapsed on the ground. Keep exactly the same outfit, palette and proportions as the reference.

### 6.7 Iconos de mejoras permanentes que faltan

**Estado:** integrados como `mejora_armadura.png`, `mejora_suerte.png` y `mejora_bloqueada.png` (Descartar).

Con el mismo marco que 6.1: **Armadura** (pecho de armadura), **Suerte** (trébol rúnico de 4 hojas), **Descartar** (carta tachada con una X). El resto ya existe en `cuadros_habilidades_emberfall/`.

**Dónde van:** `assets/cuadros_habilidades_emberfall/armadura.png`, `suerte.png` y `descartar.png` (la pantalla de Progreso los toma solos; mientras falten muestra la inicial).

| Icono | {SÍMBOLO} | {COLOR} |
|---|---|---|
| Armadura | a sturdy chestplate with a rune rivet in the center | steel grey + cyan |
| Suerte | a four-leaf clover made of glowing rune leaves | emerald green + cyan |
| Descartar | a playing card crossed out with a bold X | violet + red X |

### 6.8 Icono del footer: Progreso

Reemplaza al botón de personaje (que ahora vive solo dentro de la mochila). Mientras falte, el footer usa la flecha verde del kit.

**Estado:** hecho con el set completo de tres estados (`tienda`, `arbol`, `casa`, `mochila`, `portal` + `_normal`, `_hover`/`_hover_seleccionado`, `_desactivado`). Los corazones del HUD usan `hud/heart_full/half/empty.png`.

**Dónde va:** `assets/ui/pixel_simple_v1/navigation/upgrades.png` (mismo tamaño y estilo que `home.png`, `shop.png`, etc.).

> Pixel art game UI navigation icon, 64x64, transparent background, chunky dark purple outline, same style as a set of icons (shop stall, house, backpack, purple portal). Subject: a glowing upward arrow rising out of a small rune anvil, with tiny ember sparks. Palette: dark violet base, turquoise cyan glow (#3fe0d0), small gold highlights. Centered, readable at 48px, no text, no frame.

## 7. Exportar a Android

El preset ya está en `export_presets.cfg`. Datos de la app:

| Campo | Valor |
|---|---|
| Paquete | `com.ze7aro.emberfall` |
| Versión | 0.9.0 (código 1) |
| Arquitecturas | arm64 y armv7 |
| Pantalla | Vertical, pantalla completa |
| Salida | `build/android/Emberfall.apk` (ignorada por git) |

Lo que hay que hacer una sola vez en el editor:

1. **Plantillas de exportación:** Editor → Gestionar plantillas de exportación → Descargar e instalar.
2. **JDK 17 y Android SDK:** instalar Android Studio (trae el SDK) y un JDK 17. Configurar las rutas en Editor → Configuración del editor → Exportar → Android (`Java SDK Path` y `Android SDK Path`).
3. **Clave de depuración:** Godot la crea sola la primera vez. Alcanza para probar en tu teléfono.
4. **Clave de publicación** (solo para subir a Google Play). Se genera con:
   `keytool -genkeypair -v -keystore emberfall-release.keystore -alias emberfall -keyalg RSA -keysize 2048 -validity 10000`
   Cargala en Proyecto → Exportar → Android → Keystore → Release. Guardala fuera del repositorio: `*.keystore` está en `.gitignore` y si la perdés no podés actualizar la app.

Para probar: conectá el teléfono con depuración USB activada. Aparece el ícono de Android arriba a la derecha del editor (Despliegue con un clic). La alternativa es Proyecto → Exportar → Exportar proyecto y copiar el APK al teléfono.

Ya resuelto en el código: el botón Atrás cierra ventanas, pausa la partida y vuelve a Inicio, y en Inicio sale del juego. La partida se pausa al perder el foco, el progreso se guarda al pasar a segundo plano y la barra superior y el menú respetan las áreas seguras.

**Peso del paquete:** todo lo que el juego no carga está en `assets/quitar/` (con `.gdignore`, así que Godot no lo importa ni lo exporta): referencias, fuentes de la UI, kits viejos, sprites de efectos reemplazados por código, las hojas de íconos de otros juegos (no se pueden distribuir) y las dos pantallas de vista previa del kit. Los íconos de habilidades, los jefes, los personajes y el anillo de XP se importan con un límite de 256 px (`process/size_limit`; los PNG originales quedan intactos). El `.pck` pasó de 129 MB a 26 MB. Si algo de `quitar` vuelve a hacer falta, sacalo de ahí a su ruta original.

### 7.1 Prueba en el teléfono

| Qué mirar | Cómo | Bien si |
|---|---|---|
| Fluidez | Partida de 10 minutos, con JEFE y HORDA desde depuración | No baja de ~50 fps ni se traba al aparecer muchos enemigos o efectos |
| Temperatura y batería | La misma partida | El teléfono no se pone muy caliente |
| Toques | Footer, cartas de mejora, botón de pausa, RECLAMAR en misiones | Todo se toca al primer intento con el dedo |
| Áreas seguras | Teléfono con notch o cámara en pantalla | La barra superior y el footer no quedan tapados |
| Botón Atrás | En ventanas, en partida y en Inicio | Cierra la ventana, pausa y sale, en ese orden |
| Segundo plano | Salir a otra app en plena partida y volver | La partida está en pausa y no se perdió progreso |
| Texto | Todas las pantallas | Nada cortado ni encimado |
| Sonido | Partida y menús | Se escucha y respeta el volumen del teléfono |

## 8. Mejora visual de las habilidades en combate

### 8.1 Diagnóstico

- **Dos estilos mezclados.** Fuego, Ventisca, Frasco, Cadena y las explosiones usan sprites de pixel art detallados; Dagas, Hacha, Esquirla, Familiar, Tajo, Meteoro y Égida son polígonos chicos dibujados por código. Lado a lado no parecen del mismo juego.
- **Sprites achicados con filtro "nearest".** Los sprites miden 724×724 y se dibujan al 10–20 %: con `TEXTURE_FILTER_NEAREST` se pierden píxeles al azar y titilan.
- **Poco brillo.** Nada usa mezcla aditiva, así que los efectos se ven opacos sobre el suelo oscuro y cuesta distinguir los ataques propios de los enemigos.
- **Sin respuesta al impacto.** Salvo el número de daño, el golpe de una habilidad no deja chispas ni destello de su color.
- **Nivel y evolución casi no se notan.** Una habilidad al nivel 5 o evolucionada se ve igual que al nivel 1, apenas más grande.
- **Lunas Orbitales:** ✅ hecho, ahora son esferas blancas con halo, dibujadas por código.

### 8.2 Criterios (lenguaje visual común)

1. Cada efecto tiene **núcleo blanco + color de la habilidad + halo aditivo** (`CanvasItemMaterial.BLEND_MODE_ADD`). El color sale de `AbilityCatalog` (`color`).
2. Lo que se mueve deja **estela corta** que se desvanece (dagas, hacha, esquirla, meteoro).
3. Cada golpe genera **2–4 chispas de su color** (pool compartido con tope, como los números de daño).
4. Todo respeta la **perspectiva 3/4**: áreas y anillos son elipses (alto ≈ 55 % del ancho), como la órbita.
5. **El nivel se nota:** +10 % de brillo/tamaño por nivel. **Evolución:** tinte dorado/blanco, ×1,3 de tamaño y un detalle extra propio.
6. **Colores reservados:** cian/blanco/dorado = jugador; rojo/violeta oscuro = enemigos.
7. **Rendimiento y accesibilidad:** tope global de efectos y chispas; con "Reducir temblor y destellos" se baja el halo y no hay destellos.

### 8.3 Habilidad por habilidad

| Habilidad | Hoy | Propuesta | ¿Arte? |
|---|---|---|---|
| Lunas Orbitales | Sprite de luna | ✅ Esferas blancas. Evolución: halo cian y línea tenue de la órbita | No |
| Dagas Rúnicas | Triángulo | Hoja fina con núcleo blanco, halo cian y estela de 3 puntos | Opcional (§6.5) |
| Aura Ígnea | Anillo de fuego (3 frames muy distintos) | Usar solo el frame 0 girando lento + pulso aditivo; chispas que suben | No |
| Cadena Eléctrica | Sprite estirado entre enemigos | Rayo en zigzag dibujado por código que cambia cada 2 frames, núcleo blanco + halo cian, chispa en cada salto | No |
| Frasco Tóxico | Sprite bomba + charco | Mantener la bomba; charco como elipse con burbujas que suben y revientan | No |
| Ventisca | Sprite de anillo helado | Mantener, en elipse; copos que caen dentro del área | No |
| Hacha Bumerán | 2 triángulos girando | Hacha con arcos de movimiento (estela circular) y brillo en los filos | Opcional (§6.5) |
| Tajo Sombrío | 2 líneas curvas | Medialuna rellena que se afina en las puntas, borde blanco, partículas violeta | No |
| Lluvia de Meteoros | Círculos | Marca rúnica en elipse que se llena; roca con estela de fuego; impacto con onda + escombros + temblor chico | Opcional (§6.5) |
| Esquirla Errante | Rombo | Cristal con 3 imágenes fantasma detrás; destello en cada rebote | No |
| Familiar Espectral | Triángulo con ojos | Fantasma con cuerpo redondeado y cola ondulante; su disparo deja estela | Opcional (§6.5) |
| Égida Rúnica | Solo explosión al romperse | Burbuja hexagonal visible alrededor del jugador mientras tiene carga; al romperse, fragmentos + onda | No |

### 8.4 Fases

1. **Base común (solo código):** helper `FxKit` con material aditivo, halo, estela (`Line2D` con degradé), pool de chispas y tinte de evolución. Corregir el filtrado de los sprites grandes (pre-achicarlos a su tamaño real o usar filtro lineal con mipmaps).
2. **Rehacer las habilidades dibujadas por código** con el kit: Dagas, Tajo, Esquirla, Hacha, Meteoro, Cadena, Égida, Familiar.
3. **Sacar los sprites de efecto:** Aura Ígnea, Ventisca, Frasco y explosión pasan a dibujo por código (los sprites pixel-art opacos resaltaban demasiado frente al resto). Referencia de estilo: Magic Survival, con zonas translúcidas, borde fino y pocas partículas, y el foco en los enemigos.
4. **Evoluciones:** el detalle propio de cada una (Tormenta de Filos = anillo de dagas, Cataclismo = meteoro gigante, etc.).
5. **Arte opcional (§6.5):** si llegan las tiras, reemplazan el dibujo por código sin tocar la lógica.

**Para probar:** en builds de depuración, botones **HAB ›** (siguiente habilidad, sola, al nivel 1) y **NV +** (sube un nivel; pasado el 5, evoluciona).

**Estado:** fases 1 y 2 hechas (`fx_kit.gd`, `fx_sparks.gd`, `fx_ring.gd`, `fx_lightning.gd`, `aegis_bubble.gd`, y Dagas, Hacha, Esquirla, Familiar, Tajo, Meteoro, Cadena y Égida rehechos). Los sprites de habilidades ahora usan mipmaps. Fase 3 hecha: ventisca (disco helado con nieve), charco de veneno (borde ondulante con burbujas), frasco, aura de fuego (brasas) y explosiones (anillo con chispas, también el golpe del jefe) se dibujan en código; las esferas orbitales son más chicas. Los sprites de `emberfall_habilidades_sprites` quedaron sin uso. Fase 4 hecha: Eclipse Eterno (órbita visible y halo cian), Corona Solar (rayos dorados en el borde), Cataclismo (marca carmesí con segundo anillo rúnico e impacto más grande), Prisma Infinito (cristales arcoíris), Invierno Perpetuo (cristales de nieve girando en el borde) y Legión Espectral (halo y ojos dorados). El resto ya se distingue por su mecánica y el tinte dorado. Las áreas que dañan en círculo (meteoro) se dibujan en círculo para que lo que se ve sea lo que golpea.

### 8.5 Arte opcional (solo si querés reemplazar el dibujo por código)

**Estado:** en uso desde `assets/vfx/`: `hacha/` (girada por código), `familiar/` (3 cuadros), `muerte/` (disolución sobre el sprite del enemigo) y `estados/` (fuego, veneno y hielo; la electrocución sigue dibujada). El resto de las láminas de VFX quedó en `assets/quitar/vfx_sin_usar/`.

El resto se ve mejor dibujado por código. Estas tres piezas son objetos con forma, donde una imagen sí suma. Usar el bloque de estilo §6.0, PNG con fondo transparente, sin texto.

| Pieza | Archivo | Tamaño | Prompt |
|---|---|---|---|
| Hacha bumerán | `assets/emberfall_habilidades_sprites/hacha/axe.png` | 1 imagen, 128×128 | "a double-bladed throwing axe seen from above, blades pointing left and right, dark steel with thin glowing cyan rune edges, short wrapped handle in the center, centered, symmetric" (el código la hace girar y le agrega la estela) |
| Familiar espectral | `assets/emberfall_habilidades_sprites/familiar/frame_00.png` a `frame_02.png` | 3 imágenes, 96×96 | "small hooded ghost spirit floating, pale teal translucent body that ends in a wavy wispy tail, two glowing cyan eyes, no arms; 3 frames of an idle bob where only the tail waves" |
| Roca del meteoro | `assets/emberfall_habilidades_sprites/meteoro/rock.png` | 1 imagen, 96×96 | "a burning meteor rock, dark cracked basalt with glowing orange-yellow lava cracks, round chunky shape, no trail, centered" (la estela de fuego la pone el código) |

Avisame cuando estén y los conecto.

## Fuentes de referencia
- [Vampire Survivors: weapon evolution guide (Prima Games)](https://primagames.com/gaming/vampire-survivors-weapon-evolution-guide)
- [Vampire Survivors: passive item guide (Prima Games)](https://primagames.com/gaming/vampire-survivors-passive-item-guide)
- [All Vampire Survivors weapon evolutions (Dot Esports)](https://dotesports.com/indies/news/all-vampire-survivors-weapon-evolutions)
- [Halls of Torment ability tier list (Pro Game Guides)](https://progameguides.com/halls-of-torment/halls-of-torment-ability-tier-list-best-abilities-for-each-character/)
- [Halls of Torment ability tier list (Prima Games)](https://primagames.com/tips/halls-of-torment-ability-tier-list-best-abilities-listed)
