# Colaboración en Emberfall

Este proyecto usa Organic Driven Development (ODD): explorar, decidir el proceso proporcional, implementar en unidades comprobables y dejar evidencia suficiente para continuar.

## Antes de cambiar archivos

1. Determinar la intención del pedido. Explicaciones, auditorías y propuestas son de solo lectura salvo que el usuario pida implementar.
2. Revisar el estado relevante del proyecto y `git status`. No sobrescribir ni limpiar cambios locales ajenos a la tarea.
3. Consultar `README.md`, `ROADMAP_LANZAMIENTO.md` y la documentación relacionada con el área afectada.
4. Preguntar solamente cuando falte una decisión real de producto, arte, balance, monetización, licencias o alcance que cambie materialmente el resultado.

## Elegir la ruta

- Trabajo directo: cambio entendido, acotado y retomable leyendo el diff. Implementar sin crear documentos de seguimiento.
- Trabajo rastreado: no se podría retomar con seguridad solo desde el diff por abarcar varias sesiones, esperas externas, requisitos extensos o varias unidades dependientes. Tras explorar y antes de cambiar código o escenas, crear `odd/tasks/<nombre>.md` a partir de `odd/tasks/TEMPLATE.md`.
- El número de archivos o líneas no decide por sí solo la ruta.
- No delegar trabajo ni abrir procesos paralelos sin una razón concreta y compatible con las instrucciones de la sesión.

## Implementación

1. Trabajar en la unidad de comportamiento más pequeña que produzca un resultado verificable.
2. Mantener juntos comportamiento, pruebas y documentación relacionada.
3. Respetar la arquitectura existente: `GameState` concentra el estado persistente; `MainLayout` enruta las pantallas; datos de héroes permanecen data-driven.
4. No editar archivos generados de Godot (`.godot/`, `*.uid`, `*.import`) salvo que la tarea lo requiera expresamente. Evitar ruido de importación en la entrega.
5. No agregar dependencias, assets de terceros ni cambios de monetización sin confirmar necesidad, licencia e impacto.
6. En trabajo rastreado, actualizar el documento después de cada unidad: estado, evidencia, decisiones y próximo paso.

## Verificación proporcional

- Scripts y escenas: validar que Godot pueda cargar el proyecto sin errores de parseo ni recursos faltantes.
- Guardado, economía o progresión: cubrir casos límite y agregar una regresión automatizada cuando exista infraestructura útil.
- Combate: comprobar la mecánica afectada, derrota/victoria, recompensas y ausencia de efectos duplicados cuando corresponda.
- UI: revisar en 390x844 y en al menos otra relación de aspecto; comprobar táctil, foco y legibilidad.
- Audio: comprobar buses, persistencia de ajustes y comportamiento cuando falte un recurso.
- Android/exportación: verificar inclusiones dinámicas, reanudación y build exportable cuando la tarea alcance esa superficie.
- Usar `ROADMAP_LANZAMIENTO.md`, sección "Verificación mínima obligatoria", como matriz de referencia.
- Si una comprobación no puede ejecutarse, declararlo con precisión; no presentarla como aprobada.

## Cierre

Entregar un resumen del resultado, archivos afectados, evidencia observada, riesgos o comprobaciones pendientes. En trabajo rastreado, marcar criterios cumplidos y dejar un próximo paso concreto o cerrar el documento. No crear commits, ramas, publicaciones ni entregas externas salvo pedido explícito.

La guía operativa completa está en `docs/ODD_EMBERFALL.md`.
