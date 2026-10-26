Add-Type -AssemblyName System.Drawing
function Export-Set($src,$folder,$zip,$items){
 $out="assets\ui\kit\$folder";New-Item -ItemType Directory -Force -Path $out|Out-Null;$bmp=[System.Drawing.Bitmap]::new((Resolve-Path $src).Path)
 foreach($i in $items){$c=$bmp.Clone([System.Drawing.Rectangle]::new($i[1],$i[2],$i[3],$i[4]),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$t=Join-Path $out ($i[0]+'.png');$tmp=$t+'.tmp.png';$c.Save($tmp,[System.Drawing.Imaging.ImageFormat]::Png);$c.Dispose();if(Test-Path $t){Remove-Item $t -Force};Move-Item $tmp $t}
 $bmp.Dispose();$z="assets\ui\kit\$zip";if(Test-Path $z){Remove-Item $z -Force};Compress-Archive -Path "$out\*.png" -DestinationPath $z -CompressionLevel Optimal
}
$a=@(
@('boton_primario_normal',35,72,240,78),@('boton_primario_presionado',286,72,240,78),@('boton_primario_deshabilitado',526,72,240,78),@('boton_secundario_normal',807,72,240,78),@('boton_secundario_presionado',1048,72,240,78),@('boton_secundario_deshabilitado',1272,72,235,78),
@('barra_progreso_vacia',37,255,421,51),@('barra_progreso_relleno',480,255,330,51),@('barra_ronda_vacia',836,255,328,51),@('barra_ronda_relleno',1184,255,322,51),
@('marco_heroe',47,420,220,198),@('ranura_vacia',341,421,164,146),@('ranura_seleccionada',537,421,164,146),@('ranura_equipada',733,421,164,146),@('ranura_bloqueada',931,421,164,146),@('ranura_deshabilitada',1128,421,164,146),@('ranura_sin_cruz',1325,421,164,146),
@('marco_top_hud_largo',42,675,950,133),@('marco_top_hud_corto',1046,675,460,133),@('marco_footer',35,859,905,135),@('marco_panel_normal',995,849,151,145),@('marco_panel_seleccionado',1178,849,151,145),@('marco_panel_deshabilitado',1353,849,151,145)
)
$b=@(
@('adorno_esquina_1',39,151,86,77),@('adorno_esquina_2',139,151,86,77),@('adorno_esquina_3',239,151,75,77),@('adorno_skull',330,151,76,77),@('adorno_bat_skull',39,268,367,90),
@('divisor_largo',438,151,326,62),@('divisor_medio',438,216,326,62),@('divisor_corto',438,279,326,62),@('divisor_cadena',438,326,326,53),
@('indicador_alerta',816,150,55,55),@('indicador_mejora',895,150,55,55),@('indicador_evento',975,150,55,55),@('indicador_chat',1055,150,58,55),@('banderas_estados',807,215,273,158),@('tag_nuevo',1096,214,109,48),@('tag_evento',1096,267,109,48),@('tag_oferta',1096,320,109,48),
@('flechas_navegacion',1254,151,252,70),@('pasos',1254,223,252,51),@('marcadores_circulares',38,409,355,166),@('estados_elementos',438,409,525,165),@('etiquetas_tags',982,409,524,165),
@('iconos_estado_1',40,648,380,91),@('iconos_estado_2',40,742,380,91),@('elementos_lista',438,648,380,185),@('barras_especiales',830,648,315,185),@('ventanas_flotantes',1197,648,310,185),
@('marcadores_cantidad',39,886,382,102),@('elementos_enfasis',438,886,524,102),@('cursores_punteros',982,886,245,102),@('varios',1240,886,267,102)
)
Export-Set 'assets\UI_KIT_03.png' 'UI_KIT_03_individual' 'UI_KIT_03_individual.zip' $a
Export-Set 'assets\UI_KIT_04.png' 'UI_KIT_04_individual' 'UI_KIT_04_individual.zip' $b
Write-Output 'Created UI_KIT_03 and UI_KIT_04 exports'
