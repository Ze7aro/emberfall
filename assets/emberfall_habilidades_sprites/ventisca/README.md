# Ventisca — 3 frames

## Duración y reproducción

El ataque completo dura **5 segundos**.

1. Reproducir `frame_00.png` una vez como inicio y aviso visual.
2. Alternar y repetir `frame_00.png` y `frame_01.png` durante los 5 segundos de duración de la habilidad.
3. Al cumplirse los 5 segundos, detener el bucle y reproducir `frame_02.png` una vez como animación de finalización.
4. Después del último frame, ocultar o eliminar el efecto visual.

El temporizador de 5 segundos debe controlar la duración real del ataque. La animación no debe decidir cuándo termina la habilidad.

- `frame_00.png`: inicio y lluvia de hielo moderada.
- `frame_01.png`: ventisca activa y lluvia de hielo intensa.
- `frame_02.png`: finalización, disipación y escarcha residual; no vuelve a entrar en el bucle.
- `spritesheet.png`: tira horizontal completa (3 × 724 px).

## Uso en Godot 4

Importar las texturas sin filtrado ni mipmaps. Configurar el `Sprite2D` con `hframes = 3`. Durante la fase activa, repetir los frames `0 ↔ 1`; al finalizar el temporizador, reproducir el frame `2` una sola vez. Mantener el área de daño en un `Area2D` independiente del sprite; la imagen es solo feedback visual. El daño periódico y el congelamiento deben aplicarse mediante la lógica de la habilidad, no por el frame mostrado ni por el tamaño visible del efecto.
