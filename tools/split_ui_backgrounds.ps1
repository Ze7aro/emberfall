Add-Type -AssemblyName System.Drawing
$src='assets\UI_KIT_FONDOS.png'; $out='assets\ui\backgrounds\UI_KIT_FONDOS_individual'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$bmp=[System.Drawing.Bitmap]::new((Resolve-Path $src).Path)
function Save-Crop($name,$x,$y,$w,$h) {
  $c=$bmp.Clone([System.Drawing.Rectangle]::new($x,$y,$w,$h),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $target=Join-Path $out ($name+'.png'); $tmp=$target+'.tmp.png'
  $c.Save($tmp,[System.Drawing.Imaging.ImageFormat]::Png); $c.Dispose()
  if(Test-Path $target){Remove-Item -LiteralPath $target -Force}; Move-Item -LiteralPath $tmp -Destination $target
}
$items=@(
 @('bg_inicio',8,159,207,505),@('bg_tienda',225,159,207,505),@('bg_heroes',443,159,207,505),@('bg_mejoras',662,159,207,505),@('bg_misiones',881,159,207,505),@('bg_mazmorras',1100,159,207,505),@('bg_victoria',1320,159,207,505),
 @('bg_derrota',8,752,368,226),@('bg_carga',392,752,366,226),@('bg_pausa',784,752,366,226),@('bg_perfil',1168,752,359,226)
)
foreach($i in $items){Save-Crop $i[0] $i[1] $i[2] $i[3] $i[4]}
$bmp.Dispose()
$zip='assets\ui\backgrounds\UI_KIT_FONDOS_individual.zip'; if(Test-Path $zip){Remove-Item -LiteralPath $zip -Force}
Compress-Archive -Path (Join-Path $out '*.png') -DestinationPath $zip -CompressionLevel Optimal
Write-Output "Created $($items.Count) backgrounds and $zip"
