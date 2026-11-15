<#
  Arnes local de verificacion (equipo Windows de desarrollo).

  Compila los ayudantes Java en .work\classes y ejecuta tools\run_tests.py con:
    * SMIPS_WORK      directorio de trabajo del repo (MARS no puede escribir en
                      los directorios de tempfile.mkdtemp de este equipo),
    * SMIPS_JVM_OPTS  preferencias de Logisim en memoria (sin registro),
    * SMIPS_CP_EXTRA  clases locales en el classpath.

  Uso:
    .\tools\run_local.ps1                          # todos los programas
    .\tools\run_local.ps1 programs\hello.asm       # uno solo
    .\tools\run_local.ps1 -Assemble programs\hello.asm
#>
param(
    [switch]$Assemble,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Fuentes
)
$ErrorActionPreference = 'Stop'
$tools = $PSScriptRoot
$raiz = Split-Path -Parent $tools
$work = Join-Path $raiz '.work'
$clases = Join-Path $work 'classes'
New-Item -ItemType Directory -Force -Path $work, $clases | Out-Null

if (-not $env:LOGISIM_JAR) {
    $env:LOGISIM_JAR = 'C:\Program Files\logisim-evolution\app\logisim-evolution-5.0.0-all.jar'
}
if (-not $env:MARS_JAR) {
    $env:MARS_JAR = Join-Path $env:USERPROFILE 'Downloads\Mars4_5.jar'
}
$env:SMIPS_WORK = $work
$env:SMIPS_JVM_OPTS = '-Djava.util.prefs.PreferencesFactory=MemPrefsFactory'
$env:SMIPS_CP_EXTRA = $clases

foreach ($archivo in 'MemPrefsFactory.java', 'ListAttrs.java') {
    & javac -encoding UTF-8 -cp $env:LOGISIM_JAR -d $clases (Join-Path $tools $archivo)
    if ($LASTEXITCODE -ne 0) { throw "javac fallo con $archivo" }
}

Push-Location $raiz
try {
    if ($Assemble) {
        if (-not $Fuentes) { $Fuentes = @('programs\hello.asm') }
        foreach ($fuente in $Fuentes) {
            & python (Join-Path $tools 'assemble.py') $fuente
            if ($LASTEXITCODE -ne 0) { throw "assemble.py fallo con $fuente" }
        }
    } else {
        & python (Join-Path $tools 'run_tests.py') @Fuentes
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
