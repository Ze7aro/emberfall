EMBERFALL - SPRITES 2D SIMPLIFICADOS

Contenido por personaje:
- walk_right_00.png a walk_right_02.png
- walk_left_00.png a walk_left_02.png
- attack_00.png y attack_01.png

Todos los cuadros:
- 256 x 256 px
- PNG RGBA con fondo transparente
- mismo punto de apoyo y escala dentro de cada personaje

Configuracion recomendada en Godot 4:
1. Importar los PNG con Filter desactivado y Mipmaps desactivado.
2. Crear un SpriteFrames por personaje.
3. Animaciones walk_right y walk_left: 3 cuadros, loop activado, 6 a 8 FPS.
4. Animacion attack: 2 cuadros, loop desactivado, 8 a 10 FPS.
5. Para volver a idle, usar el primer cuadro de walk_right o walk_left segun la ultima direccion.

El paquete contiene 14 carpetas, una por variante.
