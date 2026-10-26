Add-Type -AssemblyName System.Drawing
$out='assets\ui\kit\UI_KIT_HIGH_PRIORITY_individual';New-Item -ItemType Directory -Force -Path $out|Out-Null;$bmp=[System.Drawing.Bitmap]::new((Resolve-Path 'assets\UI_KIT_HIGH_PRIORITY.png').Path)
function C($n,$x,$y,$w,$h){$c=$bmp.Clone([System.Drawing.Rectangle]::new($x,$y,$w,$h),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$t=Join-Path $out ($n+'.png');$tmp=$t+'.tmp.png';$c.Save($tmp,[System.Drawing.Imaging.ImageFormat]::Png);$c.Dispose();if(Test-Path $t){Remove-Item $t -Force};Move-Item $tmp $t}
$i=@(
@('top_hud_frame',20,8,756,284),@('hud_slot_coin',779,80,110,130),@('hud_slot_gem',913,80,110,130),@('hud_slot_energy',1048,80,112,130),@('hud_slot_xp',1182,80,112,130),@('hud_btn_profile',1329,80,90,130),@('hud_btn_settings',1424,80,90,130),
@('icon_coin',30,370,100,105),@('icon_gem',137,365,105,110),@('icon_energy',259,365,100,110),@('icon_xp',374,365,100,110),@('hud_resource_coin',520,345,225,130),@('hud_resource_gem',770,345,225,130),@('hud_resource_energy',1034,345,225,130),@('hud_resource_xp',1293,345,225,130),
@('footer_frame',30,543,1008,250),@('footer_btn',1135,582,150,205),@('footer_btn_selected',1325,582,180,205),
@('icon_coin_small',26,845,65,70),@('icon_coin_medium',116,830,80,85),@('icon_coin_large',210,815,125,125),@('icon_gem_small',379,865,65,65),@('icon_gem_medium',466,850,80,80),@('icon_gem_large',575,830,125,125),@('icon_energy_small',764,870,65,65),@('icon_energy_medium',850,850,80,90),@('icon_energy_large',1005,824,115,130),@('icon_xp_small',1160,880,65,65),@('icon_xp_medium',1240,850,90,90),@('icon_xp_large',1392,815,125,125)
)
foreach($x in $i){C $x[0] $x[1] $x[2] $x[3] $x[4]};$bmp.Dispose();$z='assets\ui\kit\UI_KIT_HIGH_PRIORITY_individual.zip';if(Test-Path $z){Remove-Item $z -Force};Compress-Archive -Path "$out\*.png" -DestinationPath $z -CompressionLevel Optimal;Write-Output "Created $($i.Count) individual files and $z"
