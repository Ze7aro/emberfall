# Crea la clave de firma de release de Emberfall (una sola vez).
#
# Uso:   powershell -ExecutionPolicy Bypass -File tools\create_release_keystore.ps1
#
# keytool pregunta la contrasena y los datos del certificado en pantalla; nada
# se guarda en el repositorio. Por defecto la clave queda FUERA del proyecto:
#   %USERPROFILE%\.emberfall\emberfall-release.keystore
#
# IMPORTANTE: guarda una copia de ese archivo y de su contrasena en un lugar
# seguro (gestor de contrasenas + copia externa). Con "Firma de apps de Play"
# activada, esta es la clave de SUBIDA: si se pierde, Google puede reemplazarla
# tras verificar tu identidad; sin esa opcion, perderla impide actualizar el juego.

param(
    [string]$KeystorePath = (Join-Path $env:USERPROFILE ".emberfall\emberfall-release.keystore"),
    [string]$Alias = "emberfall",
    [string]$JavaHome = "C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"
)

$ErrorActionPreference = "Stop"

if (Test-Path $KeystorePath) {
    Write-Host "Ya existe una clave en $KeystorePath. No se sobrescribe." -ForegroundColor Yellow
    exit 1
}

$keytool = Join-Path $JavaHome "bin\keytool.exe"
if (-not (Test-Path $keytool)) {
    $found = Get-Command keytool -ErrorAction SilentlyContinue
    if ($null -eq $found) {
        Write-Host "No se encontro keytool. Pasa -JavaHome con la carpeta de tu JDK." -ForegroundColor Red
        exit 1
    }
    $keytool = $found.Source
}

$folder = Split-Path -Parent $KeystorePath
if (-not (Test-Path $folder)) {
    New-Item -ItemType Directory -Force $folder | Out-Null
}

Write-Host "Creando la clave en $KeystorePath (alias: $Alias)."
Write-Host "keytool va a pedir una contrasena (minimo 6 caracteres) y tus datos."
& $keytool -genkeypair -v -keystore $KeystorePath -alias $Alias -keyalg RSA -keysize 2048 -validity 10000
if ($LASTEXITCODE -ne 0) {
    Write-Host "keytool fallo; no se creo la clave." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Clave creada: $KeystorePath" -ForegroundColor Green
Write-Host "Haz ahora una copia de seguridad del archivo y de la contrasena."
Write-Host "Siguiente paso: tools\build_release.ps1"
