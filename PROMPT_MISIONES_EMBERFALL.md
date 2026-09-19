# EMBERFALL — Especificación para generar la pantalla de Misiones

## Objetivo

Generar e implementar una pantalla de **Misiones** para *Emberfall*, roguelike 2D móvil vertical. Debe mostrar objetivos diarios y semanales, progreso, recompensas individuales y recompensas acumuladas, respetando la identidad visual del juego.

## Formato visual

- Relación vertical **9:16**.
- Resolución de referencia: **1254 × 2230 px**.
- Interfaz frontal, de alta fidelidad y desplazable verticalmente.
- Reservar zonas seguras superior e inferior para `TopHud` y `NavigationFooter` persistentes.
- No dibujar el TopHud ni el footer dentro del contenido central.

## Dirección artística de Emberfall

- Pixel art de fantasía oscura, detallado y legible en móvil.
- Fondo violeta casi negro.
- Marcos gruesos de piedra oscura y metal púrpura.
- Bordes pixelados, sombras marcadas y volúmenes compactos.
- Brillos, runas y barras activas en turquesa.
- Recompensas de oro en dorado cálido.
- Estados completados en verde/turquesa.
- Recompensas épicas y cofre final en violeta luminoso.
- Sin realismo fotográfico, ciencia ficción, gore ni exceso de partículas pequeñas.

## Estructura de pantalla

1. Título exacto **“MISIONES”**.
2. Botón de cierre con una **X** arriba a la derecha.
3. Pestañas:
   - **DIARIAS**, activa inicialmente.
   - **SEMANALES**, inactiva inicialmente.
4. Contador de reinicio debajo de las pestañas.
5. Panel de progreso acumulado.
6. Lista vertical desplazable de misiones.

## Pestañas y reinicios

- Las misiones diarias se reinician cada día a una hora definida por configuración.
- Las misiones semanales se reinician una vez por semana.
- Mostrar el tiempo restante con un texto corto, por ejemplo: **“Reinicio: 12 h 34 min”**.
- Cambiar de pestaña reemplaza la lista y el progreso acumulado sin cambiar de pantalla.

## Progreso diario

Mostrar un panel llamado **“PROGRESO DIARIO”** con una barra horizontal y cinco hitos:

| Hito | Recompensa visual sugerida |
| ---: | --- |
| 1 | Cofre pequeño |
| 3 | Cofre pequeño |
| 5 | Cofre mediano |
| 7 | Cofre raro |
| 10 | Cofre épico |

- La barra muestra misiones diarias completadas, por ejemplo **5 / 10**.
- Hitos reclamados: cofre apagado y marca de verificación.
- Próximo hito: resplandor turquesa controlado.
- Hito disponible sin reclamar: botón o pulso visual claro.
- El cofre final debe verse más valioso, sin eclipsar la lista.

## Tarjeta reutilizable de misión

Cada tarjeta debe contener:

1. Icono temático grande a la izquierda.
2. Título corto en mayúsculas.
3. Descripción de una línea.
4. Barra de progreso con valor numérico `actual / objetivo`.
5. Recompensa con icono y cantidad.
6. Botón a la derecha:
   - **IR** si está incompleta.
   - **RECLAMAR** en verde si está completada y pendiente.
   - Marca de verificación y estado apagado si ya fue reclamada.

Estados funcionales: `LOCKED`, `IN_PROGRESS`, `COMPLETED`, `CLAIMED`.

## Misiones diarias del mockup

Mostrar exactamente estas seis tarjetas:

| Título | Objetivo | Progreso | Recompensa | Estado |
| --- | --- | ---: | --- | --- |
| ENTRA EN COMBATE | Completa 1 mazmorra | 1/1 | 100 monedas | RECLAMAR |
| SIN PIEDAD | Derrota 50 enemigos | 32/50 | 20 de energía | IR |
| CAZADOR DE ÉLITE | Derrota 3 élites | 2/3 | 2 gemas | IR |
| EQUIPO LISTO | Mejora una pieza de equipo | 0/1 | 1 fragmento poco común | IR |
| RÍO DE ORO | Consigue 500 monedas | 500/500 | 150 monedas | RECLAMAR |
| DESAFÍO DEL JEFE | Derrota a un jefe | 0/1 | 1 baúl raro | IR |

Iconos sugeridos: espadas cruzadas, grupo de cráneos, casco de élite, martillo con armadura, montón de monedas y emblema de jefe.

## Misiones semanales sugeridas

La pestaña semanal reutiliza exactamente los mismos componentes, con objetivos mayores. Datos iniciales configurables:

| Título | Objetivo | Recompensa sugerida |
| --- | --- | --- |
| EXPLORADOR DEL ABISMO | Completa 20 mazmorras | Baúl raro |
| VERDUGO | Derrota 1.000 enemigos | Monedas |
| ROMPEJEFES | Derrota 10 jefes | Gemas |
| FORJADOR | Mejora 10 piezas de equipo | Materiales |
| SUPERVIVIENTE | Alcanza el minuto 15 en 5 partidas | Baúl épico |

## Comportamiento funcional

- El botón **IR** navega al sistema relacionado con el objetivo.
- **RECLAMAR** acredita la recompensa una sola vez.
- El progreso se actualiza mediante eventos globales del juego, no desde la pantalla.
- El estado debe persistir entre sesiones.
- Al reclamar, reproducir una animación breve y actualizar TopHud si cambia una moneda o energía.
- Si se completa una misión fuera de esta pantalla, mostrar un indicador en el icono de Misiones del footer.
- Al finalizar el período, archivar o reemplazar las misiones y reiniciar el progreso correspondiente.
- Las recompensas y metas deben cargarse desde recursos o datos configurables.

## Modelo de datos sugerido

```text
MissionDefinition
- id: String
- category: DAILY | WEEKLY
- title: String
- description: String
- event_type: String
- target_value: int
- reward_type: String
- reward_id: String
- reward_amount: int
- icon_path: String
- destination_route: String

MissionProgress
- mission_id: String
- current_value: int
- state: LOCKED | IN_PROGRESS | COMPLETED | CLAIMED
- period_id: String
```

Separar definición y progreso evita duplicar contenido y permite balancear sin modificar escenas.

## Prompt listo para una IA generadora de imágenes

```text
Create a high-fidelity portrait mobile game missions UI for EMBERFALL, a dark-fantasy 2D vertical roguelike. Use a 9:16 composition with a violet-black background, chunky dark-stone and purple painted-metal frames, strong shadows, pixel-edged detailing, turquoise runic glow and warm gold rewards. It must match a premium polished pixel-art-inspired mobile game interface and remain highly readable at phone size.

At the top place the exact Spanish title “MISIONES” and a compact X close button. Beneath it place two large tabs: “DIARIAS” active in turquoise and “SEMANALES” inactive in dark purple. Add “Reinicio: 12 h 34 min”.

Create a panel titled “PROGRESO DIARIO” with a horizontal progress track labeled 5 / 10 and exactly five chest milestones: 1, 3, 5, 7 and 10. Earlier milestones are claimed with checkmarks, the next chest glows turquoise and the final chest is ornate purple.

Below, show exactly six mission cards in a vertical list. Each card contains a large fantasy icon, bold Spanish title, one-line objective, numerical progress bar, reward and a large right-side button.

1. “ENTRA EN COMBATE” — “Completa 1 mazmorra” — 1/1 — 100 gold — green “RECLAMAR”.
2. “SIN PIEDAD” — “Derrota 50 enemigos” — 32/50 — 20 energy — “IR”.
3. “CAZADOR DE ÉLITE” — “Derrota 3 élites” — 2/3 — 2 gems — “IR”.
4. “EQUIPO LISTO” — “Mejora una pieza de equipo” — 0/1 — one green uncommon equipment fragment — “IR”.
5. “RÍO DE ORO” — “Consigue 500 monedas” — 500/500 — 150 gold — green “RECLAMAR”.
6. “DESAFÍO DEL JEFE” — “Derrota a un jefe” — 0/1 — one rare chest — “IR”.

Use crossed swords, skulls, an elite horned helmet, hammer and armor, gold pile and boss sigil as icons. Completed cards glow subtly green or turquoise. Unfinished cards remain dark purple. Buttons are large and touch-friendly. Keep all visible text correctly spelled in Spanish.

Reserve safe margins for Emberfall's external TopHud and NavigationFooter but do not draw them. No characters, no shop products, no battle scene, no photorealism, no sci-fi, no gore, no tiny unreadable particles, no watermark and no recognizable assets or branding from other games. Do not add extra missions.
```

## Validación

- [ ] El diseño coincide con Emberfall.
- [ ] Existen las pestañas Diarias y Semanales.
- [ ] Se muestra el reinicio del período.
- [ ] El progreso acumulado tiene cinco hitos.
- [ ] El mockup contiene exactamente seis misiones.
- [ ] Cada misión muestra objetivo, progreso, recompensa y acción.
- [ ] Se distinguen claramente `IR`, `RECLAMAR` y reclamado.
- [ ] Los textos visibles están correctamente escritos en español.
- [ ] No aparecen personajes ni elementos de otras franquicias.
- [ ] Las zonas de TopHud y NavigationFooter quedan reservadas.
