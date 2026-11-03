# Emberfall SFX — paquete inicial

Paquete de 37 efectos originales generados para el prototipo de Emberfall.

## Formato

- WAV PCM mono, 44.1 kHz, 16 bits.
- `poison_puddle_loop.ogg`: versión comprimida y preparada para repetición del ambiente venenoso.
- Los archivos se encuentran separados por sistema para facilitar su importación en Godot 4.

## Importación sugerida

- `combat`, `abilities`, `status` y `boss`: bus `SFX` con sub-buses dedicados.
- `economy`: bus `SFX`.
- `progression`: bus `SFX/Player` o `SFX/Boss` según el evento.
- `ui`: bus `UI` no posicional.
- Activar loop únicamente en `poison_puddle_loop.ogg`.
- No activar loop en los restantes efectos.

## Reproducción

- Variar impactos comunes entre 0.94 y 1.06 de `pitch_scale`.
- Alternar `enemy_hit_01.wav` y `enemy_hit_02.wav`.
- Limitar impactos simultáneos para evitar saturación.
- Reproducir `critical_hit.wav` encima del golpe normal.
- Usar un único loop de veneno compartido, no uno por charco o enemigo.
- Sincronizar explosiones e impactos con el frame visual de mayor expansión.

Este paquete es una primera dirección sonora funcional. Conviene evaluarlo durante una partida real y ajustar mezcla, duración o timbre según la densidad final del combate.
