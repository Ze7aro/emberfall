# Emberfall

Roguelike de supervivencia 2D vertical para Godot 4.7, pensado primero para Android.

## Ejecutar

1. Abrir `EmberfallGodot/project.godot` en Godot 4.7.
2. Ejecutar el proyecto (escena raíz `MainLayout`).
3. En escritorio: mover con las flechas del teclado. En móvil: joystick dinámico, aparece donde el jugador toca la pantalla.
4. Desde el menú principal: `JUGAR` inicia una partida (consume energía). El pie de navegación lleva a Inicio, Tienda, Personaje, Inventario y Mazmorras; Misiones se abre desde el acceso lateral de Inicio.

## Arquitectura

- `MainLayout.gd` es el controlador raíz: mantiene el `TopHud` y el `NavigationFooter` persistentes, y enruta pantallas dentro de `content_host` vía `navigate_to(route_id)`.
- `GameState` (autoload) es el único estado global persistente: energía, oro/gemas, nivel de cuenta, mejoras permanentes, personajes poseídos/equipados, misiones y progreso de campaña/mazmorras. Se guarda en `user://emberfall_save.json` con escritura atómica (temporal → verificar → reemplazar) y respaldo en `user://emberfall_save.bak.json`.
- `game_world.gd` contiene el loop de una partida (spawn de enemigos, XP, poderes activos, jefe) y `ui.gd` genera su HUD (nivel, selección de poderes/mejoras).
- `components/` agrupa jugador, enemigo, proyectil, orbes, joystick táctil y los efectos visuales reutilizables de habilidades/ataques.
- `resources/characters/*.tres` (`CharacterData`) define cada héroe de forma data-driven: sprite, arma, costo/requisito de desbloqueo y su ataque básico (nombre, color, sprite propio si lo tiene).
- Los sprites de personajes, disparos y habilidades activas viven bajo `assets/emberfall_sprites_2d_simple`, `assets/emberfall_poderes` y `assets/emberfall_habilidades_sprites`.

## Implementado

- Menú vertical con HUD persistente (nivel, energía con cuenta regresiva, oro, gemas, notificaciones).
- Energía: 50 máximo, 5 por partida, 1 recuperada cada 5 minutos.
- 14 personajes con animaciones propias (idle/walk/attack); 10 tienen un ataque básico con sprite y nombre propio (fuego, hielo, veneno, lunar, rúnico, mágico, flecha, bala, hacha arrojadiza, tajo en U con alternancia) y 4 son cuerpo a cuerpo con alcance corto real (uno de ellos con golpe en área cada 4to ataque).
- Combate: movimiento, autoataque dirigido, XP, niveles con selección de poderes/pasivas (2 rerolls por partida), estados alterados (veneno/quemadura/congelamiento), derrota y jefe a los 12 minutos con victoria al derrotarlo.
- 7 poderes activos (dirigido, orbital, área, cadena, fuego, ventisca, bomba venenosa) con efectos visuales propios; 15 mejoras pasivas.
- Economía: oro, gemas, 3 ramas de mejora permanente, equipo (6 espacios, 18 objetos, 3 rarezas) y cofres.
- Misiones diarias y semanales con reclamo persistente.
- Pantalla de héroe/equipo unificada con carrusel circular de selección y requisitos de desbloqueo leídos de datos reales.
- Guardado local resiliente (ver arquitectura) con reintento ante corrupción del archivo principal.

## Pendiente antes de publicar (ver `ROADMAP_LANZAMIENTO.md`)

- Fusiones de habilidades: hoy solo registran el nombre, sin efecto de combate propio.
- Campaña y mazmorras: los 10 escenarios y 3 mazmorras solo cambian recompensas/progreso, no mapa/oleadas/jefe.
- Catálogo de personajes explícito (la carga actual por `DirAccess` es un riesgo al exportar a Android).
- Audio: no hay reproducción de música ni efectos implementada todavía, solo los ajustes guardados.
- Rendimiento medido en dispositivos reales, pooling de enemigos/proyectiles si el perfil lo justifica.
- Tests automatizados de guardado, energía, economía y transiciones críticas.
