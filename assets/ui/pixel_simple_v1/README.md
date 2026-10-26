# Emberfall — Pixel art simple

**REVISIÓN EN CURSO:** kit exportado e integrado parcialmente. Ver `STATUS.md`.
Las familias `icons/` y `shop/` usan la entrega adaptada del 24 de septiembre;
sus piezas permanecen pendientes de revisión visual en todas las pantallas.
Los PNG fuente usados para reconstruir el kit están en `source/`.

Kit de interfaz basado en el footer: piedra oscura, biseles violetas discretos,
pequeños cristales cian y siluetas legibles. Arte de baja resolución, sin
calaveras, cuernos, destellos volumétricos ni decoración recargada.

## Organización

- `frames/`: panel reutilizable, ranura de equipo, selección, HUD y footer.
- `hud/`: placa de nivel vacía.
- `buttons/`: acción principal, secundaria y botón +.
- `bars/`: pista vacía y rellenos de experiencia, energía y vida.
- `icons/`: recursos, avisos, misiones, estado y controles.
- `shop/`: monedas, bolsa, cofre de oro, botella de energía y baúles.
- `equipment/`: arma, armadura, casco, amuleto, anillo y botas.
- `navigation/`: los cinco iconos del footer existente, normalizados al kit.
- `backgrounds/`: fondo oscuro discreto compartido por las pantallas.
- `states/`: barras de experiencia, energía y vida al 0, 25, 50, 75 y 100 %.
- `styles/`: recursos Godot para paneles, tarjetas, botones y sus estados.
- `source/`: originales, conservados sin modificar.
- `previews/`: vistas por familia y todos los niveles de llenado.
- `manifest.json`: rutas, dimensiones y clasificación de cada asset.
- `integration.json`: correspondencia con los recursos y pantallas actuales.
- `prompts.json`: prompts, procedencia declarada y estado de revisión por pieza.

## Uso

Aplicar `pixel_theme.tres` al contenedor de la pantalla y usar las variaciones
`PixelPrimary` o `PixelSecondary` en los botones. Los estilos recortan nueve
regiones para que las esquinas conserven su forma al cambiar el tamaño.
Seleccionado y enfoque usan contorno cian; bloqueado y deshabilitado están
atenuados. Los estilos de rareza distinguen común, raro y épico.
En el footer, el overlay de selección conserva la opacidad solicitada de 0.5.

Usar filtrado **Nearest**. Los iconos tienen rejilla nativa de 24, 32 o 48 px;
preferir escalas enteras. No suavizar ni mezclar escalas arbitrarias dentro de
una misma fila. Iconos pequeños de acción: 24 px; recursos/equipo: 32 px;
tienda y navegación: 48 px.

Los PNG no contienen títulos, precios ni cantidades. Superponer Labels con
datos reales, mantener una sola familia tipográfica y tamaños coherentes.
El + ya está incluido en su botón; no duplicarlo con un Label.

Las barras usan la pista por separado del relleno y recortan éste según el
porcentaje real. Los cinco estados son exports de referencia, no límites al
llenado. Para energía se conserva el máximo del juego de 25.

Los productos de la tienda reutilizan estas siluetas según la cantidad:
ofertas pequeñas con la pila, medias con la bolsa y grandes con el cofre.
La cantidad exacta se muestra como texto. Energía usa el rayo para la recarga
gratuita y la botella para los paquetes. Los cofres común y épico comparten
una silueta simple y se distinguen por material y color.

La integración de producción está en curso. Conserva los assets anteriores
mientras haya consumidores; el plan raíz documenta las pantallas migradas y
la validación pendiente. Abre `scenes/ui/PixelUiKitCatalog.tscn` para revisar
el catálogo en Godot.

## Reconstrucción

1. `godot --headless --path . --script tools/build_pixel_ui_kit.gd`
2. `godot --headless --path . --editor --quit`
3. `godot --headless --path . --script tools/build_pixel_ui_theme.gd`

Las piezas recientes proceden de
`assets/ui/emberfall_icons_transparent_2026-09-24/` y se aplican mediante
`tools/apply_delivered_icon_set.py`. `prompts.json` registra cada procedencia y
estado. Los scripts empaquetan sprites y crean estados y recursos de interfaz.
