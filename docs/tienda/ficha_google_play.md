# Ficha de Google Play: Emberfall

Borrador de textos de la ficha de la tienda (Play Console). Las notas están en español; los textos de la ficha van en español (ES) y en inglés (EN).

**Cómo se contaron los caracteres:** con `len()` de Python sobre cada texto, es decir, por carácter Unicode. En la descripción completa cuentan también los saltos de línea. Los conteos se hicieron sobre los textos exactos de este archivo.

---

## 1. Título (máximo 30 caracteres)

| Opción | Texto | Caracteres |
|---|---|---|
| 1 | Emberfall | 9 |
| 2 | Emberfall: Roguelike Oscuro | 27 |
| 3 | Emberfall: Fuego y Sombra | 25 |

Notas: el nombre del juego es Emberfall. La opción 1 es la más segura. Las opciones 2 y 3 añaden un descriptor, sin palabras promocionales.

---

## 2. Descripción breve (máximo 80 caracteres)

**Español**

| Opción | Texto | Caracteres |
|---|---|---|
| 1 | Sobrevive a hordas oscuras con una mano. Evoluciona habilidades y vence al jefe. | 80 |
| 2 | Roguelike de fantasía oscura en pixel art. Sube de nivel, evoluciona y resiste. | 79 |
| 3 | Combate en pixel art con ataque automático: elige habilidades y evoluciónalas. | 78 |

**English**

| Opción | Texto | Caracteres |
|---|---|---|
| 1 | Dark-fantasy survivors roguelike, one-handed. Build, evolve and beat the boss. | 78 |
| 2 | Pixel-art dark fantasy you play with one thumb. Level up, evolve, survive. | 74 |
| 3 | Auto-attacking pixel-art roguelike. Pick abilities, evolve them, face the boss. | 79 |

---

## 3. Descripción completa (máximo 4000 caracteres)

### 3.1 Español (neutral latinoamericano, tú)

Caracteres: **1884** (de 4000)

```text
Un héroe, una oscuridad que no se detiene y una sola mano para sobrevivir.
Emberfall es un roguelike de fantasía oscura en pixel art. Tu héroe ataca solo: tú decides hacia dónde moverte y qué poderes elegir.

COMBATE
- Ataque automático: tu héroe dispara solo mientras controlas el movimiento con un joystick flotante.
- Enemigos comunes, élites y jefes. Cada etapa culmina con un jefe.
- Al subir de nivel eliges entre habilidades activas y pasivas.

HABILIDADES Y EVOLUCIONES
- 12 habilidades activas y 12 pasivas, cada una con hasta 5 niveles.
- 6 habilidades activas empiezan bloqueadas. Se desbloquean con logros como eliminar enemigos o derrotar a un jefe.
- Una habilidad al nivel máximo, con su pasiva compañera, puede evolucionar a una versión dorada.
- 26 evoluciones doradas en total: 12 de habilidades y 14 de las armas de los héroes.

HÉROES
- 14 héroes, cada uno con su propia arma básica. Cada héroe tiene un reto que desbloquea su arma para todos.
- Las armas también evolucionan con efectos propios: explosiones, charcos de veneno, rayos, cortes en cruz y más.

PROGRESIÓN
- Equipo en 6 ranuras (arma, armadura, casco, amuleto, anillo y botas) y 6 rarezas, de común a legendario.
- Un conjunto de equipo por capítulo, con bonos al equipar 2 o 4 piezas.
- En la Forja, combina copias iguales de un objeto para subirlo de rareza, y mejora su nivel con oro y esencia.
- Un mapa de 10 etapas repartidas en 3 capítulos, y 3 mazmorras con modificadores propios.
- Mejoras permanentes que persisten entre partidas.
- Cada partida gasta energía, que se recarga con el tiempo.

MISIONES
- Cada día aparecen 5 misiones nuevas, y cada semana hay 6 misiones fijas.
- Completarlas da oro, gemas y puntos de actividad.

Emberfall es gratis. Tiene compras opcionales de oro y energía, y anuncios opcionales para obtener recompensas. No requiere cuenta y se puede jugar sin conexión.
```

### 3.2 English

Characters: **1862** (of 4000)

```text
One hero, a darkness that never stops growing, and one hand to survive it.
Emberfall is a dark-fantasy roguelike in pixel art, built for portrait play. Your hero attacks on its own: you decide where to move and which powers to take.

COMBAT
- Automatic attacks: your hero fires on its own while you steer with a floating joystick.
- Common enemies, elites and bosses. Every stage ends with a boss.
- Each level-up lets you choose between active and passive abilities.

ABILITIES AND EVOLUTIONS
- 12 active abilities and 12 passives, each up to level 5.
- 6 active abilities start locked. Unlock them through achievements such as defeating enemies or beating a boss.
- An active ability at max level, with its paired passive, can evolve into a golden version.
- 26 golden evolutions in total: 12 for abilities and 14 for the heroes' weapons.

HEROES
- 14 heroes, each with its own basic weapon. Each hero has a challenge that unlocks that weapon for all heroes.
- Weapons evolve too, with their own effects: explosions, poison pools, lightning, cross-shaped slashes and more.

PROGRESSION
- Equipment in 6 slots (weapon, armor, helmet, amulet, ring, boots) and 6 rarities, from common to legendary.
- One equipment set per chapter, with bonuses for wearing 2 or 4 pieces.
- At the Forge, combine identical copies of an item to raise its rarity, and upgrade its level with gold and essence.
- A map of 10 stages across 3 chapters, plus 3 dungeons with their own modifiers.
- Permanent upgrades that carry over between runs.
- Each run costs energy, which recharges over time.

MISSIONS
- Each day brings 5 new missions, and each week has 6 fixed missions.
- Completing them rewards gold, gems and activity points.

Emberfall is free to play, with optional in-app purchases (gold and energy packs) and optional rewarded ads. No account needed, and it works offline.
```

---

## 4. Categoría y etiquetas sugeridas

- **Categoría recomendada:** Juegos > Acción. Razón: el núcleo es combate en tiempo real con movimiento y ataque automático, como en los juegos de supervivencia.
- **Alternativa:** Juegos > Rol. Encaja por la progresión de equipo y habilidades, pero el combate es el primer atractivo de la ficha.
- **Etiquetas (elegir de la lista de Play Console, que puede tener nombres distintos):** Roguelike, Pixel art, Fantasía oscura, Supervivencia, Un jugador.

---

## 5. Formulario de seguridad de datos (Data safety)

Base: la app no tiene cuenta; el código propio del desarrollador no recopila datos; el progreso se guarda solo en el dispositivo; el SDK de Google AdMob (anuncios recompensados) recopila IDs de dispositivo, ubicación aproximada derivada de la IP e interacciones/diagnósticos para publicidad; Google Play Billing gestiona las compras; los datos viajan cifrados por los SDK de Google.

**Importante:** las filas marcadas como VERIFICAR deben revisarse contra la guía vigente de Google sobre la declaración de datos de AdMob ("Google Play data disclosure") antes de enviar el formulario. Las categorías exactas cambian con las versiones del SDK.

| Pregunta del formulario | Respuesta propuesta | Estado |
|---|---|---|
| ¿La app recopila o comparte datos de usuario? | Sí, solo mediante el SDK de AdMob. El código propio del juego no envía datos. | VERIFICAR: Play cuenta como recopilados los datos que recoge un SDK de terceros. |
| ¿Hay cuenta de usuario? | No. | Confirmar que ninguna función exige inicio de sesión. |
| ¿Los datos se cifran en tránsito? | Sí, los SDK de Google usan HTTPS. | Confirmar. |
| ¿Los usuarios pueden pedir la eliminación de sus datos? | El desarrollador no conserva datos, así que no puede eliminarlos. El progreso queda en el dispositivo y se borra al desinstalar la app. Los anuncios se gestionan con la configuración de anuncios de Google en el dispositivo. | VERIFICAR el texto exacto que pide el formulario. |
| Progreso del jugador (partidas, equipo, misiones) | Se guarda solo en el dispositivo. No se envía al desarrollador. Tipo: no recopilado. | Confirmar que no hay analítica propia. |
| Identificadores de dispositivo (ID de publicidad) | Recopilado por AdMob. Uso: publicidad. Compartido con Google (AdMob). | VERIFICAR la categoría exacta y si es opcional. |
| Ubicación aproximada | Derivada de la IP por AdMob. Uso: publicidad. Ubicación precisa: no. | VERIFICAR. |
| Interacciones con la app / actividad | Recopiladas por AdMob para publicidad (por ejemplo, anuncios vistos). | VERIFICAR. |
| Diagnósticos (fallos, rendimiento) | Puede recopilarlos el SDK de AdMob. | VERIFICAR. Si el SDK no los declara, marcar no. |
| Compras | Google Play Billing procesa el pago. La app recibe el resultado en el dispositivo. | VERIFICAR: declarar historial de compras solo si algún dato sale del dispositivo. |
| Contactos, fotos, archivos, micrófono, cámara, salud, finanzas | No. | Confirmar. |
| La app contiene anuncios | Sí (anuncios recompensados opcionales). | Marcar en la declaración de anuncios. |
| Consentimiento de anuncios | El juego ejecuta el formulario de consentimiento de Google (UMP) donde aplica, como la UE y el Reino Unido. | VERIFICAR el mensaje de consentimiento configurado en AdMob. |
| Permisos | En el preset de exportación solo figura la vibración. INTERNET y el ID de publicidad llegan por los plugins/AdMob. | VERIFICAR en el manifiesto fusionado del APK o AAB. |

---

## 6. Clasificación de contenido (cuestionario IARC)

Respuestas probables. Son estimaciones: el cuestionario lo responde el desarrollador en Play Console.

| Tema | Respuesta probable |
|---|---|
| Violencia | Sí. Violencia de fantasía contra monstruos y enemigos. |
| Sangre o gore | No. |
| Miedo o terror | Leve (ambiente oscuro, sin escenas explícitas). Revisar. |
| Lenguaje soez | No. Revisar si hay textos con insultos. |
| Sexualidad o desnudez | No. |
| Drogas, alcohol o tabaco | No. |
| Juegos de azar o apuestas con dinero | No. |
| Contenido generado por usuarios | No. |
| Chat o interacción entre usuarios, compartir ubicación | No. |
| Compras integradas | Sí (paquetes de oro y energía). |
| Anuncios | Sí (anuncios recompensados opcionales). |

**Resultado estimado:** PEGI 7 si la violencia de fantasía se considera leve, o PEGI 12 si el cuestionario la clasifica como violencia moderada. En ESRB, E10+ es lo más probable. Confirmar con las respuestas reales del cuestionario.

---

## 7. Materiales gráficos pendientes

### Requisitos de Google Play

| Material | Requisito | Estado |
|---|---|---|
| Icono de la app | 512 × 512 px | Listo: `assets/ui/icono/icon_512.png` (en la carpeta del proyecto). |
| Gráfico destacado (feature graphic) | 1024 × 500 px | Pendiente. Sugerencia: héroe frente a una cripta en penumbra, con el logotipo de Emberfall. Sin precios, sin "gratis", sin texto de promoción. |
| Capturas de teléfono | Mínimo 2; recomendadas 4 a 8; formato 9:16 (por ejemplo 1080 × 1920) | Pendiente. Ver la tabla siguiente. |
| Vídeo promocional (opcional) | Enlace de YouTube | Opcional. |

### Capturas sugeridas (en este orden)

| # | Pantalla a capturar | Qué debe verse | Archivo existente a revisar |
|---|---|---|---|
| 1 | Combate | Héroe con su arma, horda de enemigos y joystick flotante visible. | `tmp/combate_heroe_grande.png` (revisar si sigue vigente) |
| 2 | Subida de nivel | Tarjetas de habilidad y una evolución dorada. | Ninguno: captura nueva. |
| 3 | Pelea con jefe | Jefe con barra de vida visible. | Ninguno: captura nueva. |
| 4 | Inicio y mapa de etapas | Capítulos y etapas, con la pantalla de inicio. | Ninguno: captura nueva. |
| 5 | Héroes | Pantalla de héroes con la plantilla de personajes. | Ninguno: captura nueva. |
| 6 | Equipo y Forja | Piezas con sus colores de rareza y un conjunto de capítulo. | Ninguno: captura nueva. |
| 7 | Misiones | Misiones diarias y semanales con su progreso. | `tmp/misiones_nuevas.png` (revisar si sigue vigente) |
| 8 | Mejoras permanentes | Árbol de mejoras permanentes. | Ninguno: captura nueva. |

Las capturas deben tomarse de una compilación de versión, sin textos de depuración. En la compilación de depuración aparecen mensajes "[simulada]" y los anuncios y compras son simulados. No deben aparecer esos mensajes ni cualquier otro texto de depuración.

---

## 8. Pendientes del desarrollador

Datos que solo el desarrollador puede aportar:

- [x] Nombre del desarrollador tal como aparecerá en la tienda: `Z-rho[Dev]`
- [x] Correo de contacto público: `magis01watch@gmail.com`
- [x] URL de la política de privacidad (obligatoria, porque la app muestra anuncios): `https://ze7aro.github.io/emberfall-privacy/`
- [ ] Sitio web (opcional): `[URL_SITIO_WEB]`
- [ ] Cuenta de desarrollador de Google Play Console, con verificación de identidad y el pago único de registro.
- [x] ID de aplicación real de AdMob en Project Settings > admob/general/android/app_id: `ca-app-pub-4856775590726819~9395850037`
- [ ] Unidad de anuncio recompensado real. En `scripts/systems/monetization.gd` la constante `REWARDED_UNIT` sigue usando la unidad de prueba de Google. Valor: `[ID_UNIDAD_RECOMPENSADA_ADMOB]`
- [ ] Mensaje de consentimiento en AdMob (UMP) para usuarios de la UE y el Reino Unido.
- [ ] Productos in-app en Play Console con los IDs exactos de `scripts/systems/game_state.gd`: `recarga_oro_baja`, `recarga_oro_media`, `bolsa_oro_media`, `cofre_oro_medio`, `cofre_oro_grande`, `recarga_energia_media`, `recarga_energia_grande`. Precios de referencia (el definitivo se fija en la consola): 500 monedas USD 0,99 · 1.200 USD 1,99 · 3.200 USD 4,99 · 7.000 USD 9,99 · 15.000 USD 19,99 · 60 de energía USD 0,99 · 150 de energía USD 1,99.
- [ ] Versión de la app: `export_presets.cfg` tiene `version/name=0.9.0` y `version/code=1`. Subir el código de versión antes de cada envío.
- [ ] Firma de la app: el keystore de release se genera con `tools/create_release_keystore.ps1`. Guardarlo y su contraseña fuera del repositorio.
- [ ] Cuestionario de clasificación de contenido (IARC) completado en Play Console.
- [ ] Formulario de seguridad de datos completado y revisado contra la guía de AdMob.
- [ ] Declaración de anuncios: marcar que la app contiene anuncios.
- [ ] Público objetivo: indicar edad (recomendado 13 o más). Con anuncios, no declarar la app como dirigida a niños.
- [ ] Acceso a la app: indicar que no hace falta inicio de sesión, para que el revisor no pida credenciales.
- [ ] Países de distribución y precios locales.
- [ ] Notas de la versión (opcional).
- [ ] Capturas, gráfico destacado y textos finales (las secciones 1 a 7 de este archivo).

---

## 9. Verificación de datos

| Dato | Valor usado | Fuente en el proyecto |
|---|---|---|
| Héroes | 14 | 14 archivos `resources/characters/variante_01.tres` a `variante_14.tres`. Coinciden con `RESOURCE_PATHS` en `scripts/data/character_catalog.gd`. |
| Habilidades activas | 12 | Entradas de `ACTIVES` en `scripts/data/ability_catalog.gd`. |
| Habilidades pasivas | 12 | Entradas de `PASSIVES` en `scripts/data/ability_catalog.gd`. |
| Niveles máximos por habilidad | 5 | `MAX_LEVEL` en `scripts/data/ability_catalog.gd`. |
| Habilidades activas bloqueadas al inicio | 6 | `UNLOCKS` en `scripts/data/ability_catalog.gd`. Las 6 restantes están disponibles desde el inicio. |
| Evoluciones de habilidades | 12 | Campo `evolution` de cada entrada de `ACTIVES`. |
| Evoluciones de armas de héroes | 14 | `WEAPON_EVOLUTIONS` en `scripts/data/ability_catalog.gd`. |
| Total de evoluciones doradas | 26 | 12 + 14. |
| Etapas | 10 | `STAGE_COUNT := 10` en `scripts/systems/game_state.gd`, y 10 nombres en `STAGE_NAMES` de `scripts/ui/HomeScreen.gd`. |
| Capítulos | 3 | En `HomeScreen.gd`, el capítulo es `1 + i/4` para 10 etapas, y hay previews para los capítulos 1 a 3. |
| Mazmorras | 3 | `DUNGEONS` en `scripts/ui/DungeonSelectionScreen.gd`, cada una con un modificador. |
| Ranuras de equipo | 6 | `TYPES` en `scripts/data/equipment_catalog.gd`. |
| Rarezas | 6 | `RARITIES` en `scripts/data/equipment_catalog.gd`. |
| Conjuntos de equipo | 3, uno por capítulo, con bono a 2 piezas y efecto a 4 | `SETS`, `SET_BONUS_PIECES` y `SET_EFFECT_PIECES` en `scripts/data/equipment_catalog.gd`. |
| Fusión en la Forja | Copias iguales | `MERGE_COUNT` en `scripts/data/equipment_catalog.gd`. |
| Misiones diarias | 5 por día, de un pool de 10 | `DAILY_SLOTS` (2 + 2 + 1) y `DAILY_POOL` en `scripts/systems/game_state.gd`. |
| Misiones semanales | 6 fijas | `WEEKLY_MISSIONS` en `scripts/systems/game_state.gd`. |
| Recompensas de misiones | Oro, gemas y puntos de actividad | Campos `gold`, `gems` y `points` de las misiones. |
| Costo de energía por partida | 5 | `ENERGY_COST := 5` en `scripts/systems/game_state.gd`. La energía se recarga con el tiempo (mensaje en `scripts/MainLayout.gd`). |
| Productos de pago | 7 con precio real | `COIN_OFFERS` y `ENERGY_OFFERS` en `scripts/systems/game_state.gd`, con `cost = -1`. |
| Anuncios recompensados | Sí | `scripts/systems/monetization.gd`, con backend Play y AdMob. |
| Compras | Sí | `scripts/systems/monetization.gd`, con Google Play Billing. |
| Jefes al final de la partida | Sí | Dato indicado en el encargo; `scripts/game_world.gd` contiene la lógica de jefes (59 menciones). |

## 10. Lo que no pude verificar o que conviene revisar

- **Plugins instalados:** no verifiqué en `addons/` que los plugins de facturación y AdMob estén activos en el proyecto. Los textos dan por supuesto que sí, según la descripción del juego.
- **Unidad de anuncio de prueba:** `monetization.gd` sigue apuntando a la unidad de prueba de Google. Hay que reemplazarla antes de publicar, o los anuncios no pagarán.
- **Comentario desactualizado:** el comentario de `scripts/systems/game_state.gd` junto a `COIN_OFFERS` dice que las ofertas son solo visuales hasta conectar la tienda. El código de compra ya está conectado. No lo cambié, porque el encargo era no modificar otros archivos.
- **Capturas de `tmp/`:** no abrí las imágenes de `tmp/` para comprobar su contenido. Solo las señalé como posibles reutilizables.
- **Clasificación y formulario de datos:** son estimaciones basadas en el código y en la descripción. Deben confirmarse en Play Console.
- **Jefes:** la descripción dice que cada partida termina con un jefe, tal como indicó el encargo. Revisé que haya lógica de jefes en `game_world.gd`, pero no seguí el flujo completo de una partida.
- **Sin precios:** los textos no mencionan precios, porque Play los muestra según el país.
