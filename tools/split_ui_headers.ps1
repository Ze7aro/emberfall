Add-Type -AssemblyName System.Drawing
$src='assets\UI_KIT_CABEZERAS.png'; $out='assets\ui\headers\UI_KIT_CABEZERAS_individual'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$bmp=[System.Drawing.Bitmap]::new((Resolve-Path $src).Path)
function Save-Crop($name,$x,$y,$w,$h){$c=$bmp.Clone([System.Drawing.Rectangle]::new($x,$y,$w,$h),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$t=Join-Path $out ($name+'.png');$tmp=$t+'.tmp.png';$c.Save($tmp,[System.Drawing.Imaging.ImageFormat]::Png);$c.Dispose();if(Test-Path $t){Remove-Item -LiteralPath $t -Force};Move-Item -LiteralPath $tmp -Destination $t}
$items=@(
 @('inicio_header',15,123,737,126),@('tienda_header',784,123,737,126),
 @('heroes_header',15,280,737,126),@('mejoras_header',784,280,737,126),
 @('misiones_header',15,438,737,126),@('mazmorras_header',784,438,737,126),
 @('victoria_header',15,596,737,126),@('derrota_header',784,596,737,126),
 @('carga_header',15,753,737,135),@('perfil_header',784,753,737,135),
 @('decorador_linea',55,922,375,55),@('decorador_esquinas',455,916,104,68),@('decorador_bat_skull',585,916,390,68),@('decorador_cadena',1032,916,164,68),@('decorador_linea_corta',1274,916,243,68)
)
foreach($i in $items){Save-Crop $i[0] $i[1] $i[2] $i[3] $i[4]}
$bmp.Dispose();$zip='assets\ui\headers\UI_KIT_CABEZERAS_individual.zip';if(Test-Path $zip){Remove-Item -LiteralPath $zip -Force};Compress-Archive -Path (Join-Path $out '*.png') -DestinationPath $zip -CompressionLevel Optimal;Write-Output "Created $($items.Count) assets and $zip"
