# TopHUD simple

Revisión de bajo detalle: superficies planas, bordes finos violeta y acentos
cian. Sin cuernos, calaveras, grietas, partículas ni reflejos recargados.
Creado con la herramienta integrada image_gen. Prompts finales: `prompts.json`.

## Assets independientes

- `frame.png`: marco exterior relleno, sin contenido.
- `level.png`: placa de nivel vacía, centro geométrico para el número.
- `track.png`: casilla vacía para experiencia, energía, monedas o gemas.
- `xp_fill.png`: relleno púrpura completo de experiencia.
- `energy_fill.png`: relleno turquesa completo de energía.
- `energy_icon.png`, `coin_icon.png`, `gem_icon.png`: iconos separados.
- `add.png`: botón con + incorporado, no necesita otro Label.

Los originales generados se conservan en `source/`. Los exports tienen alfa
transparente fuera de la pieza y fondos opacos donde corresponde.

## Barras dinámicas

`states/` contiene 0, 25, 50, 75 y 100 % para experiencia y energía.
`preview.png` presenta los assets y los estados de vacío a lleno.

Para cualquier valor intermedio, usa `scripts/ui/HudFillBar.gd`, asigna
`track_texture` y `fill_texture` y llama `set_amount(actual, maximo)`.
El relleno se recorta sin deformarlo. Energía conserva máximo 25; experiencia
usa el requisito real del nivel actual. Nivel y cantidades se dibujan con
Labels desde GameState, nunca están grabados en los PNG.

La escena `scenes/ui/TopHudAssetPreview.tscn` prueba ambas barras con sliders.
El TopHUD principal usa estos assets, con experiencia y energía dinámicas.
La versión más ornamentada se conserva en `modular_v2/`.

Para reconstruir exports y estados:
`godot --headless --path . --script tools/build_tophud_pack.gd`.
