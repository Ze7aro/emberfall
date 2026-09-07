# Emberfall — migración Godot

Migración KISS del prototipo SwiftUI + SpriteKit a Godot 4.7.

## Ejecutar

1. Abrir `EmberfallGodot/project.godot` en Godot.
2. Ejecutar el proyecto.
3. Usar flechas o WASD; en móvil usar el joystick inferior izquierdo.
4. Pulsar `JUGAR` para comenzar una partida.

## Arquitectura

- `GameState` es el único estado global: guardado, energía, oro, mejoras y pantalla.
- `game_world.gd` contiene el loop de partida y coordina entidades.
- `components/` contiene jugador, enemigo, proyectil, orbe y joystick reutilizables.
- `ui.gd` genera el HUD, nivel y selección de poderes.
- Los assets se importan una sola vez desde el paquete Swift corregido.

## Implementado

- Menú vertical de Emberfall.
- Energía persistente: 5 por partida, 1 recuperada cada 5 minutos.
- Guardado local en `user://emberfall_save.json`.
- Jugador, límites del mapa y controles de teclado/joystick táctil.
- Enemigos perseguidores, daño, invulnerabilidad y derrota.
- Proyectiles automáticos, orbes, magnetismo y experiencia.
- Niveles, selección de poderes y dos rerolls por partida.
- Poderes dirigidos, orbitales, área, cadena y fuego con comportamiento reutilizable.
- Victoria a los 180 segundos.
- Oro y mejoras permanentes.

## Próximo endurecimiento antes de publicar

- Añadir escenas visuales dedicadas para cada efecto y fusión.
- Añadir audio y vibración.
- Mostrar tarjetas gráficas dedicadas para pasivas y fusiones en el menú de selección.
- Añadir pooling cuando aumente el límite de enemigos.
- Probar exportación Android y diferentes relaciones de aspecto.
- Crear tests automatizados de energía, guardado, XP, fusiones y victoria.
