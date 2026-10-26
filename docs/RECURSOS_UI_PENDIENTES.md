# Recursos de UI pendientes

Estado: **ninguno entregado todavía**. El código ya está preparado (`UiTheme.KIT` en `scripts/ui/UiTheme.gd`): al colocar un archivo con el nombre y la ruta indicados, Godot lo importa y el tema lo usa. Mientras no exista, se usa el estilo plano actual.

## Criterios comunes

- PNG, pixel art sin suavizado (el proyecto usa filtro *nearest*). Transparencia donde se indica.
- Dimensiones al doble de la resolución lógica del proyecto (390×844) para que se vean nítidas en móviles. Los márgenes de nueve cortes se expresan en píxeles **de la textura**, en el orden izquierda / arriba / derecha / abajo.
- Nueve cortes solo en paneles, botones, pestañas, barras y ranuras. Iconos, cabeceras, fondos y logo **no** usan nueve cortes.
- Los estados por color (rareza, activo/inactivo) pueden resolverse teñiendo (`self_modulate`) una textura neutra en lugar de exportar una por color.
- Cada recurso nuevo se valida primero en una pantalla de prueba antes de aplicarlo al resto.

## Kit con nueve cortes (StyleBoxTexture)

| Recurso | Ruta de destino | Dimensiones | Transparencia | Márgenes | Componente | Pantallas | Estado |
|---|---|---|---|---|---|---|---|
| panel_default | assets/ui/kit/panels/panel_default.png | 96×96 | Sí (esquinas) | 12/12/12/12 | PanelContainer (tema) | Todas las tarjetas y paneles | Pendiente (clave en KIT) |
| panel_modal | assets/ui/kit/panels/panel_modal.png | 128×128 | Sí | 16/16/16/16 | PanelContainer | Perfil, Configuración, Notificaciones, poderes, pausa | Pendiente (clave en KIT) |
| panel_card | assets/ui/kit/panels/panel_card.png | 64×64 | Sí | 8/8/8/8 | PanelContainer | Tarjetas de tienda, misiones y opciones de poder | Pendiente (clave en KIT) |
| panel_topbar | assets/ui/kit/panels/panel_topbar.png | 780×320 (lógico 390×160) | Sí | 12/12/12/16 | TopHud | Top HUD | Pendiente (clave en KIT) |
| panel_footer | assets/ui/kit/panels/panel_footer.png | 780×232 (lógico 390×116) | Sí | 12/16/12/12 | NavigationFooter | Footer | Pendiente (clave en KIT) |
| button_normal | assets/ui/kit/buttons/button_normal.png | 96×96 | Sí | 10/10/10/10 | Button (tema) | Botones secundarios de todas las pantallas | Pendiente (clave en KIT) |
| button_hover | assets/ui/kit/buttons/button_hover.png | 96×96 | Sí | 10/10/10/10 | Button | Ídem, estado hover | Pendiente (clave en KIT) |
| button_pressed | assets/ui/kit/buttons/button_pressed.png | 96×96 | Sí | 10/10/10/10 | Button | Ídem, estado presionado | Pendiente (clave en KIT) |
| button_disabled | assets/ui/kit/buttons/button_disabled.png | 96×96 | Sí | 10/10/10/10 | Button | Ídem, deshabilitado (RECLAMADO, BLOQUEADO) | Pendiente (clave en KIT) |
| button_primary | assets/ui/kit/buttons/button_primary.png | 96×96 | Sí | 10/10/10/10 | Button (`apply_primary`) | Iniciar/Comenzar aventura, Entrar, compras, Reanudar, Seleccionar, Reintentar | Pendiente (clave en KIT) |
| button_primary_hover | assets/ui/kit/buttons/button_primary_hover.png | 96×96 | Sí | 10/10/10/10 | Button | Ídem | Pendiente (clave en KIT) |
| button_primary_pressed | assets/ui/kit/buttons/button_primary_pressed.png | 96×96 | Sí | 10/10/10/10 | Button | Ídem | Pendiente (clave en KIT) |
| tab_normal | assets/ui/kit/buttons/tab_normal.png | 96×64 | Sí | 8/8/8/8 | TabContainer | Progreso (Personajes / Árbol de mejoras) | Pendiente (clave en KIT) |
| tab_selected | assets/ui/kit/buttons/tab_selected.png | 96×64 | Sí | 8/8/8/8 | TabContainer | Ídem | Pendiente (clave en KIT) |
| bar_bg | assets/ui/kit/progress/bar_bg.png | 32×24 | Sí | 4/4/4/4 | ProgressBar (fondo) | HUD, misiones, perfil, carga, combate | Pendiente (clave en KIT) |
| bar_fill | assets/ui/kit/progress/bar_fill.png | 32×24 | Sí | 4/4/4/4 | ProgressBar (relleno, se tiñe por código) | Ídem | Pendiente (clave en KIT) |
| slot_normal | assets/ui/kit/slots/slot_normal.png | 96×96 | Sí | 8/8/8/8 | EquipmentSlot, footer | Ranuras de equipo y mochila, botones del footer | Pendiente (clave en KIT) |
| slot_active | assets/ui/kit/slots/slot_active.png | 96×96 | Sí | 8/8/8/8 | EquipmentSlot, footer | Ranura equipada, opción activa del footer | Pendiente (clave en KIT) |
| hero_card_focus | assets/ui/kit/slots/hero_card_focus.png | 160×220 | Sí | 12/12/12/12 | HeroCarouselCard | Selección de héroe | Pendiente (sin clave en KIT todavía) |

## Iconos (TextureRect, sin nueve cortes)

| Recurso | Ruta de destino | Dimensiones | Transparencia | Componente | Pantallas | Estado |
|---|---|---|---|---|---|---|
| icon_gold | assets/ui/icons/icon_gold.png | 32×32 | Sí | TextureRect | HUD, tienda, victoria, perfil | Pendiente |
| icon_gem | assets/ui/icons/icon_gem.png | 32×32 | Sí | TextureRect | HUD, tienda, misiones, victoria | Pendiente |
| icon_energy | assets/ui/icons/icon_energy.png | 32×32 | Sí | TextureRect | HUD, mazmorras, reintentar | Pendiente |
| icon_attack, icon_heart | assets/ui/icons/ | 32×32 cada uno | Sí | TextureRect | Equipamiento (ATQ / VIDA) | Pendiente |
| icon_mail, icon_settings | assets/ui/icons/ | 32×32 cada uno | Sí | TextureRect dentro de Button | Top HUD (reemplazan ✉ y el texto AJUSTES) | Pendiente |
| icon_coins_s, icon_bag, icon_chest_s, icon_chest_l, icon_chest_xl | assets/ui/icons/ | 64×64 cada uno | Sí | TextureRect | Tienda, ofertas de monedas (reemplazan COINS/BAG/CHEST) | Pendiente |
| icon_energy_pack_s, icon_energy_pack_m, icon_energy_pack_l | assets/ui/icons/ | 64×64 cada uno | Sí | TextureRect | Tienda, ofertas de energía | Pendiente |
| icon_chest_common, icon_chest_epic | assets/ui/icons/ | 96×96 cada uno | Sí | TextureRect | Tienda, baúles | Pendiente |

`assets/iconos main/06_candado.png` y los iconos del footer ya existen y siguen en uso.

## Cabeceras, fondos y logo (TextureRect, sin nueve cortes)

| Recurso | Ruta de destino | Dimensiones | Transparencia | Componente | Pantallas | Estado |
|---|---|---|---|---|---|---|
| header_shop, header_missions, header_upgrades, header_dungeons, header_profile | assets/ui/headers/header_<pantalla>.png | 780×300 (lógico 390×150) | No; borde inferior difuminado | TextureRect (KEEP_ASPECT_COVERED) detrás del título | Tienda, Misiones, Progreso, Mazmorras, Perfil | Pendiente |
| bg_home | assets/ui/backgrounds/bg_home.png | 780×1688 | No | TextureRect a pantalla completa | Inicio | Pendiente |
| bg_dungeons | assets/ui/backgrounds/bg_dungeons.png | 780×1688 | No | TextureRect | Mazmorras | Pendiente |
| bg_victory, bg_defeat | assets/ui/backgrounds/ | 780×1688 cada uno | No | TextureRect | Victoria, Derrota | Pendiente |
| bg_loading | assets/ui/backgrounds/bg_loading.png | 780×1688 | No | TextureRect | Pantalla de carga | Pendiente |
| logo_emberfall | assets/ui/backgrounds/logo_emberfall.png | 560×280 | Sí | TextureRect | Inicio, carga | Pendiente |

## Notas de integración

- `panel_default`, `button_*`, `tab_*` y `bar_*` se aplican en `UiTheme.make_theme()`. Alcanzan a todo lo que use el tema.
- Los sitios con estilo explícito (`add_theme_stylebox_override` con `UiTheme.panel()` o `slot()`: HUD, footer, modales, ranuras) tendrán que pasar por `UiTheme.kit(id, fallback)` en una segunda pasada, pantalla por pantalla.
- Iconos, cabeceras y fondos requieren agregar `TextureRect` en las pantallas. No se hará hasta que existan los archivos.
- Los recursos actuales (`assets/iconos main/*`, `assets/ui/*.svg`, `assets/environment/*`) no se tocan ni se reemplazan hasta validar sus sustitutos.

## Entrega UI_KIT_01 (`assets/ui/kit/UI_KIT_01_individual/`)

Integrado y validado con capturas (claves en `UiTheme.KIT` / `UiTheme.icon`):

| Archivo(s) | Uso actual | Márgenes 9 cortes |
|---|---|---|
| panel_secundario | `panel_default` (tema, tarjetas internas, panel ATQ/VIDA, info de mapa) | 16 |
| panel_principal | `panel_main` (marco de la mochila) | 20 |
| panel_modal | `panel_modal` (Perfil, Configuración, Notificaciones, poderes, pausa) | 20 |
| tarjeta_item | `panel_card` (tarjetas de tienda, misiones, fichas de Perfil) | 18 |
| ranura_vacia | `slot_normal` (ranuras de equipo vacías) | 12 |
| icono_moneda, icono_gema, icono_engrane | Top HUD (oro, joyas, ajustes) | — |
| icono_moneda, icono_bolsa, icono_cofre, icono_energia | Tienda (reemplazan COINS/BAG/CHEST/ENERGY) | — |
| icono_ataque | Equipamiento (ATQ) | — |
| badge_notificacion | Indicador de misiones del footer | — |

Los paneles tienen el interior transparente: el tema los compone sobre un relleno oscuro en tiempo de ejecución (sin archivos extra).

**No utilizables tal como están** (traen contenido dibujado; hay que entregar versiones sin él):
- `boton_primario_*`, `boton_secundario_*`, `boton_aceptar/cancelar/confirmar/eliminar`: el texto está dibujado en la imagen. Hacen falta versiones **sin texto** (normal / hover / presionado / deshabilitado, primario y secundario).
- `barra_*`: incluyen el porcentaje y el relleno a un valor fijo, y `barra_contenedor` es un marco, no un fondo de barra. Hacen falta `bar_bg` (vacío) y `bar_fill` (solo relleno) por separado.
- `marco_heroe_*`: traen el retrato dibujado; hace falta el marco **vacío** (el sprite del héroe debe seguir siendo el del juego).
- `ranura_con_item`, `ranura_epico`, `ranura_equipado`: traen un objeto dibujado; hace falta la ranura vacía con borde de cada estado (los objetos reales se dibujan encima). `ranura_seleccionada` y `ranura_bloqueada` están bien pero aún sin uso (falta una ranura sin la cruz central para botones de forma no cuadrada, como los del footer).
- `ventana_mensaje`: incluye título, texto y botones dibujados; sirve el marco vacío (`panel_modal` ya cubre este caso).
- `badge_comun/poco_comun/raro/epico/legendario/nuevo`: texto dibujado; el juego hoy no muestra estas etiquetas.
- Archivo sobrante: `icono_bolsa.png.tmp.png` (temporal; se puede borrar).
- Aún sin entregar: marco del Top HUD, marco del footer, pestañas, cabeceras, fondos, logo (ver tablas anteriores).

## Entregas posteriores (revisadas el 2026-09-21, importadas en Godot, aún sin integrar)

- `assets/ui/kit/UI_KIT_03_individual/` (23 PNG): botones primario/secundario **sin texto** (normal/presionado/deshabilitado, ~240×78), barras (`barra_progreso_*`, `barra_ronda_*`) con fondo vacío y relleno **separados**, `marco_top_hud_corto/largo`, `marco_footer`, `marco_heroe` (interior vacío), `marco_panel_*` (forma de arco), ranuras vacía / sin cruz / seleccionada / equipada / bloqueada / deshabilitada (164×146). Cubre lo que bloqueaba la entrega UI_KIT_01.
- `assets/ui/kit/UI_KIT_04_individual/` (28 PNG): adornos de esquina, calaveras, divisores (corto/medio/largo/cadena), indicadores (alerta, chat, evento, mejora) y varias **hojas con muchos elementos en una sola imagen** (etiquetas, estados, cursores, flechas, marcadores, ventanas flotantes…); las hojas requieren recorte para poder usarse.
- `assets/ui/headers/UI_KIT_CABEZERAS_individual/` (15 PNG): cabeceras de Carga, Derrota, Héroes, Inicio, Mazmorras, Mejoras, Misiones, Perfil, Tienda y Victoria (737×126–135) + decoradores (línea, línea corta, cadena, esquinas, bat-skull).
- `assets/ui/backgrounds/UI_KIT_FONDOS_individual/` (11 PNG): verticales 207×505 (Héroes, Inicio, Mazmorras, Mejoras, Misiones, Tienda, Victoria) y horizontales ~366×226 (Carga, Derrota, Pausa, Perfil). Son de baja resolución: hay que ampliarlos con filtro *nearest* y recortarlos (relación 0,41 vs 0,46 de la pantalla).
- Los `.zip` originales quedaron dentro de `assets/`; Godot los ignora pero engrosan el repositorio (~3 MB cada uno).
