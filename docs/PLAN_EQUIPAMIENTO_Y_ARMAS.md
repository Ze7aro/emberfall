# Plan: armas de héroe y equipamiento

Decisiones tomadas (2026-11-03):
- **Armas de héroe estilo Vampire Survivors.** Cada héroe arranca solo con su ataque, que pasa a ser un arma de nivel 1. Los ataques de los otros héroes aparecen al subir de nivel, pero solo los que desbloqueaste: primero desbloqueás al héroe y después, con un desafío con ese héroe, desbloqueás su arma para todos.
- **Casilleros:** 6 activas y 6 pasivas por partida.
- **Equipamiento completo:** más stats, objetos con nivel, rareza legendaria con efecto único y sets.
- **Dónde se consigue:** baúles de la Tienda, jefes y élites en partida, misiones y mazmorras.

---

## Cómo está hoy

| Tema | Estado actual |
|---|---|
| Héroes | 14, cada uno con un ataque básico único y una habilidad inicial del pool de 12 |
| Habilidades | 12 activas y 12 pasivas, 4 casilleros de cada una, nivel máximo 5, con evoluciones |
| Equipamiento | 6 casilleros, 18 objetos (común, raro y épico), solo daño, vida o velocidad |
| Obtención | Solo baúles de la Tienda; un repetido se convierte en oro |
| Arte de objetos | Un ícono genérico de 32 px por casillero |

---

## Parte A: armas de héroe

### Cómo funciona
- Al empezar la partida, el héroe tiene **su arma en nivel 1** y nada más. Ya no arranca con una habilidad inicial.
- Al subir de nivel pueden aparecer:
  - las 12 habilidades actuales;
  - las armas de otros héroes, **solo si están desbloqueadas**;
  - las pasivas.
- Armas y habilidades comparten los **6 casilleros de activas**.
- Cada arma tiene **5 niveles**. Cada nivel mejora algo distinto:
  - Nv. 2: +30 % de daño.
  - Nv. 3: +1 proyectil.
  - Nv. 4: atraviesa 1 enemigo más y +20 % de alcance.
  - Nv. 5: +30 % de daño y ataca 20 % más rápido.
- El efecto del elemento viaja con el arma: el Disparo de Fuego quema aunque lo use otro héroe.
- Las armas tienen **evolución** como las habilidades: nivel 5 más una pasiva emparejada da una versión dorada. Esto va en una fase posterior.

### Desbloqueo
Para usar el arma de un héroe con otros:
1. Hay que tener desbloqueado al héroe (compra o requisito, como hoy).
2. Hay que cumplir **su desafío jugando con ese héroe**.

Desafíos propuestos (editables):

| Héroe | Arma | Desafío con ese héroe |
|---|---|---|
| Vaelor | Disparo de Fuego | Sobreviví 5 minutos |
| Azyren | Disparo de Hielo | Congelá 300 enemigos |
| Orven | Disparo de Veneno | Eliminá 300 enemigos envenenados |
| Zerath | Disparo Lunar | Llegá al nivel 15 |
| Sylven | Flecha | Eliminá 500 enemigos |
| Halvek | Disparo Rúnico | Sobreviví 8 minutos |
| Mordrak | Tajo en U | Eliminá 3 élites |
| Kaelgor | Grieta de Impacto | Derrotá a un jefe |
| Torvak | Hacha Arrojadiza | Eliminá 800 enemigos |
| Theron | Estocada | Sobreviví 10 minutos sin perder más de 3 corazones |
| Cinder | Bala Compacta | Llegá al nivel 20 |
| Eldren | Disparo Mágico | Evolucioná una habilidad |
| Raiken | Onda de Puño | Eliminá 1000 enemigos |
| Darven | Corte en X | Derrotá a 2 jefes |

Al cumplirlo, aparece un aviso: "Arma desbloqueada: Flecha".

### Pantallas que cambian
- **Selección de héroe:** debajo de cada héroe se muestran su arma y el estado del desafío (por ejemplo, 230/500).
- **Códex:** sección nueva "Armas", con las bloqueadas como "???" y su desafío.
- **Subir de nivel:** el arma se muestra con su ícono, en un círculo con el color del héroe.
- **Barra de la partida y pausa:** 6 + 6 casilleros.

---

## Parte B: equipamiento completo

### Objetos
- **Rarezas:** común, raro, épico y **legendario** (nueva).
- **Stat principal fijo por casillero:**

| Casillero | Stat principal |
|---|---|
| Arma | Daño |
| Armadura | Vida |
| Casco | Bloqueo |
| Amuleto | Enfriamiento |
| Anillo | Crítico |
| Botas | Velocidad |

- **Stats secundarias al azar** según la rareza: común 0, raro 1, épico 2, legendario 2 más un efecto único. Se eligen entre área, imán, oro, experiencia, regeneración y velocidad de proyectil.
- **Efectos únicos de los legendarios** (ejemplos):
  - Al matar, 3 % de chance de soltar un corazón.
  - Cada 10 s, la próxima habilidad hace el doble de daño.
  - Al recibir daño, nova que empuja a los enemigos.

### Nivel de los objetos
- Cada objeto sube del **nivel 1 al 10**. Cada nivel mejora sus stats.
- Para subirlo se usa **oro + Esencia**, un material nuevo.
- **Repetidos y objetos que no querés:** se *desarman* y dan Esencia. Esto reemplaza la conversión a oro de hoy.

### Sets
- **3 sets**, uno por capítulo:
  - Criptas (cripta / vacío)
  - Cavernas (hielo / cristal)
  - Forja (fuego / brasa)
- Cada set tiene 6 piezas, una por casillero.
- **Bonus por piezas equipadas:**
  - 2 piezas: un bonus chico (por ejemplo, +10 % de daño de fuego).
  - 4 piezas: un efecto del set (por ejemplo, tus ataques queman).
- Las piezas de un set salen en su capítulo.

### Dónde se consiguen
| Fuente | Qué da |
|---|---|
| Baúl común (Tienda) | Común o raro |
| Baúl épico (Tienda) | Raro o épico, con chance chica de legendario |
| Élites en partida | Chance de soltar un objeto común o raro del set del capítulo |
| Jefes en partida | Un objeto seguro, raro o mejor, del set del capítulo |
| Misiones | Esencia en los hitos diarios y un objeto en el hito semanal |
| Mazmorras | Objeto épico o legendario al completarla por primera vez, y Esencia las siguientes veces |

Lo que se encuentra en la partida se guarda al terminar, aunque pierdas, y se muestra en la pantalla de resultado.

### Pantallas que cambian
- **Detalle del objeto (nuevo):** stats, nivel, set y efecto, más la comparación con lo que tenés equipado (flechas verde y roja). Botones Equipar, Mejorar y Desarmar.
- **Mochila:**
  - Borde con el color de la rareza.
  - Nivel en la esquina.
  - Ordenar por rareza, casillero o nivel.
- **Equipamiento:** stats totales del héroe y bonus de set activos.
- **HUD superior:** contador de Esencia junto al oro y las gemas.

### Guardado
Los 18 objetos actuales se convierten al sistema nuevo y se conservan, en nivel 1 y con su rareza.

---

## Fases (cada una se prueba y se commitea por separado)

| # | Fase | Qué se puede probar al terminar |
|---|---|---|
| 1 | ✅ Casilleros 6 + 6 | Una partida con 6 activas y 6 pasivas, barra y pausa incluidas |
| 2 | ✅ Ataques de héroe convertidos en armas | Cada héroe arranca con su arma, que sube de nivel 1 a 5 al subir de nivel |
| 3 | ✅ Armas de otros héroes en el pool y desbloqueo | Desafío con progreso, aviso al desbloquear y el arma apareciendo con otro héroe |
| 4 | ✅ Pantallas de armas | Selección de héroe con el arma y su desafío, Códex de armas |
| 5 | Equipamiento: datos nuevos | Stats nuevas aplicadas en partida, rareza legendaria y guardado convertido |
| 6 | Equipamiento: detalle, mejorar y desarmar | Subir un objeto con oro y Esencia, desarmar y comparar |
| 7 | Fuentes de equipamiento | Drops de élites y jefes, misiones, mazmorras y baúles nuevos |
| 8 | Sets y legendarios | Bonus de 2 y 4 piezas y efectos únicos funcionando |
| 9 | Evoluciones de armas | 14 evoluciones doradas |
| 10 | Arte | Íconos de las 14 armas y de los objetos (prompts en el mismo formato que `PROMPTS_ICONOS.md`) |

Mientras falte el arte de las fases 2 a 8, se usan íconos provisorios: el sprite del proyectil del héroe para las armas y el ícono del casillero con el color de la rareza para los objetos.

## A definir más adelante
- Desafíos y números finales (los de la tabla son una propuesta).
- Nombres y efectos de los 3 sets y de los legendarios.
- Precio en oro y Esencia de cada nivel de objeto.
