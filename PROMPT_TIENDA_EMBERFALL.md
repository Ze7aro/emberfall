# EMBERFALL — Especificación para generar la tienda

## Objetivo

Generar una pantalla de **Tienda** para *Emberfall*, un roguelike 2D móvil vertical. La IA debe crear un mockup visual completo y coherente con las demás pantallas del juego. No debe copiar marcas, personajes ni recursos de otros videojuegos.

## Formato de salida

- Pantalla móvil vertical, relación **9:16**.
- Resolución recomendada: **1254 × 2230 px** o equivalente proporcional.
- Vista frontal de interfaz, sin perspectiva de teléfono ni manos sosteniéndolo.
- Mockup de alta fidelidad, listo para usarse como referencia de implementación en Godot.
- Toda la pantalla debe poder interpretarse como un contenido con desplazamiento vertical.

## Dirección artística de Emberfall

- Pixel art de fantasía oscura, detallado pero legible.
- Fondo violeta muy oscuro, casi negro.
- Paneles, divisores y tarjetas construidos con piedra oscura y metal púrpura.
- Bordes gruesos, sombras marcadas y terminaciones pixeladas.
- Runas, energía y detalles luminosos en turquesa.
- Monedas y botones de compra en dorado cálido.
- Cofre épico con brillo violeta intenso y runas turquesa.
- Formas grandes y limpias, pensadas para leerse en un teléfono.
- Acabado pulido de videojuego móvil premium.
- Evitar realismo fotográfico, ciencia ficción, gore, líneas finas y exceso de partículas.

## Estructura general

1. Encabezado central con el título exacto **“TIENDA”**.
2. Botón de cierre con una **X** en la esquina superior derecha.
3. Sección **“MONEDAS”**.
4. Sección **“ENERGÍA”**.
5. Sección **“BAÚLES”**.

No incluir personajes. No incluir el TopHud ni el NavigationFooter dentro del contenido generado: estos componentes persistentes se superpondrán desde Godot. Reservar márgenes seguros arriba y abajo para ellos.

## Sección 1 — Monedas

Crear exactamente **6 tarjetas**, distribuidas en una grilla de **3 columnas × 2 filas**.

| Opción | Cantidad | Apariencia | Botón |
| --- | ---: | --- | --- |
| 1 | 100 monedas | Pequeño montón de monedas | **GRATIS** en verde |
| 2 | 500 monedas | Bolsa pequeña | Compra dorada |
| 3 | 1.200 monedas | Bolsa mediana llena | Compra dorada |
| 4 | 3.000 monedas | Bolsa grande con monedas alrededor | Compra dorada |
| 5 | 6.000 monedas | Cofre abierto con monedas | Compra dorada |
| 6 | 12.000 monedas | Cofre grande y abundante | Compra dorada |

Reglas:

- Solo la primera opción es gratuita.
- Mostrar claramente la cantidad y un icono de moneda dorada.
- El botón gratuito debe decir exactamente **“GRATIS”**.
- Los demás botones pueden mostrar costos provisionales en gemas: **50, 120, 250, 500 y 1.000**.
- La recompensa gratuita debe indicar visualmente que se reclama una vez y luego entra en espera; no agregar textos largos al mockup.

## Sección 2 — Energía

Crear exactamente **3 tarjetas** en una sola fila.

| Opción | Cantidad | Apariencia | Botón |
| --- | ---: | --- | --- |
| 1 | 20 de energía | Dos frascos turquesa | **GRATIS** en verde |
| 2 | 100 de energía | Grupo de frascos | Compra dorada, costo provisional 80 gemas |
| 3 | 250 de energía | Caja con varios frascos | Compra dorada, costo provisional 180 gemas |

Reglas:

- Solo la primera opción es gratuita.
- Usar un icono de rayo turquesa para representar energía.
- Mantener la energía visualmente distinta de las gemas usadas como precio.

## Sección 3 — Baúles de equipo

Crear exactamente **2 tarjetas grandes**, una junto a la otra.

### Baúl común

- Título exacto: **“BAÚL COMÚN”**.
- Cofre de madera oscura reforzado con hierro.
- Precio provisional: **100 gemas**.
- Entrega piezas de equipo con estas rarezas:
  - Normal: probabilidad alta.
  - Poco común: probabilidad media.
  - Raro: probabilidad baja.
- Mostrar chips de rareza: **NORMAL · POCO COMÚN · RARO**.

### Baúl épico

- Título exacto: **“BAÚL ÉPICO”**.
- Cofre de metal púrpura, más grande y ornamentado.
- Runas turquesa y aura violeta controlada.
- Precio provisional: **300 gemas**.
- Entrega piezas de equipo con estas rarezas:
  - Raro: probabilidad media.
  - Épico: probabilidad alta.
- Mostrar chips de rareza: **RARO · ÉPICO**.

Los baúles entregan exclusivamente objetos de equipamiento. No deben parecer paquetes de monedas ni contener personajes.

## Código visual de rarezas

| Rareza | Color |
| --- | --- |
| Normal | Gris claro |
| Poco común | Verde |
| Raro | Azul |
| Épico | Violeta |

## Reglas de UX

- Todos los objetos deben tener una silueta clara y ocupar la mayor parte de su tarjeta.
- La información debe seguir este orden: objeto, cantidad o nombre, precio/botón.
- Los botones deben tener áreas táctiles grandes y consistentes.
- **GRATIS** debe tener mayor contraste que los botones de compra.
- Separar las secciones mediante encabezados de piedra claramente visibles.
- Evitar párrafos dentro de la interfaz.
- No usar precios en dinero real en este mockup.
- No inventar ofertas adicionales, promociones, personajes, pases, anuncios ni monedas nuevas.

## Prompt final listo para una IA generadora de imágenes

```text
Create a high-fidelity portrait mobile game shop UI for EMBERFALL, a dark-fantasy 2D vertical roguelike. Use a 9:16 composition with dark violet-black background, chunky purple stone and painted-metal frames, pixel-edged details, strong shadows, turquoise runic glow and warm golden purchase buttons. Premium polished pixel-art-inspired mobile game interface, highly readable at phone size.

At the top place the exact Spanish title “TIENDA” and a compact X close button. The screen is vertically scrollable and contains exactly three sections:

1. “MONEDAS”: exactly six cards in a 3-column by 2-row grid. Quantities: 100, 500, 1.200, 3.000, 6.000 and 12.000. Progress visually from a small coin pile to bags and large treasure chests. The 100-coin card has a bright green button labeled exactly “GRATIS”. The other five cards have gold gem-price buttons showing 50, 120, 250, 500 and 1.000.

2. “ENERGÍA”: exactly three cards in one row. Quantities: 20, 100 and 250, represented by turquoise energy bottles and a lightning icon. The 20-energy card has a bright green button labeled exactly “GRATIS”. The other buttons show 80 and 180 gems.

3. “BAÚLES”: exactly two large cards side by side. “BAÚL COMÚN” is a dark wooden chest reinforced with iron, priced at 100 gems, with rarity chips “NORMAL · POCO COMÚN · RARO”. “BAÚL ÉPICO” is an ornate purple-metal chest with restrained violet aura and turquoise runes, priced at 300 gems, with rarity chips “RARO · ÉPICO”. Both chests contain equipment items only.

Use these rarity colors: normal grey, uncommon green, rare blue, epic violet. Keep all Spanish labels correctly spelled and large enough to read. Reserve safe empty margins for an external persistent TopHud and NavigationFooter, but do not draw those components. No characters, no real-money prices, no sci-fi, no gore, no photorealism, no tiny particles, no watermark, no copied branding or recognizable assets from other games. Do not add or remove offers: exactly 6 coin products, 3 energy products and 2 equipment chests.
```

## Validación obligatoria

Antes de aceptar la imagen, comprobar:

- [ ] Es inequívocamente una pantalla de Emberfall.
- [ ] Hay 6 opciones de monedas y solo la primera es gratis.
- [ ] Hay 3 opciones de energía y solo la primera es gratis.
- [ ] Hay exactamente 2 baúles.
- [ ] El baúl común entrega normal, poco común o raro.
- [ ] El baúl épico entrega raro o épico.
- [ ] Los textos principales están correctamente escritos en español.
- [ ] No aparecen personajes ni elementos de otras franquicias.
- [ ] La composición deja margen para TopHud y NavigationFooter externos.

## Nota de implementación

Las cantidades, costos y probabilidades son valores iniciales de diseño y deben quedar configurables mediante datos en Godot; no deben codificarse directamente dentro de la lógica de cada tarjeta.
