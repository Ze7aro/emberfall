# Onda Orbital — lunas dinámicas

La habilidad comienza con **2 lunas** y puede aumentar progresivamente hasta un máximo de **6**.

## Contenido

- `moon_spritesheet.png`: animación horizontal de una única luna, 3 frames.
- `moon_frame_00.png`: brillo inicial.
- `moon_frame_01.png`: pulso mágico intenso.
- `moon_frame_02.png`: brillo descendente.
- `PROMPT_IMPLEMENTACION_GODOT.md`: instrucción lista para pasar a una IA que trabaje sobre el proyecto.

## Decisión técnica

No se incluye el personaje, la órbita ni varias lunas dentro de las imágenes. Godot debe instanciar el mismo sprite entre 2 y 6 veces y calcular sus posiciones. Esto permite mejorar la habilidad sin crear un spritesheet distinto para cada nivel.

## Importación en Godot 4

- Desactivar filtrado y mipmaps.
- Usar escalado entero cuando sea posible.
- Configurar `AnimatedSprite2D` con los 3 frames en bucle.
- Mantener el centro y el tamaño visual idénticos en todos los frames.
- Crear una `Area2D` por luna; la textura nunca debe definir la colisión.
- Distribuir las lunas uniformemente con `TAU / cantidad`.
- Usar una órbita elíptica para conservar la vista 3/4: radio horizontal mayor que el vertical.
- Limitar siempre la cantidad mediante `clampi(cantidad, 2, 6)`.

