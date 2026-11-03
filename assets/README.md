# Assets de Emberfall

Todo lo que el juego usa, agrupado por tema. Lo que no se usa va a `quitar/`,
que Godot ignora (tiene `.gdignore`): no se importa ni entra al APK.

| Carpeta | Qué hay | Quién lo carga |
|---|---|---|
| `audio/musica/` | Música: `Intro_0X`, `Combat_0X`, `Boss_0X` | `MusicDirector` |
| `audio/sfx/<grupo>/` | Efectos de sonido por grupo (abilities, boss, combat, economy, progression, status, ui) | `SfxPlayer.play("grupo/archivo.wav")` |
| `personajes/heroes/<variante>/` | Héroes: `walk_<dir>_0X`, `attack_0X` | `CharacterAnimations` (nombre de carpeta en `resources/characters/*.tres`) |
| `personajes/enemigos/<tipo>/capN/` | Enemigos por tipo (chaser, fast, tank, shooter, charger, elite) y capítulo: `walk_00..02` | `EmberfallEnemy.walk_frames()` |
| `personajes/enemigos/generico.png` | Enemigo de respaldo si falta el arte de un tipo | `EmberfallEnemy` |
| `personajes/jefes/<NN_nombre>/` | Jefes: `idle`, `attack_01`, `attack_02` | `EmberfallBoss`, Códex |
| `habilidades/iconos/` | Íconos de activas (`<id>.png`) y evoluciones (`evo_<nombre>.png`) | `AbilityCatalog.icon()` |
| `habilidades/proyectiles/<nombre>/` | Disparos básicos de cada héroe | `EmberfallProjectile` |
| `habilidades/efectos/` | Arte de efectos: `estados/` (fuego, veneno, hielo), `familiar/`, `hacha/`, `muerte/` | `EmberfallVfxArt` |
| `mejoras/` | Íconos de mejoras permanentes y pasivas | `UpgradeCatalog`, `AbilityCatalog` |
| `mundo/suelos/` | Losetas de suelo por capítulo (`capN_<bioma>.png`, repetibles) | `game_world.gd` (`FLOOR_ART`) |
| `mundo/decorados/capN/` | Decorados del mapa; los de `DECOR_SOLID` son sólidos | `game_world.gd` |
| `mundo/recolectables/` | XP (`xp_chica/mediana/grande`), `moneda(s)`, `pocion`, `iman`, `bomba`, `cofre`, `cofre_epico` | `xp_orb.gd`, `pickup.gd` |
| `ui/fuentes/` | Cinzel Decorative (títulos) y Alegreya Sans (texto), licencia OFL (`OFL_*.txt`). `texto.tres` es la fuente global del proyecto; `titulo.tres` y `texto_bold.tres` las usa `UiTheme` | `project.godot`, `UiTheme.title_font()` / `bold_font()` |
| `ui/` | Kit de interfaz: `backgrounds`, `bars`, `buttons`, `equipment`, `frames`, `hud` (corazones, nivel), `icons`, `navigation` (footer en 3 estados), `shop`, `escenarios` (vistas de mapa), `logo` | `UiTheme`, `TopHud`, `NavigationFooter`, pantallas |

## Reglas

- Nombres en minúscula, sin ñ, tildes ni espacios (`dano.png`, no `daño.png`).
- Imágenes grandes: el límite de tamaño y los mipmaps se ponen en el `.import`
  (`process/size_limit`), así el PNG original queda intacto.
- Si movés o renombrás un archivo, buscá su ruta en `scripts/` y actualizala.
