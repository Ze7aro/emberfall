Add-Type -AssemblyName System.Drawing
$out='assets\ui\kit\UI_KIT_05_individual';New-Item -ItemType Directory -Force -Path $out|Out-Null;$bmp=[System.Drawing.Bitmap]::new((Resolve-Path 'assets\UI_KIT_05.png').Path)
function C($n,$x,$y,$w,$h){$c=$bmp.Clone([System.Drawing.Rectangle]::new($x,$y,$w,$h),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$t=Join-Path $out ($n+'.png');$tmp=$t+'.tmp.png';$c.Save($tmp,[System.Drawing.Imaging.ImageFormat]::Png);$c.Dispose();if(Test-Path $t){Remove-Item $t -Force};Move-Item $tmp $t}
$i=@(
@('ranura_vacia',20,53,108,107),@('ranura_seleccionada',137,53,108,107),@('ranura_bloqueada',258,53,108,107),@('ranura_deshabilitada',379,53,108,107),
@('rareza_comun',526,53,108,107),@('rareza_poco_comun',648,53,108,107),@('rareza_raro',770,53,108,107),@('rareza_epico',891,53,108,107),@('rareza_legendario',1013,53,108,107),
@('marco_heroe_normal',1170,52,150,155),@('marco_heroe_seleccionado',1350,40,160,168),
@('tarjeta_heroe_normal',23,282,150,173),@('tarjeta_heroe_seleccionada',182,267,154,188),@('tarjeta_heroe_bloqueada',346,282,150,173),
@('barra_fina_200_vacia',541,278,274,42),@('barra_fina_200_relleno',840,278,274,42),@('barra_fina_100_vacia',550,378,155,38),@('barra_fina_100_turquesa',730,378,122,38),@('barra_fina_100_violeta',866,378,122,38),@('barra_fina_100_verde',1001,378,122,38),
@('icono_correo',1177,325,93,101),@('icono_reloj',1304,325,75,101),@('icono_xp',1411,325,96,101),
@('fondo_vertical_inicio',25,555,112,325),@('fondo_vertical_mazmorras',147,555,112,325),@('fondo_vertical_tienda_misiones',270,555,112,325),@('fondo_vertical_mejoras_heroes',392,555,112,325),@('fondo_vertical_victoria',518,555,112,325),
@('fondo_horizontal_derrota',670,550,367,66),@('fondo_horizontal_carga',670,639,367,66),@('fondo_horizontal_pausa',670,735,367,66),@('fondo_horizontal_perfil',670,833,367,66),
@('logo_emberfall',1080,529,430,180),@('cabecera_configuracion',1085,772,426,104),@('cabecera_pausa',1085,887,426,105)
)
foreach($x in $i){C $x[0] $x[1] $x[2] $x[3] $x[4]};$bmp.Dispose();$z='assets\ui\kit\UI_KIT_05_individual.zip';if(Test-Path $z){Remove-Item $z -Force};Compress-Archive -Path "$out\*.png" -DestinationPath $z -CompressionLevel Optimal;Write-Output "Created $($i.Count) individual files and $z"
