# Emberfall — Roadmap de lanzamiento Android 1.0

Fecha de auditoría: 9 de septiembre de 2026. Plataforma confirmada por el propietario: **Android primero**.

**Diagnóstico: prototipo avanzado con sistemas de metaprogresión; todavía no es una versión candidata a publicación.** Hay una base aprovechable y suficiente para producir el juego. La principal distancia al mercado está en la variedad del combate, la identidad de los personajes, la protección del progreso y la validación del producto en teléfonos reales.

Este documento fija una propuesta de alcance, una secuencia de producción y condiciones verificables de lanzamiento. Las cifras de tiempo y calidad son objetivos de planificación, no resultados medidos ni garantías de ventas. La fecha comercial se decide al superar los controles de salida.

## 1. Base de la auditoría

Se revisaron configuración, escenas, estado global, combate, componentes, interfaces, recursos de personajes y situación del repositorio. El proyecto contiene 32 scripts GDScript y 14 recursos de personajes. El análisis corresponde al árbol de trabajo actual, que incluye cambios y archivos sin incorporar al historial; no solamente al último commit `755fa9a`.

Se ejecutó la importación del editor sin interfaz con Godot `4.7.2.stable.official.ed1daf0bf`: terminó con código 0 y sin errores reportados en la salida. Evidencia: `audit_import.log`. Esta comprobación puede actualizar cachés e importaciones de Godot. No se modificó la lógica del juego como parte de esta auditoría.

**Límites:** no se realizó una partida completa, inspección visual interactiva, exportación Android, medición de rendimiento ni pruebas de compra real. No hay una suite de tests encontrada en el proyecto. Los riesgos de ejecución señalados más abajo se basan en lectura de código y requieren reproducción. No se verificaron cuentas de tienda, presupuesto, capacidad del equipo ni derechos de los assets.

## 2. Qué existe y qué falta

| Área | Evidencia actual | Distancia a 1.0 |
|---|---|---|
| Combate | Movimiento, autoataque, experiencia, selección de mejoras, estados alterados, derrota y jefe | Validar ritmo, variedad, alcance y legibilidad; definir encuentros por escenario |
| Habilidades | 7 activas y 15 pasivas; niveles hasta 6; 2 rerolls | Balance, descripciones exactas, presentación y casos límite |
| Fusiones | 5 recetas detectadas por nivel de habilidades | Solo agregan nombres a un array; falta comportamiento de combate y comunicación |
| Personajes | 14 recursos con sprites, precios, requisitos y variaciones de ataque | Gran parte comparte reglas; fuego/hielo/veneno no conceden automáticamente su efecto elemental |
| Campaña | 10 entradas con nombres, desbloqueos y recompensas | `game_world.gd` no usa el contexto para cambiar mapa, oleadas o jefe |
| Mazmorras | 3 entradas; desbloqueo después de la pantalla 10 | Comparten el mismo mundo de combate; falta experiencia propia |
| Progresión | Oro, gemas, nivel de cuenta, 3 mejoras permanentes | Curvas de adquisición, utilidad del nivel de cuenta y límites claros |
| Equipo | 6 espacios, 18 objetos, 3 rarezas, cofres con oro | Comparación clara, duplicados, crecimiento del inventario y balance |
| Misiones | 3 diarias y 4 semanales con reclamo persistente | Validar periodos, reloj, cambios de fecha y recompensas únicas |
| Persistencia | JSON local, validación parcial y archivo de respaldo | Recuperación robusta, versión de formato, escrituras seguras y pruebas de fallos |
| UX móvil | Diseño vertical 390 × 844, joystick flotante, pausa, menú, ajustes | Tutorial, segundo plano, áreas seguras, escalado y accesibilidad |
| Audio | Ajustes de música y efectos guardados | No se encontró reproducción de audio ni archivos de audio en el árbol revisado |
| Distribución | Proyecto local Godot | No se encontraron presets de exportación, automatización de builds ni paquete validado en Play |

El README quedó desactualizado: anuncia victoria a los 180 segundos. El código actual genera el jefe a los **720 segundos** y otorga victoria al derrotarlo. También anuncia WASD, pero el jugador usa acciones `ui_*` y no hay mapeo WASD explícito en `project.godot`.

## 3. Hallazgos que determinan las prioridades

| ID | Prioridad | Hallazgo y evidencia | Resolución requerida |
|---|---|---|---|
| AUD-01 | P0 | `_write_save()` copia el archivo principal al respaldo sin validar su contenido; una copia principal corrupta puede reemplazar un respaldo bueno. `_read_save()` tampoco intenta el respaldo cuando falta el principal. `scripts/systems/game_state.gd:590` | Validar candidato, escribir temporal, verificar, reemplazar y conservar el último respaldo válido. Recuperar también ante archivo principal ausente |
| AUD-02 | P0 | Carga de héroes mediante `DirAccess` y filtro `.tres`, en estado global y pantalla de equipo | Catálogo explícito de recursos o mecanismo compatible con exportación. Probar todos los héroes en el paquete instalado. Es un riesgo de exportación, no un fallo Android reproducido |
| AUD-03 | P1 | `check_fusions()` solo agrega nombres; no hay consumidor que altere daño, ataques o efectos. `scripts/game_world.gd:433` | Implementar y probar una transformación por receta, con información visible |
| AUD-04 | P1 | Campaña y mazmorras solo cambian contexto de progresión/recompensas; mundo, escalado y jefe son comunes. `scripts/game_world.gd:39`, `scripts/ui/HomeScreen.gd:24` | Datos de escenarios que gobiernen fondo, oleadas, enemigos, tiempo, jefe y premios |
| AUD-05 | P1 | Estados elementales dependen de pasivas aleatorias, no del elemento nominal del héroe. `scripts/game_world.gd:192` y `resources/characters/` | Definir identidades mecánicas y alinear nombres, descripción y comportamiento |
| AUD-06 | P1 | No hay gestión explícita de suspensión/reanudación; pausa depende del estado de pantalla | Pausar al perder foco, limpiar contacto táctil y conservar progreso según una política documentada |
| AUD-07 | P1 | `_available()` puede agotar ambos pools; la pantalla de nivel quedaría sin opciones. `scripts/game_world.gd:352` | Recompensa alternativa o cierre válido. Caso límite no observado en una partida natural |
| AUD-08 | P1 | Compras reciben coste/moneda del llamador; `buy_upgrade()` no rechaza tipos desconocidos; inicio de escenario no centraliza validación de desbloqueo | Validar ID, requisito, precio y estado dentro de la lógica de dominio. No confiar exclusivamente en botones deshabilitados |
| AUD-09 | P1 | Cruce de cada proyectil con cada enemigo, copias de arrays por frame, búsquedas y creación frecuente de nodos/animaciones | Medir con cargas representativas; después aplicar índice espacial, caché, límites y reutilización donde el perfil lo justifique |
| AUD-10 | P1 | Dependencia del reloj del sistema para energía y misiones; UID de objetos basado en milisegundos desde arranque | Política ante reloj atrasado/adelantado y claves persistentes sin colisiones entre sesiones |
| AUD-11 | P1 | El oro recogido cambia memoria y se persiste en otros eventos; no hay reanudación de la partida | Definir checkpoints y política ante cierre forzado, evitando pérdida de premios confirmados o duplicación |
| AUD-12 | P2 | Círculos de depuración dibujados siempre; UI con posiciones fijas y ajustes de audio sin implementación | Acabado visual, diseño adaptable y ajustes que tengan efecto real |
| AUD-13 | P1 | `.godot` está versionado y existen numerosos cambios locales y recursos sin seguimiento; no se encontró `.gitignore` | Incorporar deliberadamente el trabajo vigente, excluir cachés y demostrar construcción desde copia limpia |

P0 bloquea distribución a testers externos; P1 bloquea 1.0 cuando afecta funcionalidad incluida; P2 se resuelve según impacto. Un corte visual que impida jugar pasa a P1.

La documentación de Godot advierte que los nombres de recursos pueden cambiar al exportar y que los listados de `DirAccess` pueden variar. AUD-02 es una inferencia concreta de ese comportamiento y del código existente. [Referencia oficial](https://docs.godotengine.org/en/stable/classes/class_diraccess.html).

## 4. Contrato de producto propuesto para 1.0

**Promesa:** un juego de supervivencia de fantasía oscura, vertical y manejable con una mano, donde cada partida produce una combinación de habilidades reconocible y progreso permanente comprensible.

Público de diseño: jugadores de supervivencia y acción accesible que buscan sesiones breves. Es una hipótesis a validar con jugadores, no una investigación de demanda ya realizada.

| Elemento | Alcance cerrado propuesto |
|---|---|
| Plataforma | Android, orientación vertical, juego individual; combate y progreso disponibles sin conexión |
| Duración | Primera experiencia de 3–5 minutos; escenarios normales de 8–12 minutos incluyendo desenlace. Ajustar después de pruebas |
| Campaña | 10 encuentros distribuidos en 3 biomas, con oleadas y combinaciones distintas; final explícito |
| Enemigos | 5 arquetipos con decisiones distintas: perseguidor, veloz, tanque, tirador y cargador; combinaciones progresivas |
| Jefes | 3 jefes con patrones y anticipación visible; reutilización con variantes explícitas en campaña |
| Héroes | 6 preparados para lanzamiento: Vaelor, Azyren, Orven, Sylven, Theron y Mordrak; cada uno con una diferencia mecánica comprobable |
| Habilidades | Las 7 activas y 15 pasivas actuales, revisadas; evitar agregar más antes del balance |
| Fusiones | 5 recetas actuales, cada una con transformación funcional, efecto propio e información de requisitos |
| Metaprogresión | 3 ramas permanentes, 6 espacios de equipo y 18 objetos; límites y tratamiento de duplicados |
| Rejugabilidad | 1 mazmorra con modificadores y recompensas definidos, desbloqueada tras la campaña |
| UX | Tutorial breve, pausa, resultados detallados, ajustes reales, joystick configurable y legibilidad en pantallas pequeñas |
| Idiomas | Español completo; inglés antes de anunciar distribución internacional |
| Presentación | Sonido de acciones esenciales, música de menú/combate/jefe, señales claras de daño y selección |

Los otros 8 héroes y 2 mazmorras se conservan como trabajo existente para versiones posteriores. Si se ocultan en 1.0, no deben quedar requisitos, compras o textos inaccesibles. Se mantiene el progreso previo mediante migración; no se eliminan posesiones guardadas. Los seis héroes propuestos no dependen de las mazmorras postergadas.

### Modelo comercial: decisión pendiente de producto

**Recomendación para limitar complejidad: pago único por descarga, sin anuncios ni compras dentro del juego.** Bajo esa opción se retira el bloqueo por energía de la experiencia comercial y se conserva la progresión ganada jugando. Es una propuesta, no una decisión confirmada ni un cambio implementado.

La alternativa es free-to-play: conservar energía solo si las pruebas justifican su función y definir con precisión qué se vende. Requiere otro presupuesto para compras, restauración, estados pendientes, reembolsos, verificación de transacciones y protección de bienes pagados; el JSON local actual no basta como registro confiable de compras. Publicidad agrega integración, consentimiento donde corresponda, verificación de SDK y pruebas adicionales. La rama F2P debe cerrarse en el hito 0; no añadirse al final.

Precio, países iniciales y canal de adquisición se deciden con una comparación documentada de productos vigentes y pruebas de disposición a pagar. No se fija aquí un precio sin esa evidencia. Estimación adicional orientativa de una rama F2P: **4–8 semanas**, a revisar según servicios y alcance elegido.

## 5. Secuencia de producción y controles de salida

Plan base: **18–24 semanas** desde el inicio efectivo, suponiendo una persona de desarrollo a tiempo completo, decisiones de producto semanales y apoyo puntual de arte, audio y pruebas. Son unas 16–20 semanas de trabajo planificado más 2–4 de contingencia. Un equipo parcial o producción de todos los assets por la misma persona exige recalcular. Los plazos externos de Google Play no están garantizados.

| Hito | Esfuerzo orientativo | Entregable | Dependencias | Condición para avanzar |
|---|---|---|---|---|
| M0 — Alcance y base reproducible | 1 semana | Contrato 1.0, modelo comercial, matriz Android y build inicial | Ninguna | Copia limpia importa; catálogo de recursos revisado; responsable y alcance aceptados |
| M1 — Integridad y exportación | 2–3 semanas | Guardado seguro, reglas validadas y paquete Android interno | M0 | AUD-01/02 cerrados; pruebas críticas pasan; instalación y actualización conservan progreso |
| M2 — Una experiencia completa | 3 semanas | Un bioma, dos héroes, un jefe, una fusión, tutorial y audio esenciales | M1 | Jugadores externos completan el ciclo y pueden explicar sus decisiones |
| M3 — Contenido y progresión 1.0 | 4–5 semanas | Campaña completa, seis héroes, cinco fusiones, equipo y mazmorra | M2 | Todo el contenido prometido es alcanzable y tiene comportamiento propio |
| M4 — Calidad móvil y balance | 3–4 semanas | Interfaz final, rendimiento medido y economía ajustada | M3; mediciones desde M2 | Matriz de dispositivos aprobada; sin bloqueos de progresión; pruebas de actualización completas |
| M5 — Beta cerrada | 2 semanas mínimo | Cohorte real, incidencias clasificadas y métricas de experiencia | M4 y ficha/políticas listas | Sin problemas críticos; requisitos de cuenta satisfechos; ajustes validados |
| M6 — Candidata y salida comercial | 1–2 semanas | Paquete firmado, ficha final, soporte y plan de correcciones | M5 | Lista de lanzamiento completa y aprobación de tienda |

Ruta crítica: **alcance → guardado/exportación → experiencia validada → contenido → calidad Android → beta → candidata**. No se produce toda la campaña antes de validar M2.

### M0 — Primera semana

1. Incorporar de forma revisada los cambios locales y recursos necesarios; configurar exclusiones de cachés sin perder el trabajo existente.
2. Actualizar README: ejecución, controles, duración, arquitectura y comportamiento real.
3. Resolver pago único o F2P; fijar alcance de seis héroes y contenido de lanzamiento.
4. Identificar cuenta de Google Play, acceso de publicación, dispositivos disponibles y responsable de la clave de firma.
5. Fijar versión de Godot/plantillas y herramientas Android. Crear preset de exportación sin secretos en Git.
6. Obtener paquete inicial en teléfono; revisar catálogo completo de recursos. Registrar cualquier bloqueo antes de estimar contenido.
7. Inventariar autor, procedencia y permisos comerciales de imágenes, sprites, música, tipografías y complementos.

### M1 — Fundamentos verificables

Introducir pruebas para energía, guardado, recompensas, compras y transiciones antes de modificar esas reglas. Separar gradualmente persistencia, catálogo y reglas económicas de `GameState`, manteniendo una fachada para la UI. Extraer datos de encuentros y recetas de los scripts de presentación. No se necesita una reescritura total ni un servidor para la opción de pago único.

Agregar versión de guardado y migraciones; validar también elementos internos de listas y diccionarios. Tratar guardado incompleto, disco lleno, copia ausente y reloj anómalo. Establecer checkpoints con recompensa confirmada y reanudación segura, o una política explícita y probada de recuperación que evite cobrar energía dos veces. Validar inicio/fin de partida para impedir premios duplicados.

Salida: todos los casos críticos automatizados pasan y cada build incluye versión identificable. La instalación Android abre menú, carga héroes, inicia combate y conserva progreso tras actualización.

### M2 — Validar que jugar vale la pena

Construir una muestra con Vaelor y Theron, un encuentro corto y otro normal, tres arquetipos enemigos, un jefe, una fusión, recompensas y una compra con moneda ganada. La experiencia debe mostrar el futuro acabado de combate, aunque todavía falte la campaña.

Probar con 8–12 personas ajenas al desarrollo. Objetivos internos: al menos 80% inicia y comprende el movimiento sin explicación oral; al menos 70% identifica una decisión útil de mejora; al menos 60% inicia voluntariamente una segunda partida. Registrar denominador y observaciones: esta muestra sirve para detectar problemas, no para demostrar rentabilidad.

Si falla el interés por repetir, reservar una iteración de la contingencia para ritmo, controles y claridad antes de construir más escenarios.

### M3 — Convertir el sistema en contenido

Cada encuentro define bioma, límites, calendario de aparición, mezcla de enemigos, evento distintivo, jefe y premios. Evitar que las diez pantallas se diferencien solamente por vida enemiga. Cada héroe debe tener una ventaja y una limitación observable; los estados elementales deben coincidir con sus nombres.

Las fusiones deben ser alcanzables en una partida normal mediante elecciones deliberadas. Medir cuántos niveles y oportunidades reales hacen falta: exigir nivel 5 en dos poderes con opciones alternadas puede volverlas demasiado raras. Revisar requisitos según resultados, sin asumir que la fórmula actual es adecuada.

Modelar entradas y salidas de oro/gemas, tiempo hasta primera mejora y primer héroe, coste de equipo y repetición de recompensas. Objetivos iniciales: primera mejora en 1–2 partidas y primer desbloqueo alternativo en 2–4; ajustar a duración real. Definir reglas de duplicados y recompensas de primera victoria frente a repetición. Verificar que ninguna misión obligue a gastar más de lo que devuelve sin una razón clara para el jugador.

Salida: campaña alcanzable desde guardado vacío, créditos al terminar y mazmorra rejugable; sin pantallas de contenido prometido que sean decorativas.

### M4 — Hacerlo fiable en Android

Probar teléfono modesto, medio y alto, con al menos dos familias de GPU; cubrir versión mínima elegida, Android reciente, pantallas alargadas y recortes de cámara. La versión mínima y los modelos exactos se fijan en M0 después de revisar herramientas y dispositivos disponibles.

Ensayar bloqueo de pantalla, segundo plano, interrupciones, botón Atrás, cambio de tamaño, múltiples dedos, pérdida del toque al pausar, inicio sin red, falta de espacio y cierre del proceso. El HUD, el joystick y los modales necesitan áreas seguras; el ajuste inferior existente en el menú no demuestra cobertura global.

Metas de rendimiento propuestas: 60 FPS en gama media y modo de 30 FPS en el mínimo soportado; percentil 95 del tiempo de frame dentro de 16,7/33,3 ms según modo durante combate exigente de 20 minutos. Registrar picos, memoria, temperatura y batería. Diez ciclos de entrada/salida no deben mostrar crecimiento sostenido inexplicado. Definir límites de entidades a partir del perfil, no mediante un número arbitrario.

Añadir controles de volumen independientes, vibración opcional, reducción de sacudidas/destellos y señales que no dependan solo del color. Revisar español completo y traducción inglesa si se incluye. Sustituir la pantalla de resultados por un resumen de duración, causa de derrota/victoria, premios de esa partida y próximo objetivo.

### M5 y M6 — Beta y publicación

Reclutar testers antes de llegar a la beta. Objetivo de producto: 30–50 jugadores y al menos 200 sesiones para identificar problemas frecuentes. Esa muestra sigue siendo pequeña para extrapolar comportamiento comercial. Registrar versión, dispositivo y reproducción para cada incidencia.

Si se elige F2P, medir retorno al día siguiente y a los siete días por cohortes completas. Como hipótesis inicial se pueden usar D1 ≥ 30% y D7 ≥ 10%; no son benchmarks demostrados en este análisis. Una cohorte insuficiente obliga a extender observación; no se aprueba adquisición pagada usando porcentajes de pocos usuarios.

Preparar icono, capturas reales, video de combate de 20–30 segundos, descripción clara, créditos, contacto de soporte y notas de versión. Verificar nombre comercial y licencias antes de cerrar estos materiales. Publicar inicialmente en un mercado/idioma acotado si hace falta limitar soporte; ampliar después de comprobar estabilidad. No asumir que la primera publicación permite exactamente el mismo despliegue porcentual que una actualización.

## 6. Backlog ejecutable

Cada ticket debe tener responsable, build de prueba y evidencia de aceptación. Roles: DEV = desarrollo; PROD = producto/diseño; ART = arte/audio; QA = pruebas. Una misma persona puede cubrir varios roles, pero su tiempo no se cuenta dos veces.

| Ticket | Prioridad / hito | Responsable | Resultado verificable |
|---|---|---|---|
| REL-01 | P1 / M0 | DEV | Copia limpia construible, recursos incluidos y cachés excluidas |
| REL-02 | P0 / M1 | DEV | Catálogo de héroes idéntico en editor y paquete Android |
| SAVE-01 | P0 / M1 | DEV | Recuperación desde respaldo válido sin sobrescribirlo con datos corruptos |
| SAVE-02 | P1 / M1 | DEV | Migraciones y validación de contenido inválido sin caída ni pérdida silenciosa |
| RUN-01 | P1 / M1 | DEV | Inicio, pausa, nivel, derrota, victoria y reintento sin doble cobro/premio |
| ECON-01 | P1 / M1 | DEV | IDs y costes resueltos desde catálogo; operaciones inválidas no alteran saldo |
| TIME-01 | P1 / M1 | DEV | Energía y misiones consistentes ante reinicio y reloj alterado |
| MOBILE-01 | P1 / M1–M4 | DEV/QA | Suspensión y reanudación con controles restablecidos y progreso coherente |
| PLAY-01 | P1 / M2 | PROD/DEV | Primer encuentro completo con objetivo comprensible y aprendizaje guiado |
| BOSS-01 | P1 / M2 | PROD/ART/DEV | Primer jefe con patrones anticipables y victoria consistente |
| FUSE-01 | P1 / M2–M3 | DEV/ART | Cinco fusiones cambian mecánicas y muestran requisitos/desbloqueo |
| HERO-01 | P1 / M3 | PROD/DEV | Seis identidades jugables con descripciones fieles |
| STAGE-01 | P1 / M3 | PROD/DEV/ART | Diez encuentros, tres biomas, tres jefes y una mazmorra |
| ECON-02 | P1 / M3 | PROD/QA | Progresión completa sin bloqueos; balance y duplicados documentados |
| UX-01 | P1 / M4 | DEV/ART/QA | Flujo completo usable en toda la matriz de pantallas |
| AUDIO-01 | P1 / M2–M4 | ART/DEV | Audio esencial presente; ajustes persistentes y efectivos |
| PERF-01 | P1 / M4 | DEV/QA | Informe de rendimiento sobre combate final y sesiones prolongadas |
| QA-01 | P1 / M5 | QA/DEV | Beta sin fallos críticos abiertos ni pérdida de progreso reproducible |
| STORE-01 | P1 / M0–M6 | PROD | Cuenta, derechos, políticas, ficha y firma listos para revisión |
| OPS-01 | P1 / M6 | DEV/PROD | Soporte y procedimiento de hotfix ensayados |

## 7. Verificación mínima obligatoria

| Grupo | Casos mínimos |
|---|---|
| Guardado | Perfil nuevo; ciclo guardar/cargar; JSON roto; estructuras internas inválidas; principal ausente; respaldo bueno/malo; escritura interrumpida; falta de espacio; migración de versión anterior |
| Economía | Energía 0/4/5/50; recarga parcial; reloj hacia atrás; compra sin saldo; precio/ID inválido; doble toque; objeto duplicado; equipar/desquipar; misiones reclamadas dos veces |
| Combate | Daño directo y por estados; muerte con varios impactos simultáneos; jefe muerto una sola vez; XP multinivel; rerolls agotados; pools vacíos; fusiones y límites de nivel |
| Progresión | Bloqueo de escenarios/héroes en lógica; recompensas de derrota/victoria; guardado nuevo hasta final; mazmorra y desbloqueos compatibles con catálogo 1.0 |
| Móvil | Suspensión en combate y al elegir nivel; toque interrumpido; botón Atrás; notches; distintos aspectos; instalación limpia; actualización conservando datos; juego sin red |
| Exportación | Recursos y sprites dinámicos presentes; build firmado; arquitectura y compatibilidad requeridas; permisos finales; diferencia entre debug y release |

Automatizar reglas reproducibles y transiciones críticas. Mantener pruebas manuales para legibilidad, controles, sonido y diversión. Cada defecto corregido que afecte datos o reglas debe tener una prueba de regresión útil.

## 8. Google Play: dependencias externas verificadas

Revisar estas condiciones nuevamente al generar la candidata, porque pueden cambiar durante producción.

- **API objetivo:** a la fecha consultada, nuevas apps y actualizaciones generales deben apuntar a Android 16 / API 36 o superior desde el 31 de agosto de 2026. No confundir API objetivo con Android mínimo soportado. [Android Developers](https://developer.android.com/google/play/requirements/target-sdk?hl=en).
- **Distribución:** preparar APK para pruebas locales y Android App Bundle para Google Play, con firma y herramientas compatibles. Validar también recursos cargados por rutas construidas en ejecución. [Guía oficial de exportación Godot para Android](https://developer.android.com/games/engines/godot/godot-export?hl=en).
- **Compatibilidad nativa:** comprobar soporte de páginas de memoria de 16 KB en el motor exportado y cualquier biblioteca nativa incorporada; adjuntar evidencia de prueba al paquete final. [Guía oficial de compatibilidad](https://developer.android.com/guide/practices/page-sizes).
- **Cuenta personal nueva:** si fue creada después del 13 de noviembre de 2023, la regla consultada exige al menos 12 testers inscritos continuamente durante 14 días para solicitar acceso a producción. Esto no equivale a aprobación automática ni sustituye pruebas de calidad. [Requisitos oficiales de testing](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-GB).
- **Privacidad:** completar Data safety y enlazar política de privacidad, incluso si no se recopilan datos; auditar también cualquier SDK incorporado. El canal exclusivamente interno tiene una excepción indicada en la documentación. [Google Play: Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).

El responsable de publicación debe verificar además los formularios y avisos vigentes en su Play Console: audiencia, clasificación de contenido, anuncios/compras si existen y acceso para revisión. No se incluyen credenciales ni claves de firma en el repositorio.

## 9. Presupuesto, señales de mercado y riesgos

Separar horas de desarrollo de arte/audio externo, dispositivos, cuenta de publicación, localización, soporte y marketing. Reservar 2–4 semanas para contingencias técnicas y de validación. No comprometer presupuesto de adquisición antes de validar la experiencia y el modelo comercial.

Durante M0–M2, realizar una comparación actual de 5 juegos Android del segmento: promesa, duración, precio/modelo, calidad percibida y quejas recurrentes. Entregable: una página que explique por qué alguien elegiría Emberfall. Este estudio queda como trabajo del roadmap; no se ha realizado en la auditoría técnica.

Desde M2, recopilar comentarios de pruebas y producir capturas de gameplay real. Desde M4, probar la claridad de icono, descripción y video con personas del público objetivo. Medir visitas, instalaciones y compras cuando corresponda; fijar objetivos según precio y costes reales, no inventar una meta de ingresos.

| Riesgo | Señal de alerta | Respuesta |
|---|---|---|
| Escenarios repetitivos | Testers no distinguen encuentros | Cambiar composición, objetivos y patrones antes de sumar mapas |
| Alcance excesivo | Se agregan héroes antes de cerrar M2 | Mantener seis; mover contenido extra a 1.1 |
| Grind o energía frustrante | Abandono para esperar recursos, sin nueva decisión | Revisar economía; retirar barrera en pago único |
| Rendimiento insuficiente | Picos frecuentes y degradación térmica | Reducir coste visual/entidades y optimizar lo medido |
| Corrupción o pérdida | Reproducción de pérdida de premios confirmados | Detener salida y corregir persistencia |
| Exportación distinta del editor | Recursos faltantes solo en teléfono | Build Android desde M0; catálogo explícito y prueba por build |
| Derechos incompletos | Assets sin origen/permisos comprobables | Sustituir o resolver licencia antes de producir ficha |
| Modelo comercial tardío | Se piden anuncios/compras durante beta | Replanificar con rama F2P; no incorporarlos silenciosamente |

## 10. Regla definitiva de salida

La versión 1.0 se publica únicamente cuando todas estas condiciones tienen evidencia y responsable:

- [ ] Alcance comercial y contenido final coinciden con lo que muestra la tienda.
- [ ] No quedan P0/P1 abiertos dentro del alcance publicado.
- [ ] Campaña y mazmorra se completan desde guardado nuevo; todos los héroes anunciados son obtenibles.
- [ ] No se reproduce pérdida de progreso confirmado ni premios/cargos duplicados en la matriz de pruebas.
- [ ] Guardados anteriores migran y el respaldo recupera correctamente los casos previstos.
- [ ] Paquete Android firmado instala, actualiza, carga todos los recursos y funciona sin conexión en su ciclo principal.
- [ ] Rendimiento y controles cumplen la matriz de dispositivos documentada.
- [ ] Tutorial y repetición voluntaria superan la validación acordada; si no, hay nueva iteración probada.
- [ ] Sonido, ajustes, textos, áreas seguras y accesibilidad básica revisados.
- [ ] Beta ejecutada y requisitos de acceso a producción resueltos según la cuenta.
- [ ] Ficha, políticas, créditos, licencias y contacto de soporte terminados.
- [ ] Claves resguardadas, versión etiquetada, build reproducible y corrección de emergencia ensayada.

Las primeras 72 horas se revisan incidencias y señales de estabilidad a diario, con un responsable asignado. Ante corrupción o cierre sistemático se limita nueva distribución donde la tienda lo permita y se prepara un hotfix; no se asume que se puede instalar una versión anterior encima de una nueva. Toda corrección conserva compatibilidad de guardados.

La versión 1.1 puede recuperar los héroes y mazmorras diferidos según uso y demanda. Multijugador, PvP, clanes, temporadas, cuentas propias, sincronización en nube e iOS quedan fuera de esta 1.0. La expansión empieza después de demostrar estabilidad y una razón observable para volver a jugar.
