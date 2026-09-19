# Prompt para implementar Onda Orbital en Emberfall

Implementa o refactoriza la habilidad **Onda Orbital** en el proyecto Emberfall, desarrollado con Godot 4.

## Comportamiento

- La habilidad genera inicialmente **2 lunas mágicas** que orbitan continuamente alrededor del personaje.
- Conforme mejore el nivel de la habilidad, el sistema podrá agregar lunas adicionales.
- La cantidad debe ser dinámica y configurable, con mínimo 2 y máximo absoluto de 6.
- Distribuir todas las lunas de manera uniforme: separación angular `TAU / moon_count`.
- Las lunas deben seguir al jugador mientras giran, sin retrasos ni teletransportes.
- La órbita debe ser elíptica para acompañar la perspectiva 3/4 del combate: `radius_x` mayor que `radius_y`.
- Cada luna daña al enemigo que toca usando su propia `Area2D` y `CollisionShape2D`.
- Evitar daño en cada frame de física: aplicar un cooldown por objetivo o respetar el sistema de impactos existente.
- Al aumentar o disminuir la cantidad, redistribuir las lunas suavemente.
- No superar 6 lunas aunque los datos recibidos sean incorrectos.

## Recurso visual

Usar `moon_spritesheet.png`, una tira horizontal de 3 frames de una única luna. Crear un `SpriteFrames` o cargar sus PNG individuales. La animación de brillo se reproduce en bucle y es independiente del movimiento orbital.

No usar una imagen con el personaje, el círculo orbital o todas las lunas dibujadas. Instanciar una escena reutilizable `OrbitalMoon.tscn` por cada luna.

## Estructura sugerida

```text
OrbitalWave (Node2D)
└── Moons (Node2D)
    ├── OrbitalMoon (Area2D)
    │   ├── AnimatedSprite2D
    │   └── CollisionShape2D
    └── ...hasta 6 instancias
```

## Movimiento

Para cada luna calcular:

```gdscript
var angle := orbit_time * angular_speed + TAU * float(index) / float(moon_count)
moon.position = Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
moon.z_index = 1 if moon.position.y >= 0.0 else -1
```

El cambio de `z_index` debe hacer que la luna pase visualmente detrás del personaje en la mitad superior y delante en la mitad inferior.

## Integración

- Revisar primero el sistema actual de habilidades, daño, mejoras y pooling; reutilizarlo.
- Exponer `moon_count`, `radius_x`, `radius_y`, `angular_speed`, daño y cooldown como parámetros configurables o datos de la habilidad.
- El nivel debe modificar la cantidad mediante el modelo de mejoras existente, no desde la escena visual.
- Liberar todas las instancias al terminar la partida o desactivar la habilidad.
- Mantener compatibilidad móvil y evitar crear nodos cada frame.
- Informar qué escenas y scripts fueron creados o modificados.

## Estilo visual obligatorio

Pixel art de fantasía oscura de Emberfall: violeta y púrpura dominantes, brillos mágicos turquesa/cian, lectura clara a escala pequeña y fondo transparente. No agregar anillos sólidos, estética futurista, efectos realistas ni partículas excesivas.
