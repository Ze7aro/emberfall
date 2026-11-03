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
- Los assets están ordenados por tema: `audio`, `personajes`, `habilidades`, `mejoras`, `mundo` y `ui`. El detalle de cada carpeta está en `assets/README.md`.

## Implementado

- Menú vertical con HUD persistente (nivel, energía con cuenta regresiva, oro, gemas, notificaciones).
- Energía: 25 máximo, 5 por partida, 1 recuperada cada 5 minutos.
- 14 personajes con animaciones propias (idle/walk/attack) y ataque básico propio; cada héroe empieza con su habilidad de identidad.
- Habilidades: 12 activas y 12 pasivas, 4 espacios de cada una, nivel máximo 5 y una evolución por activa (activa al máximo + su pasiva). Barra de build en el HUD y cartas de subida de nivel con Cambiar, Descartar y Saltar.
- Partida: élites con cofre cada 90–120 s, hordas en anillo, enjambres, mini-jefe a los 6 minutos, pociones, imanes y bombas, y 3 jefes con sprite y patrones propios.
- Sensación de combate: destello y empuje al golpear, pausa breve en críticos, muertes con ceniza e iluminación con luces dinámicas.
- Metaprogresión: cuadrícula de 21 mejoras permanentes (incluye revivir), 6 habilidades que se desbloquean con objetivos y un Códex con las habilidades y evoluciones descubiertas y un bestiario con bajas por enemigo.
- Resultado detallado: tiempo, bajas, nivel, recompensas, ranking de daño por habilidad y próximo objetivo. La pausa muestra la build y el daño hasta el momento.
- Audio: música por contexto (`MusicDirector`, con tema de jefe) y efectos (`SfxPlayer`), ambos desactivables.
- Configuración: música, efectos, vibración, reducir temblor y destellos, y tamaño del joystick.
- Economía: oro, gemas, equipo (6 espacios, 18 objetos, 3 rarezas), cofres y tienda.
- Campaña y mazmorras con modificadores reales (enjambre, enemigos endurecidos, jefe adelantado) y bonus de primera vez.
- Misiones diarias y semanales con reclamo persistente.
- Android: preset de exportación, botón Atrás, pausa al perder el foco, guardado al pasar a segundo plano y áreas seguras. Pasos en `docs/PLAN_FINALIZACION.md` §7.
- Guardado local resiliente (ver arquitectura) con reintento ante corrupción del archivo principal.

## Pendiente antes de publicar

- Arte de enemigos, suelo y recolectables (prompts en `docs/PLAN_FINALIZACION.md` §6).
- Rendimiento medido en un teléfono real; reutilización de nodos (pooling) solo si el perfil lo justifica.
- Tests automatizados de guardado, energía, economía y transiciones críticas.