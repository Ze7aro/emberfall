EMBERFALL - PODERES DE DISPARO

Incluye:
- disparo_fuego
- disparo_hielo
- disparo_veneno
- disparo_lunar
- disparo_runico
- disparo_magico

Cada carpeta contiene:
- icon.png: icono estatico para la interfaz.
- projectile_00.png: primer cuadro del proyectil.
- projectile_01.png: segundo cuadro del proyectil.

Formato:
- PNG RGBA con transparencia real.
- 256 x 256 px.
- Proyectiles orientados hacia la derecha.
- Los dos cuadros comparten escala, centro y punto de apoyo.

Configuracion recomendada en Godot 4:
- Importar con Filter y Mipmaps desactivados.
- Crear una animacion en AnimatedSprite2D con projectile_00 y projectile_01.
- Activar Loop y utilizar aproximadamente 8 a 12 FPS.
- Para disparar hacia la izquierda, usar flip_h en el AnimatedSprite2D.
- Mantener la colision en un nodo separado del sprite visual.





EMBERFALL - PROYECTILES DE PERSONAJES

Contenido:
- Cinder: bala compacta.
- Raiken: onda de puno de corto alcance.
- Sylven: flecha.
- Torvak: hacha arrojadiza.

Cada carpeta incluye projectile_00.png y projectile_01.png.

Formato:
- PNG RGBA con transparencia real.
- 256 x 256 px.
- Orientados hacia la derecha.
- Escala y punto de apoyo consistentes entre cuadros.

Godot 4:
- Desactivar Filter y Mipmaps.
- Usar AnimatedSprite2D con Loop activado y 8 a 12 FPS.
- Para la direccion izquierda, usar flip_h.
- La colision y el alcance deben manejarse por codigo, separados del sprite.




EMBERFALL - EFECTOS DE ATAQUES CUERPO A CUERPO

Darven:
- slash_x_00.png
- slash_x_01.png
- La X se desplaza una distancia corta hacia delante.

Kaelgor:
- ground_crack_00.png
- ground_crack_01.png
- Impacto inicial y expansion de la grieta en area.

Mordrak:
- u_slash_right_to_left.png
- u_slash_left_to_right.png
- Ataques alternados; no deben reproducirse simultaneamente.

Theron:
- thrust_00.png
- thrust_01.png
- shield_aoe_00.png
- shield_aoe_01.png
- La logica debe reproducir shield_aoe cada cuarto ataque.

Todos los archivos son PNG RGBA de 256 x 256 px con transparencia real.
En Godot 4, desactivar Filter y Mipmaps. La colision, distancia y area deben
manejarse con nodos separados del efecto visual.
