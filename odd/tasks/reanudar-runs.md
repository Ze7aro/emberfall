# Reanudar una run después de cerrar el juego

- Estado: implementado; pendiente de prueba en teléfono (ver «Próximo paso»)
- Ticket del roadmap: relacionado con AUD-11 y UX-01; sin ticket de implementación asignado
- Pedido original: «la idea es que la run se puedan cerrar y luego reanudar como podemos realizarlo?»
- Última actualización: 2026-11-16

## Resultado esperado

El jugador puede cerrar el juego durante una partida y continuar esa misma run más tarde desde el menú. La reanudación conserva el escenario y el estado de combate, no vuelve a cobrar energía ni entrega recompensas o progreso por duplicado. Al terminar o abandonar la run, su instantánea se elimina.

## Alcance

Incluye:

- Instantánea versionada en el guardado existente, compuesta por datos serializables; no se guardan nodos de Godot.
- Captura y restauración del estado de `GameWorld`, sus entidades y sistemas de combate.
- Guardado al pausar/salir, al perder foco o suspender la app y en puntos periódicos acotados.
- Reanudación desde el menú y salida voluntaria de una run conservando su progreso.
- Reglas explícitas para run pendiente, nueva run, victoria, derrota y abandono.
- Validación de instantáneas viejas, incompletas o incompatibles sin bloquear el inicio del juego.

No incluye:

- Sincronización en nube o entre dispositivos.
- Repetición determinista exacta de cada número aleatorio tras reanudar.
- Recuperar una partida anterior a la instalación que incorpore esta función.

## Diseño implementado

- **Dónde vive:** `GameState.active_run`, dentro de `user://emberfall_save.json` (clave `active_run`, `null` si no hay). Al estar en el mismo archivo que el perfil, el oro ya cobrado y los orbes que quedan en el suelo se escriben siempre juntos: no hay forma de cobrar dos veces un orbe.
- **Proveedor:** el `game_world` vivo registra `capture_snapshot()` en `GameState`; cada `save()` durante la run refresca la instantánea antes de escribir. Al terminar o al salir, el proveedor se retira.
- **Esquema v1** (`RUN_SNAPSHOT_VERSION`): `version`, `saved_at`, `phase` (`playing` | `level_up`), `context` (escenario), `hero` (id, textura, carpeta), `report` (las mismas estadísticas que recibe `record_run`), `loot`, `world` (tiempo, XP/nivel, bajas, build, evoluciones, descartes, opciones de nivel, rerolls, temporizadores de habilidades, eventos disparados, próximo élite, jefe, Égida, empoderado, daño por fuente, oro de la run, contadores de armas, equipo y mejoras congelados), `player`, `enemies` (incluye élites, mini-jefe y jefe), `orbs`, `pickups`, `zones` (charcos y ventiscas). Vectores como `[x, y]`.
- **No se guarda:** disparos, meteoros, frascos, runas y zonas del jefe en el aire, ni decorados/efectos. Perderlos solo puede quitar unos golpes; nunca repite una baja, un drop o un evento. Los nodos persistentes de la build (lunas, aura, familiares, Invierno Perpetuo, Égida) se reconstruyen con `_refresh_powers()`.
- **Lectura tolerante:** `scripts/systems/run_snapshot.gd` (`RunSnapshot`) convierte cada valor con valor por defecto; `GameState.is_valid_run_snapshot()` valida versión, fase, escenario desbloqueado, héroe poseído, vida > 0 y tipos de las colecciones. Una instantánea inválida se descarta al cargar con un aviso en el log; el perfil carga normal.
- **Cierre atómico:** `end_run()` retira el proveedor, abre un lote de guardado (`begin_save_batch`), borra la instantánea, registra estadísticas, entrega botín y recompensas y escribe una sola vez (`end_save_batch`). Un cierre inesperado deja o la run pendiente o la run liquidada, nunca ambas ni a medias.

## Decisiones y supuestos

- Confirmado por el pedido: una run debe poder cerrarse y reanudarse después.
- Supuesto reversible: se conserva una sola run pendiente por perfil. Inicio muestra la tarjeta «REANUDAR»; empezar otra run (Inicio o Mazmorras) pide confirmar «ABANDONAR Y JUGAR».
- Supuesto reversible: los periodos diarios/semanales siguen avanzando mientras la app está cerrada; la run se reanuda sin aplicar tiempo offline al combate.
- Decisión: abandonar (desde la pausa o al empezar otra run) cuenta como la derrota que ya era «SALIR» antes: estadísticas, botín pendiente y XP de derrota, una sola vez (`forfeit_pending_run`).
- Decisión: «GUARDAR Y SALIR» en la pausa vuelve a Inicio conservando la run; no registra resultados ni premios.
- Decisión: la run reanudada usa el equipo y las mejoras permanentes con que empezó (congelados en la instantánea), para que comprar mejoras con el oro de la run y volver no la haga más fuerte. El héroe seleccionado vuelve al de la run al reanudar.
- Decisión: la run reanudada empieza en pausa (o en la misma elección de nivel, con las mismas cartas y rerolls). Un jefe guardado a mitad de ataque vuelve persiguiendo, con su próximo ataque cerca y el aviso completo.
- Decisión de UI: la tarjeta de Inicio va en el hueco izquierdo de la fila de atajos. La columna del escenario solo tiene ~28 px libres a 390×844 (el diorama fija 290 px); una tarjeta a lo ancho tapaba «JUGAR» con el pie de navegación. Por eso Inicio no tiene botón propio de abandonar: se abandona desde la pausa o con «ABANDONAR Y JUGAR».

## Riesgos

- Rendimiento del guardado: cada escritura serializa la instantánea (puede pasar de 100 KB con muchas entidades) y `_write_save` vuelve a parsear el temporal y el principal. Ocurre cada 20 s de juego, cada 5 s si hubo oro nuevo, y en pausa/nivel/jefe. No se midió en un teléfono de gama baja.
- Retrocompatibilidad: una actualización que cambie el esquema debe subir `RUN_SNAPSHOT_VERSION`; hoy una versión distinta se descarta (la run se pierde, sin premio ni castigo).
- `_present_level_up()` sigue sumando 20 de oro sin marcar el guardado como pendiente cuando no hay cartas posibles (comportamiento previo); es consistente porque la instantánea tampoco lo refleja hasta el siguiente guardado.

## Unidades de trabajo

- [x] **RUN-RESUME-01 — Contrato y ciclo de vida del guardado.** `active_run` versionado, `has_resumable_run()`, `save_run_snapshot()`, `clear_run_snapshot()`, `is_valid_run_snapshot()`, `prepare_resume()`, `forfeit_pending_run()`, lote de guardado y `load_data()` separado de `load_save()`. Aceptación cumplida: se conserva tras ida y vuelta por JSON y carga; ausente/dañado/versión desconocida se descarta sin perder el perfil; guardar la instantánea no cambia energía ni oro.
- [x] **RUN-RESUME-02 — Exportación del estado del mundo.** `game_world.capture_snapshot()` y `_run_report()` cubren todos los campos que deciden la siguiente elección o el resultado (lista en «Diseño implementado»).
- [x] **RUN-RESUME-03 — Entidades activas.** `to_snapshot()` / `apply_snapshot()` en jugador, enemigo, jefe, orbe, pickup, charco venenoso y zona de ventisca. Orden de restauración: campos base → nodos de la build → entidades → pantalla. Los charcos/zonas restaurados no repiten el golpe de aterrizaje; el «ya congelado» del enemigo se conserva para no contar dos veces el desafío.
- [x] **RUN-RESUME-04 — Reanudación sin coste ni reinicialización.** `MainLayout.resume_run()` no llama `begin_stage()` ni `GameState.start_run()`; `game_world` con `restore_snapshot` no concede el arma inicial ni los 4 enemigos iniciales.
- [x] **RUN-RESUME-05 — Guardados seguros y salida.** Guarda al pausar o abrir subida de nivel (`change_screen`), al perder foco, al suspender la app, al cerrar la ventana, al aparecer el jefe, tras elegir carta y cada 20 s de juego. La run nueva queda guardada desde su primer segundo. «GUARDAR Y SALIR» conserva; «ABANDONAR» pide confirmación y liquida como derrota. Victoria/derrota la borran en la misma escritura que los premios.
- [x] **RUN-RESUME-06 — Flujo de menú y recuperación.** Tarjeta con escenario, tiempo y «REANUDAR»; «JUGAR» con run pendiente pide «ABANDONAR Y JUGAR»; si la instantánea ya no valida al reanudar, se descarta con aviso y se puede jugar normal. Textos en español con su traducción en `translations_en.gd`.
- [x] **RUN-RESUME-07 — Regresión y verificación.** Ver «Evidencia». Pendiente solo lo que exige dispositivo (ver «Próximo paso»).

## Evidencia

- `godot --headless --path . --script tools/run_tests.gd`: **1337 comprobaciones correctas, 0 fallidas.** Pruebas nuevas: `run_snapshot_contract` (versión, fase, escenario bloqueado, héroe no poseído, vida 0, colecciones dañadas, `active_run` texto/número/null/versión vieja al cargar, guardar sin tocar energía/oro), `run_resume_world` (salir no cobra orbes; reanudar no cobra energía ni registra estadísticas; vuelve en pausa; tiempo, bajas, XP, élite único, orbes con su valor, cofre, charco, pasivas, vida y posición, eventos disparados, botín, oro de la run contado una vez, sin arma ni enemigos iniciales extra), `run_resume_level_up_and_boss` (misma elección y cartas, rerolls y niveles intactos, un solo jefe, música de jefe, elegir carta cierra la subida), `run_end_settles_once` (la run nueva se guarda desde el inicio; la derrota borra la instantánea, registra bajas y botín una vez, deja el lote cerrado; repetir `end_run` no suma nada), `run_forfeit` (abandonar desde el menú da XP de derrota, bajas y botín una vez; repetir no entrega nada ni toca energía) y casos de traducción de los textos nuevos.
- `godot --headless --path . --import`: proyecto cargado y `RunSnapshot` registrada sin errores de parseo. Único archivo generado nuevo: `scripts/systems/run_snapshot.gd.uid` (corresponde al script nuevo). Ningún `.import` cambió por esta tarea.
- `tools/check_translations.gd`: 642 textos revisados; 5 sin traducir («Ajustes» en Inicio y 4 del Códex), todos de cambios locales previos a esta tarea, no de esta función.
- Capturas en ventana real (persistencia apagada, instantánea en memoria) a 390×844 en español y 412×915 en inglés: tarjeta de Inicio sin desplazar el escenario ni «JUGAR», confirmación de nueva run, partida reanudada en pausa con «GUARDAR Y SALIR» / «ABANDONAR», confirmación de abandono, aviso tras guardar y salir, y «ABANDONAR Y JUGAR» arrancando una run nueva (tiempo 2 s) que queda guardada.
- El guardado real del perfil (`%APPDATA%\Godot\app_userdata\Emberfall\emberfall_save.json`) se respaldó antes y quedó idéntico tras todas las ejecuciones.

## Próximo paso

Probar en un teléfono Android con un build de depuración: (1) en combate, enviar la app a segundo plano y matarla desde recientes; reabrir y reanudar; (2) lo mismo con la elección de nivel abierta y con el jefe en pantalla; (3) comprobar que no hay tirones perceptibles al guardar con muchas entidades (gama baja). Si todo pasa, cerrar este documento.
