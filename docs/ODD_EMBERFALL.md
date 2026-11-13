# Organic Driven Development en Emberfall

ODD es el flujo cotidiano de trabajo del proyecto. Su objetivo es conservar contexto y evidencia sin convertir cada cambio en una ceremonia.

## Fuentes de verdad

- `README.md`: arquitectura y estado general del juego.
- `ROADMAP_LANZAMIENTO.md`: prioridades, tickets y condiciones para Android 1.0.
- `PLAN_IMPLEMENTACION_ASSETS.md` y `docs/`: decisiones visuales y trabajos especializados.
- `odd/tasks/`: estado recuperable de una implementación extensa en curso.
- El código, las escenas y los recursos actuales: evidencia del comportamiento real.

El roadmap dice qué construir; ODD define cómo abordar y comprobar cada unidad. Un documento de `odd/tasks/` no duplica el roadmap: enlaza el ticket correspondiente y registra solamente el contexto necesario para ejecutar y retomar ese trabajo.

## Ciclo de trabajo

### 1. Interpretar

Separar el resultado pedido de una posible solución sugerida. Confirmar si el pedido autoriza cambios o solamente requiere analizar, explicar o proponer.

### 2. Explorar

Antes de escribir, localizar las escenas, scripts, datos y documentación relevantes. Revisar cambios locales para evitar pisar trabajo existente. Registrar hechos observados y distinguirlos de supuestos.

### 3. Elegir la cantidad de proceso

Resolver directamente cuando el cambio esté entendido, tenga impacto contenido y pueda retomarse leyendo el diff.

Crear un seguimiento en `odd/tasks/` cuando la tarea necesite varias unidades dependientes, probablemente cruce sesiones, espere una decisión o recurso externo, o tenga tanto contexto que el diff no alcance para reconstruir la intención.

### 4. Resolver decisiones reales

La implementación técnica reversible y coherente con la arquitectura puede decidirse dentro de la tarea. Se consulta al responsable del producto cuando cambie, entre otros puntos:

- experiencia central, dificultad o balance económico;
- monetización, anuncios o compras;
- identidad visual, narrativa o alcance de contenido;
- uso o sustitución de assets con dudas de licencia;
- compatibilidad mínima, datos del jugador o política de publicación.

### 5. Implementar una unidad

Cada unidad debe expresar un comportamiento observable y ser suficientemente pequeña para revisar y verificar. Los tests y la documentación forman parte de la misma unidad cuando explican ese comportamiento.

Ejemplos de unidades útiles:

- `SAVE-01`: detectar principal corrupto y cargar el respaldo sin modificarlo.
- `AUDIO-01`: reproducir música de menú respetando el volumen persistido.
- `FUSE-01`: implementar una fusión completa con efecto, requisitos y presentación antes de repetir el patrón.

Separar por capas técnicas —primero modelos, luego servicios, luego tests— suele ocultar si una unidad realmente funciona.

### 6. Verificar según el riesgo

La comprobación mínima es la que podría detectar de forma creíble la regresión introducida. Se combinan, según corresponda:

- validación de carga y parseo en Godot;
- prueba automatizada de reglas deterministas;
- recorrido manual focalizado;
- inspección visual en más de una resolución;
- ejecución en Android real para rendimiento, táctil, suspensión o exportación;
- revisión independiente para guardado, economía, seguridad de datos o cambios de alto impacto.

Una prueba que no se pudo ejecutar queda como pendiente explícito.

### 7. Actualizar y continuar

En una tarea rastreada, después de cada unidad se actualizan las casillas, la evidencia y el próximo paso. Si aparece nueva información, se ajustan solamente las unidades afectadas dentro del alcance autorizado.

### 8. Cerrar

El cierre informa resultado, evidencia, limitaciones y riesgos residuales. Una tarea no se marca completa por haber terminado el código si faltan criterios de aceptación esenciales.

## Ejemplo de uso cotidiano

Pedido: "corregir que una misión se pueda reclamar dos veces".

1. Explorar `GameState`, la pantalla de misiones y el guardado.
2. Si la causa y la superficie son acotadas, trabajar directamente.
3. Crear primero o junto al arreglo una regresión que intente reclamar dos veces.
4. Implementar la corrección mínima.
5. Verificar saldo, estado persistido y recarga de partida.
6. Entregar evidencia y cualquier caso no cubierto.

Pedido: "completar las cinco fusiones de habilidades".

1. Explorar el sistema de poderes, UI, datos y assets.
2. Crear `odd/tasks/fusiones-habilidades.md` porque hay varias unidades y decisiones de balance/arte.
3. Implementar una fusión vertical completa.
4. Verificarla y actualizar el seguimiento.
5. Repetir el patrón validado con las restantes, ajustando el plan a lo aprendido.

## Regla de higiene del repositorio

Godot puede modificar muchos archivos `.import` al abrir el proyecto. Esos cambios no son evidencia de una feature. Las entregas deben distinguir claramente los archivos de comportamiento de los metadatos generados y nunca limpiar cambios previos sin autorización.
