# Fuego Constante v3

Zona circular de fuego rasante para Emberfall. El fuego cubre casi toda el área y deja solamente una abertura central pequeña para mantener visible al personaje.

## Secuencia

- `frame_00.png`: expansión hacia el interior.
- `frame_01.png`: superficie activa casi completa.
- `frame_02.png`: comienzo de la disipación exterior.
- `spritesheet.png`: tira horizontal completa.

## Integración en Godot 4

- Mantener el efecto centrado en el personaje.
- Conservar la lógica y el `Area2D` actuales; el sprite es solamente visual.
- Usar el primer cuadro al activarse, el segundo durante el estado activo y el tercero al finalizar.
- Configurar filtrado y mipmaps desactivados.
- No reutilizar los archivos `.import` anteriores: Godot debe generarlos nuevamente.
