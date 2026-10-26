# Emberfall — Tres jefes iniciales

Cada carpeta contiene la lámina completa y tres PNG independientes:

- `idle.png`: pose base.
- `attack_01.png`: primer patrón.
- `attack_02.png`: segundo patrón.

## 01 — Coloso Rúnico

- Patrón 1: embestida lineal. Debe telegrafiar la dirección antes de avanzar.
- Patrón 2: golpe al suelo. Genera daño circular alrededor del punto de impacto.

## 02 — Guardián Hueco

- Patrón 1: barrido amplio con alabarda. Daño en arco frontal.
- Patrón 2: abanico de tres proyectiles rúnicos.

## 03 — Matriarca de Ceniza

- Patrón 1: cono frontal corto de fuego.
- Patrón 2: tres zonas rúnicas con explosión retardada.

## Aplicación en Godot

Las imágenes de ataque representan poses y efectos de referencia. Conviene separar el cuerpo del jefe y los efectos en nodos diferentes para que:

- Las colisiones no dependan del tamaño visible del efecto.
- Los proyectiles puedan dirigirse dinámicamente.
- Las zonas puedan fijarse en posiciones reales del mapa.
- El jefe conserve el mismo sprite mientras el efecto se anima por separado.

Importar como pixel art con filtrado y mipmaps desactivados. Mantener escala entera siempre que sea posible.
