Add-Type -AssemblyName System.Drawing

$src = 'assets\UI_KIT_01.png'
$out = 'assets\ui\kit\UI_KIT_01_individual'
New-Item -ItemType Directory -Force -Path $out | Out-Null

$bmp = [System.Drawing.Bitmap]::new((Resolve-Path $src).Path)

function Save-Crop([string]$name, [int]$x, [int]$y, [int]$w, [int]$h) {
    $rect = [System.Drawing.Rectangle]::new($x,$y,$w,$h)
    $crop = $bmp.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $target = Join-Path $out ($name + '.png')
    $tmp = $target + '.tmp.png'
    $crop.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
    Move-Item -LiteralPath $tmp -Destination $target -Force
}

# All coordinates are pixel coordinates in the supplied 1536x1024 sheet.
$items = @(
    # Panels
    @('panel_principal',28,214,268,132), @('panel_secundario',311,224,157,108), @('panel_modal',490,214,196,132),
    @('barra_contenedor',28,403,258,85), @('tarjeta_item',315,403,153,85), @('mensaje_tooltip',490,403,198,88),
    # Buttons
    @('boton_primario_normal',726,216,244,60), @('boton_primario_presionado',993,216,245,60), @('boton_primario_deshabilitado',1263,216,244,60),
    @('boton_secundario_normal',727,316,243,59), @('boton_secundario_presionado',994,316,244,59), @('boton_secundario_deshabilitado',1263,316,244,59),
    @('boton_icono_atras',733,412,81,54), @('boton_cerrar',876,412,81,54), @('boton_menu',1009,412,81,54), @('boton_confirmar',1177,412,328,58),
    @('boton_eliminar',728,499,264,48), @('boton_cancelar',1015,499,249,48), @('boton_aceptar',1288,499,217,48),
    # Progress bars
    @('barra_progreso_general',31,600,312,31), @('barra_vida',31,639,312,31), @('barra_experiencia',31,678,312,31), @('barra_energia',31,717,312,31),
    # Inventory/equipment slots
    @('ranura_vacia',596,619,82,87), @('ranura_seleccionada',700,619,84,87), @('ranura_con_item',804,619,84,87), @('ranura_epico',908,619,84,87), @('ranura_bloqueada',1011,619,84,87), @('ranura_equipado',1113,619,84,87),
    # Hero frames
    @('marco_heroe_normal',1248,614,103,104), @('marco_heroe_seleccionado',1380,614,106,104),
    # Main icons
    @('icono_moneda',44,808,54,57), @('icono_gema',125,808,54,57), @('icono_energia',209,808,54,57), @('icono_vida',291,808,54,57), @('icono_ataque',374,808,54,57), @('icono_defensa',457,808,54,57), @('icono_velocidad',540,808,54,57),
    @('icono_cofre',44,900,54,57), @('icono_llave',125,900,54,57), @('icono_pocion',209,900,54,57), @('icono_pergamino',291,900,54,57), @('icono_bolsa',374,900,54,57), @('icono_engrane',457,900,54,57), @('icono_logro',540,900,54,57),
    # Badges
    @('badge_comun',665,809,126,36), @('badge_poco_comun',807,809,125,36), @('badge_raro',948,809,125,36), @('badge_epico',665,858,126,36), @('badge_legendario',807,858,125,36), @('badge_nuevo',948,858,125,36),
    @('badge_notificacion',687,913,44,44), @('badge_mejora',791,913,44,44), @('badge_bloqueado',893,913,44,44), @('badge_marcador',1000,913,44,44),
    # Popup
    @('ventana_mensaje',1128,801,376,190)
)

foreach ($i in $items) { Save-Crop $i[0] $i[1] $i[2] $i[3] $i[4] }
$bmp.Dispose()

# Remove only dark pixels connected to the outside edge, preserving enclosed UI backgrounds.
foreach ($file in Get-ChildItem -LiteralPath $out -Filter '*.png') {
    $im = [System.Drawing.Bitmap]::new($file.FullName)
    $seen = New-Object 'bool[,]' $im.Width,$im.Height
    $q = [System.Collections.Generic.Queue[object]]::new()
    for ($x=0; $x -lt [int]$im.Width; $x++) { $q.Enqueue([int[]]@($x,0)); $q.Enqueue([int[]]@($x,([int]$im.Height - 1))) }
    for ($y=0; $y -lt [int]$im.Height; $y++) { $q.Enqueue([int[]]@(0,$y)); $q.Enqueue([int[]]@(([int]$im.Width - 1),$y)) }
    while ($q.Count -gt 0) {
        $p=$q.Dequeue(); [int]$x=$p[0]; [int]$y=$p[1]
        if ($x -lt 0 -or $y -lt 0 -or $x -ge $im.Width -or $y -ge $im.Height -or $seen[$x,$y]) { continue }
        $seen[$x,$y]=$true; $c=$im.GetPixel($x,$y)
        if ($c.R+$c.G+$c.B -gt 115) { continue }
        $im.SetPixel($x,$y,[System.Drawing.Color]::FromArgb(0,$c.R,$c.G,$c.B))
        $q.Enqueue([int[]]@(([int]$x + 1),$y)); $q.Enqueue([int[]]@(([int]$x - 1),$y)); $q.Enqueue([int[]]@($x,([int]$y + 1))); $q.Enqueue([int[]]@($x,([int]$y - 1)))
    }
    $tmpFile = $file.FullName + '.tmp.png'
    $im.Save($tmpFile,[System.Drawing.Imaging.ImageFormat]::Png); $im.Dispose()
    Remove-Item -LiteralPath $file.FullName -Force
    Move-Item -LiteralPath $tmpFile -Destination $file.FullName
}

$zip = 'assets\ui\kit\UI_KIT_01_individual.zip'
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $out '*') -DestinationPath $zip -CompressionLevel Optimal
Write-Output "Created $($items.Count) PNG files and $zip"
