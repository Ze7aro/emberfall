# TopHUD modular V2

Paquete inspirado en la referencia: armadura de obsidiana violeta, cristales
cian, fondo azul oscuro, experiencia púrpura y energía turquesa. Generado con
la herramienta integrada de imágenes, una imagen independiente por pieza.
Los originales con alfa están en `source/`; no se modifican los assets anteriores.

## Piezas

| Archivo | Función |
| --- | --- |
| frame.png | Marco exterior con interior relleno, sin números ni casillas |
| level.png | Placa de nivel vacía para superponer un Label |
| track.png | Casilla vacía compartida por barras y recursos |
| xp_fill.png | Relleno completo de experiencia |
| energy_fill.png | Relleno completo de energía |
| energy_icon.png | Rayo de energía |
| coin_icon.png | Moneda |
| gem_icon.png | Gema |
| add.png | Botón con signo + incorporado |

`states/` contiene experiencia y energía al 0, 25, 50, 75 y 100 %.
`preview.png` muestra las piezas y ambas series de estados (de vacío a lleno).
Los estados son ejemplos y exports listos para usar, no límites a los valores.

## Uso dinámico en Godot

`scripts/ui/HudFillBar.gd` dibuja la pista y recorta el relleno según un valor
continuo de 0 a 1, sin comprimir horizontalmente el dibujo conforme cambia.
Asigna `track_texture` y `fill_texture`; luego llama
`set_amount(valor_actual, valor_maximo)`. Para energía, el máximo del juego
sigue siendo 25. Para experiencia, usa el requisito real del nivel actual.
Si el máximo es cero o negativo, la barra aparece vacía.

Los números de nivel, experiencia, monedas y gemas deben ser Labels alimentados
por GameState, nunca textos incluidos en los PNG. Monedas y gemas no tienen
porcentaje de llenado: sus casillas usan solamente `track.png`.

El botón ya contiene +: no superponer otro signo. Hover puede usar
`modulate = Color(1.15, 1.15, 1.15)`; pressed, `Color(0.75, 0.85, 0.95)`;
disabled, `Color(0.45, 0.45, 0.50)`, además de desactivar la interacción.

Esta variante ornamentada se conserva como referencia. La revisión vigente,
más simple, está en `modular_v3_simple/`; la escena de prueba usa esa revisión.

Los prompts finales se guardan en `prompts.json`.
El script `tools/build_tophud_pack.gd` exporta ahora la revisión simple.
