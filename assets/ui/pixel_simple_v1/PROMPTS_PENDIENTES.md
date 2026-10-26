# Prompts pendientes — Emberfall / pixel art simple

## Alcance exacto

Quedan **20 piezas: 12 nuevas y 8 correcciones**. Este documento contiene un prompt completo por pieza; se pueden copiar de forma independiente. No volver a generar el resto del kit.

Guardar los originales aceptados en `assets/ui/pixel_simple_v1/source/<nombre>.png`. La ruta indicada en cada sección corresponde al export final, relativo a `assets/ui/pixel_simple_v1/`.

**No adjuntar el footer completo como referencia para estos prompts.** En varias generaciones se interpretó como parte de la composición y apareció detrás de los iconos. Los prompts especifican el estilo mediante texto. Si se usa referencia para un objeto, debe ser sólo ese objeto aislado, nunca una interfaz completa.

Las imágenes fallidas se conservan únicamente como historial; no utilizarlas como assets finales. Los rellenos anteriores que parecen marcos vacíos deben regenerarse, no reutilizarse.

## Dirección visual común

- Pixel art simple, siluetas claras y pocos colores.
- Piedra violeta oscura con cian como acento; identidad discreta.
- Misma escala lógica dentro de cada familia: controles 24 px, recursos/equipo 32 px, tienda 48 px.
- PNG con alfa real. El fondo de menú es la única pieza opaca.
- No generar valores, precios, nivel o porcentajes dentro del dibujo.
- Cada llamada produce UNA pieza. No pedir una lámina con las 20 juntas.

## 1. Correcciones necesarias

### 1. bar_track

Destino final: `bars/bar_track.png` · Rejilla: **96 × 16 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: bar_track
REJILLA LÓGICA: 96 × 16 px
DESCRIPCIÓN: Una sola pista de barra horizontal VACÍA, de proporción 6:1. Interior opaco azul noche #141827. Borde de piedra violeta de 2 píxeles lógicos, esquinas recortadas en uno o dos escalones. Un único espacio interior continuo.
RESTRICCIONES ESPECÍFICAS: No incluir separadores, casillas, relleno de color, iconos, cristales, marcas de porcentaje ni adornos en los extremos.
```

### 2. fill_xp

Destino final: `bars/fill_xp.png` · Rejilla: **96 × 12 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: fill_xp
REJILLA LÓGICA: 96 × 12 px
DESCRIPCIÓN: Una sola tira horizontal de relleno de experiencia COMPLETA, de proporción 8:1. Toda su superficie debe ser violeta #9255d8, con una sola línea superior de un píxel en lavanda #c897f4. Esquinas con un escalón pequeño. Opaca dentro de la silueta.
RESTRICCIONES ESPECÍFICAS: No dibujar pista vacía, borde de piedra, marco, fondo azul oscuro, cantidades, partículas ni cristal. Es únicamente el relleno que se recortará en Godot.
```

### 3. fill_energy

Destino final: `bars/fill_energy.png` · Rejilla: **96 × 12 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: fill_energy
REJILLA LÓGICA: 96 × 12 px
DESCRIPCIÓN: Una sola tira horizontal de relleno de energía COMPLETA, de proporción 8:1. Toda su superficie debe ser turquesa #24bfc5, con una sola línea superior de un píxel en cian claro #87f4ec. Esquinas con un escalón pequeño. Opaca dentro de la silueta.
RESTRICCIONES ESPECÍFICAS: No dibujar pista vacía, borde de piedra, marco, rayo, fondo azul oscuro, cantidades ni efectos de luz. Es únicamente el relleno.
```

### 4. fill_health

Destino final: `bars/fill_health.png` · Rejilla: **96 × 12 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: fill_health
REJILLA LÓGICA: 96 × 12 px
DESCRIPCIÓN: Una sola tira horizontal de relleno de vida COMPLETA, de proporción 8:1. Toda su superficie debe ser rojo coral #d96168, con una sola línea superior de un píxel en rojo claro #f29a9f. Esquinas con un escalón pequeño. Opaca dentro de la silueta.
RESTRICCIONES ESPECÍFICAS: No dibujar pista vacía, borde de piedra, marco, corazón, fondo azul oscuro, cantidades, partículas ni efectos. Es únicamente el relleno.
```

### 5. arrow

Destino final: `icons/arrow.png` · Rejilla: **24 × 24 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: arrow
REJILLA LÓGICA: 24 × 24 px
DESCRIPCIÓN: Un solo chevrón grueso apuntando a la DERECHA, formado por dos trazos escalonados de color marfil #ecedf4. Grosor interior aproximado de 3 píxeles lógicos y contorno azul noche de 1 píxel. Centrar y dejar 2 píxeles libres alrededor. La flecha izquierda se obtendrá reflejando esta pieza.
RESTRICCIONES ESPECÍFICAS: No dibujar un botón, placa, barra, marco, texto, flechas adicionales ni fondo detrás del símbolo.
```

### 6. energy

Destino final: `icons/energy.png` · Rejilla: **32 × 32 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: energy
REJILLA LÓGICA: 32 × 32 px
DESCRIPCIÓN: Un solo rayo de energía aislado: silueta clásica en zigzag, cuerpo cian #42d8e8, una cara de sombra turquesa #238d9a y contorno azul noche de 1 píxel. Forma compacta y reconocible al mostrarse pequeña. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: No dibujar footer, barra, casilla, placa, aura, destellos ni fragmentos de cristal. La única figura es el rayo.
```

### 7. gem

Destino final: `icons/gem.png` · Rejilla: **32 × 32 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: gem
REJILLA LÓGICA: 32 × 32 px
DESCRIPCIÓN: Una sola gema aislada en forma de rombo vertical simétrico. Cuatro facetas grandes y planas, magenta #c747e0, violeta medio #9255d8, violeta oscuro #55446e y un tono claro discreto. Contorno azul noche de 1 píxel y diagonales escalonadas. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: No dibujar footer, barra, marco, placa, gemas adicionales, aura, estrellas ni chispas.
```

### 8. gold_pile

Destino final: `shop/gold_pile.png` · Rejilla: **48 × 48 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: gold_pile
REJILLA LÓGICA: 48 × 48 px
DESCRIPCIÓN: Una sola pila compacta de monedas: dos montones bajos de diferente altura y tres monedas sueltas delante. Oro base #dfaa39, luz #f4d06a y sombra #9b652b; contorno marrón oscuro. Silueta clara con pocos bloques de color y sin grabados pequeños. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: No dibujar footer, bandeja, pedestal, tarjeta, precio, marco, bolsa, cofre, tesoro desbordado ni brillos externos.
```

## 2. Piezas nuevas pendientes

### 9. chest_epic

Destino final: `shop/chest_epic.png` · Rejilla: **48 × 48 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: chest_epic
REJILLA LÓGICA: 48 × 48 px
DESCRIPCIÓN: Un único cofre de botín ÉPICO CERRADO, compacto, visto en tres cuartos suaves. Cuerpo violeta oscuro, dos bandas de metal violeta apagado y un pestillo cuadrado central con una diminuta gema magenta. Mantener una silueta sencilla equivalente a un cofre común: tapa baja y base rectangular. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: No añadir cuernos, púas, alas, calaveras, runas, aura, monedas, destellos, cadenas ni ornamentación compleja. Sin placa o tarjeta.
```

### 10. weapon

Destino final: `equipment/weapon.png` · Rejilla: **32 × 32 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: weapon
REJILLA LÓGICA: 32 × 32 px
DESCRIPCIÓN: Una sola espada corta, en diagonal desde abajo a la izquierda hacia arriba a la derecha. Hoja plateada con una única línea de luz cian, guarda recta violeta y empuñadura marrón. Contorno azul noche. Pocos bloques de color, silueta claramente legible. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: Sin runas, fuego, gemas grandes, partículas, pedestal, mano, personaje, marco ni tarjeta.
```

### 11. armor

Destino final: `equipment/armor.png` · Rejilla: **32 × 32 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: armor
REJILLA LÓGICA: 32 × 32 px
DESCRIPCIÓN: Una sola coraza frontal compacta con dos hombros cortos. Metal gris violáceo en tres tonos, contorno azul noche y un diminuto acento cian central. Hueco de cuello simple, torso simétrico. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: Sin casco, personaje, brazos completos, capa, pinchos, alas, grabados, marco ni tarjeta.
```

### 12. ring

Destino final: `equipment/ring.png` · Rejilla: **32 × 32 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: ring
REJILLA LÓGICA: 32 × 32 px
DESCRIPCIÓN: Un solo anillo de plata visto en tres cuartos muy leves. Aro grueso de pocos píxeles con hueco central transparente y una única gema pequeña violeta en la parte superior. Dos o tres tonos de plata y contorno azul noche. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: Sin filigrana, cadenas, joyas adicionales, brillo externo, mano, pedestal, marco ni tarjeta.
```

### 13. amulet

Destino final: `equipment/amulet.png` · Rejilla: **32 × 32 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: amulet
REJILLA LÓGICA: 32 × 32 px
DESCRIPCIÓN: Un solo amuleto redondo pequeño. Montura violeta oscura, una piedra cian central y una argolla corta de plata arriba que indica que es un colgante. Contorno azul noche, forma compacta con pocos píxeles. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: Sin cadenas largas, espirales mágicas, runas, estrellas, alas, personaje, placa, marco ni tarjeta.
```

### 14. boots

Destino final: `equipment/boots.png` · Rejilla: **32 × 32 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: boots
REJILLA LÓGICA: 32 × 32 px
DESCRIPCIÓN: Un único icono que representa un par de botas cortas de cuero marrón. Una bota ligeramente adelantada, puños violeta apagado y suelas oscuras. Tres tonos como máximo para el cuero, contorno azul noche. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: Sin alas, fuego, piernas, personaje, hebillas complejas, marco, tarjeta ni efectos de movimiento.
```

### 15. heart

Destino final: `icons/heart.png` · Rejilla: **24 × 24 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: heart
REJILLA LÓGICA: 24 × 24 px
DESCRIPCIÓN: Un solo corazón de vida, simétrico, rojo coral #d96168 con una sombra #9f3949 y un pequeño grupo de píxeles de luz #f29a9f. Borde azul noche de 1 píxel y contorno escalonado. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: Sin latido dibujado, alas, cruces, gotas, marco, placa ni brillo exterior.
```

### 16. speed

Destino final: `icons/speed.png` · Rejilla: **24 × 24 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: speed
REJILLA LÓGICA: 24 × 24 px
DESCRIPCIÓN: Un solo icono de velocidad: una bota marrón pequeña apuntando a la derecha, con exactamente dos trazos horizontales cian cortos detrás. Contorno azul noche y máximo tres tonos por material. Los trazos forman parte del mismo icono compacto. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: Sin alas detalladas, plumas, personaje, suelo, partículas, marco, placa ni texto.
```

### 17. target

Destino final: `icons/target.png` · Rejilla: **24 × 24 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: target
REJILLA LÓGICA: 24 × 24 px
DESCRIPCIÓN: Un solo objetivo circular pequeño: aro exterior violeta, aro intermedio marfil y centro cian. Silueta circular escalonada y contorno azul noche. Usar formas concéntricas gruesas y legibles, sin detalles finos. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: Sin soporte, paisaje, múltiples dianas, texto, marco o placa. No añadir detalles que dificulten reconocer el centro.
```

### 18. play

Destino final: `icons/play.png` · Rejilla: **24 × 24 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: play
REJILLA LÓGICA: 24 × 24 px
DESCRIPCIÓN: Un solo triángulo grueso de reproducir apuntando a la derecha. Color cian #42d8e8, sombra mínima y contorno azul noche de 1 píxel. Diagonal escalonada, silueta limpia. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: Sin botón, círculo de fondo, placa, marco, texto ni otros símbolos.
```

### 19. pause

Destino final: `icons/pause.png` · Rejilla: **24 × 24 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: pause
REJILLA LÓGICA: 24 × 24 px
DESCRIPCIÓN: Un solo símbolo de pausa compuesto por dos barras verticales gruesas e iguales, de color marfil #ecedf4, con contorno azul noche de 1 píxel. Separación clara y composición centrada. Dejar 2 píxeles libres alrededor.
RESTRICCIONES ESPECÍFICAS: Sin botón, círculo de fondo, placa, marco, texto ni otros símbolos.
```

### 20. background

Destino final: `backgrounds/background.png` · Rejilla: **192 × 320 px**.

```text
Crea UN ÚNICO asset independiente para la interfaz de Emberfall. Estilo: PIXEL ART SIMPLE de baja resolución, coherente con marcos de piedra oscura y pequeños detalles violeta/cian. Píxeles cuadrados visibles, contornos escalonados y limpios, grupos de píxeles grandes, máximo tres tonos por material. Sin suavizado, apariencia vectorial, render 3D, textura pintada, ruido, degradados continuos, bloom ni efectos extravagantes.

Paleta: contorno azul noche #101321; interior oscuro #141827; piedra violeta #55446e y luz #87739f; acento cian #42d8e8; texto/símbolos marfil #ecedf4. Usar los colores adicionales del objeto sólo cuando se indiquen.

Entregar una pieza aislada, completa y centrada, sin cortes. PNG RGBA con transparencia REAL fuera de su silueta: no dibujar tablero de ajedrez, fondo negro ni sombra exterior. Única excepción: el fondo de menú debe ser opaco.

NO crear un footer, HUD completo, pantalla, lámina de sprites, collage ni varias alternativas. NO añadir marcos, casillas o botones salvo que esa pieza los requiera explícitamente. No incluir palabras, nombres de archivo, números, precios ni marcas de agua.

El tamaño indicado es la REJILLA LÓGICA del sprite final. Si se entrega ampliado, cada píxel debe ampliarse uniformemente con nearest-neighbor; no inventar detalle adicional. Las cantidades, textos y porcentajes se dibujarán por código.

PIEZA: background
REJILLA LÓGICA: 192 × 320 px
DESCRIPCIÓN: Un solo fondo vertical de menú de proporción 3:5, completamente OPACO. Azul noche muy oscuro #101321. El 85 % central es tranquilo y prácticamente uniforme para colocar texto y controles. Bloques grandes y muy discretos de piedra #141827 sólo junto a los bordes; dos pequeños acentos violeta apagado en las esquinas inferiores. Acabado pixel art con zonas de color planas.
RESTRICCIONES ESPECÍFICAS: Sin marco visible que encierre una tarjeta, paisajes, personajes, estrellas, humo, luces fuertes, degradados suaves, ruido, texto ni interfaz montada.
```

## 3. Criterios para aceptar cada resultado

1. Contiene sólo la pieza solicitada, no un footer ni una pantalla completa.
2. La silueta sigue siendo reconocible al tamaño lógico indicado.
3. No tiene decoración extravagante, texturas suaves ni detalles diminutos.
4. Los iconos no incluyen una placa detrás; los rellenos no incluyen su pista.
5. El alfa exterior es transparente, sin tablero pintado ni fondo negro.
6. No hay palabras, precios o cantidades incorporados en el dibujo.
7. Los rellenos tienen color en toda su superficie y admiten recorte horizontal.
8. Todas las piezas se ven coherentes al colocarlas juntas sobre #101321.

## 4. Preparación posterior en Godot

- Revisar visualmente los originales disponibles que aún figuran como `review_pending`.
- Sustituir en `prompts.json` la procedencia y el estado de cada pieza aceptada.
- Quitar el estado global de bloqueo sólo cuando las piezas necesarias estén completas.
- Ejecutar el empaquetado: `tools/build_pixel_ui_kit.gd`.
- Importar PNG en Godot y ejecutar `tools/build_pixel_ui_theme.gd`.
- Revisar `scenes/ui/PixelUiKitCatalog.tscn` y renderizar el catálogo.
- Exportar los 15 estados de barras: experiencia, energía y vida al 0/25/50/75/100 %.
- Mantener el llenado real continuo mediante código: los estados no son límites.
- Validar paneles y botones con nueve segmentos, y filtros nearest.
- Preparar el ZIP del kit aprobado.

La integración de este kit en todas las pantallas sigue siendo una fase posterior. No modificar datos del jugador, lógica de compras ni navegación durante la generación.
