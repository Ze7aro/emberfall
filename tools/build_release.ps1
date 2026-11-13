# Genera el AAB firmado de release para subir a Google Play.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File tools\build_release.ps1
#   powershell -ExecutionPolicy Bypass -File tools\build_release.ps1 -VersionCode 2 -VersionName "1.0.0"
#
# La contrasena de la clave se pide en pantalla y solo vive en este proceso:
# no se escribe en export_presets.cfg ni en ningun archivo del proyecto.
# (Godot la lee de las variables GODOT_ANDROID_KEYSTORE_RELEASE_*.)
#
# -VersionCode / -VersionName actualizan los dos presets de export_presets.cfg.
# Google Play rechaza un AAB cuyo VersionCode no sea mayor que el anterior.
#
# Cierra el editor de Godot antes de ejecutarlo: el editor abierto puede
# reescribir export_presets.cfg. La exportacion tarda unos 10-15 minutos.

param(
    [string]$KeystorePath = (Join-Path $env:USERPROFILE ".emberfall\emberfall-release.keystore"),
    [string]$Alias = "emberfall",
    [int]$VersionCode = 0,
    [string]$VersionName = "",
    [string]$Preset = "Android Release",
    [string]$Output = "build/android/Emberfall.aab",
    [string]$Godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe",
    [string]$JavaHome = "C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"
)

$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
Set-Location $project

if (-not (Test-Path $KeystorePath)) {
    Write-Host "No existe la clave $KeystorePath. Creala con tools\create_release_keystore.ps1" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $Godot)) {
    Write-Host "No se encontro Godot en $Godot. Pasa -Godot con la ruta del ejecutable." -ForegroundColor Red
    exit 1
}

# --- Version -----------------------------------------------------------------
$presets = Join-Path $project "export_presets.cfg"
if ($VersionCode -gt 0 -or $VersionName -ne "") {
    $text = [System.IO.File]::ReadAllText($presets)
    if ($VersionCode -gt 0) {
        $text = [regex]::Replace($text, "(?m)^version/code=\d+", "version/code=$VersionCode")
    }
    if ($VersionName -ne "") {
        $text = [regex]::Replace($text, '(?m)^version/name="[^"]*"', "version/name=`"$VersionName`"")
    }
    [System.IO.File]::WriteAllText($presets, $text, (New-Object System.Text.UTF8Encoding($false)))
}
$current = Select-String -Path $presets -Pattern '^version/(code|name)=' | Select-Object -First 2 | ForEach-Object { $_.Line }
Write-Host ("Version: " + ($current -join "  "))

# --- Password (never stored) ---------------------------------------------------
$hadPassword = [bool]$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
if (-not $hadPassword) {
    $secure = Read-Host "Contrasena de la clave de release" -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = (Resolve-Path $KeystorePath).Path
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $Alias

# --- Export ----------------------------------------------------------------------
$outputPath = Join-Path $project $Output
$outputDir = Split-Path -Parent $outputPath
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force $outputDir | Out-Null
}
if (Test-Path $outputPath) {
    Remove-Item $outputPath -Confirm:$false
}

Write-Host "Exportando '$Preset' a $Output (10-15 minutos)..."
$log = Join-Path $outputDir "release_export.log"
try {
    # Godot is a windowed program: PowerShell would not wait for it with "&",
    # so it is started explicitly and waited for.
    $arguments = "--headless --path `"$project`" --export-release `"$Preset`" `"$Output`""
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -NoNewWindow -Wait -PassThru -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    $exitCode = $process.ExitCode
} finally {
    if (-not $hadPassword) {
        Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -ErrorAction SilentlyContinue
    }
}

if ($exitCode -ne 0 -or -not (Test-Path $outputPath)) {
    Write-Host "La exportacion fallo. Revisa $log" -ForegroundColor Red
    Select-String -Path $log -Pattern "ERROR|FAILED|What went wrong|keystore" | Select-Object -First 15 | ForEach-Object { Write-Host $_.Line }
    exit 1
}

# --- Verify the signature ----------------------------------------------------------
$jarsigner = Join-Path $JavaHome "bin\jarsigner.exe"
if (Test-Path $jarsigner) {
    $verify = & $jarsigner -verify $outputPath 2>&1 | Out-String
    if ($verify -match "jar verified") {
        Write-Host "Firma verificada." -ForegroundColor Green
    } else {
        Write-Host "ATENCION: jarsigner no pudo verificar la firma:" -ForegroundColor Yellow
        Write-Host $verify
    }
}

$size = [math]::Round((Get-Item $outputPath).Length / 1MB, 1)
Write-Host "Listo: $Output ($size MB). Subelo a Google Play Console." -ForegroundColor Green
