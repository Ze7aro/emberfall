# Candidatos para rehacer al estilo de Emberfall

Los IDs apuntan a recortes de referencia en `sprites/` y se refieren a la cuadrícula de origen (fila y columna, empezando en cero). Son propuestas de motivos para redibujar, no assets listos para integrar.

## Prioridad actual: combate y estados

| Necesidad de Emberfall | Referencias elegidas | Uso propuesto |
|---|---|---|
| Quemadura / fuego | `bof6_item_boosters/r07_c00.png` (vela con llama) | Redibujar solo la llama como estado de quemadura, separándola de la vela y haciéndola legible a 16–24 px. |
| Veneno / consumible | `bof6_item_boosters/r01_c00.png` (poción morada), `bof6_miscellaneous/r02_c04.png` (grupo de frascos) | Referencia de silueta para una gota o vial venenoso. Simplificar; no copiar el frasco ornamentado. |
| Habilidades de ataque | `bof6_item_boosters/r00_c06.png` (espada), `bof6_miscellaneous/r00_c08.png` (armas cruzadas) | Crear símbolos pequeños para disparo/proyectil o daño; evitar duplicar el icono de arma del equipo. |
| Escarcha / elemento | `bof6_materials/r00_c06.png` (esfera clara), `bof6_miscellaneous/r02_c03.png` (cristales con hierbas) | Referencias de forma/color para rehacer un cristal de hielo cian. No son iconos de congelamiento listos. |
| Buff / mejora temporal | `bof6_item_boosters/r00_c04.png` (destello), `bof6_item_boosters/r02_c08.png` (emblema ornamental) | Motivos para distinguir mejoras temporales; conservar solo la silueta básica en el redibujo. |
| Regeneración / vida | `bof6_item_boosters/r00_c05.png` (corazón) | Emberfall ya tiene el icono base de vida. Solo redibujar una variante de regeneración si la interfaz de combate necesita indicar ese estado. |

El atlas de RPG Maker se conserva entero para consulta, pero no se escogieron sprites individuales: sus celdas son diminutas y mezclan iconos con abreviaturas/estados de otra interfaz. Su `contact_sheet.png` sirve para encontrar convenciones generales, no para calcar.

## Cotejo con la lista de iconos de interfaz y tienda

Los motivos de la columna central sí aparecen en las láminas adjuntas. Son referencias para rehacer con el estilo de Emberfall, no archivos listos para integrar. “Falta” significa que no encontré un motivo suficientemente claro para esa función en estas cinco imágenes.

| Asset requerido | Referencia encontrada | Resultado |
|---|---|---|
| `close` | `bof6_miscellaneous/r19_c05.png` (X) | Se puede redibujar. |
| `arrow` | `bof6_miscellaneous/r01_c04.png` (flecha hacia arriba) | Se puede adaptar y orientar hacia la derecha. |
| `lock` | `bof6_miscellaneous/r07_c00.png` | Se puede redibujar. |
| `check` | `rpgmaker_vxace_miscellaneous/r21_c03.png` (tilde) | Hay una tilde de referencia; redibujar sin el color/estilo del original. `bof6_miscellaneous/r19_c06.png` es un botón “OK”, útil para aceptar, pero no sustituye a la tilde. |
| `mail` | `bof6_miscellaneous/r03_c07.png` | Sobre sellado; se puede simplificar como notificación/correo. |
| `missions` | `bof6_miscellaneous/r06_c08.png` | Papel enrollado/sellado; buen motivo para misiones. |
| `energy` | `bof6_miscellaneous/r02_c04.png` | Referencia secundaria de frascos; la botella eléctrica de WhatsApp es una guía más clara para este recurso. |
| `coin` | `bof6_miscellaneous/r06_c01.png` | Monedas visibles; redibujar como icono simple. |
| `gem` | `bof6_materials/contact_sheet.png` | Hay cristales/gemas facetados; elegir un recorte concreto al diseñar la versión final. |
| `heart` | `bof6_item_boosters/r00_c05.png` | Corazón visible; redibujar para que coincida con Emberfall. |
| `speed` | `bof6_miscellaneous/r00_c07.png` (reloj/cronómetro) | Motivo de tiempo/rapidez disponible; se puede estilizar como velocidad. |
| `target` | Imagen adjunta `watermarked_img_13769176373749304400 (1).jpg` (cuarto icono) | Mira circular; redibujar simplificada al estilo del juego. |
| `play` | Imagen adjunta `watermarked_img_13769176373749304400 (1).jpg` (segundo icono) | Triángulo reproducir. |
| `pause` | Imagen adjunta `watermarked_img_13769176373749304400 (1).jpg` (tercer icono) | Dos barras de pausa. |
| `gold_pile` | `bof6_miscellaneous/r06_c01.png`; foto WhatsApp `18.22.47 (1)` y `18.22.47` | Monedas apiladas; las dos fotos adicionales dan variaciones de cantidad para packs de compra. |
| `gold_bag` | `bof6_miscellaneous/r07_c06.png`; foto WhatsApp `18.22.47 (2)` | Bolsa de monedas como alternativa visual del pack. |
| `gold_chest` | `bof6_miscellaneous/r12_c03.png` | Referencia de cofre dorado ya compartida. Está cerrado; para cumplir la variante abierta, redibujar con la tapa levantada. |
| `energy_bottle` | Foto WhatsApp `18.19.07` | Botella con rayo explícito; crear una versión de una unidad y variantes de muchas unidades/stack. |
| `chest_common` | `bof6_miscellaneous/r07_c01.png` | Cofre cerrado de aspecto común. |
| `chest_epic` | `bof6_miscellaneous/r12_c03.png` | Cofre cerrado con marco/detalles dorados, válido como referencia épica. |

**Resumen:** Los 20 assets de la lista tienen ahora una referencia identificada. La nueva imagen aporta `target`, `play` y `pause` (y un motivo adicional de auto-play). El `gold_chest` ya estaba referenciado por `r12_c03`; como ese cofre está cerrado, solo falta convertirlo en variante abierta durante el redibujado. La botella eléctrica y las referencias de monedas/bolsa/cofres también sirven para crear las variantes de compra de energía y oro.

El proyecto ya tiene sus propios archivos para esta lista dentro de `assets/ui/pixel_simple_v1`; este cotejo identifica qué podemos redibujar a partir de las imágenes que compartiste, no qué archivos activos faltan en el juego.

## Solo para sistemas futuros

El atlas `bof6_materials` ofrece minerales, cristales, plantas, flores, peces, partes de criaturas, cuero y lingotes (`contact_sheet.png` para elegirlos visualmente). Emberfall no tiene actualmente un inventario de crafting/materiales que justifique agregarlos. Dejarlos fuera de la tanda actual evita introducir categorías que el juego aún no usa.

## Excluido de la selección

No se seleccionan recortes directos de `ffxiii_status_icons`: la propia imagen indica que el material tiene copyright de Square Enix. Puede consultarse solo para entender convenciones visuales de estados; no se reproduce su diseño.
