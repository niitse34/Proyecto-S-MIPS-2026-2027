<#
  Ejecuta todos los programas y pruebas, o fuentes especificadas, en Windows.
  Las rutas de dependencias se detectan automaticamente; MARS_JAR y LOGISIM_JAR
  pueden definirse para reemplazar la busqueda.

  Uso:
    .\tools\run_local.ps1                          # todos los programas y pruebas
    .\tools\run_local.ps1 programs\hello.asm       # uno solo
    .\tools\run_local.ps1 -Assemble programs\hello.asm
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_local.ps1
#>
param(
    [switch]$Assemble,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Fuentes,
    [int]$MaxCycles = 60000,
    [int]$Trace = 0,
    [string]$Circuit,
    [string]$JvmOpts = '',
    [switch]$NoVhdl
)
$ErrorActionPreference = 'Stop'
$tools = $PSScriptRoot
$raiz = Split-Path -Parent $tools
$work = Join-Path $raiz '.work'
$clases = Join-Path $work 'classes'

function Resolve-DependencyFile {
    param(
        [string]$Name,
        [string]$Override,
        [string[]]$Candidates,
        [string[]]$OverrideFileNames
    )
    if ($Override) {
        if (Test-Path -LiteralPath $Override -PathType Leaf) {
            return (Resolve-Path -LiteralPath $Override).Path
        }
        if (Test-Path -LiteralPath $Override -PathType Container) {
            foreach ($fileName in $OverrideFileNames) {
                $candidate = Join-Path $Override $fileName
                if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                    return (Resolve-Path -LiteralPath $candidate).Path
                }
            }
        }
        throw "$Name does not exist at: $Override"
    }
    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw "Could not find $Name. Set its environment variable or install it in a searched location."
}

$marsCandidates = @(
    (Join-Path $raiz 'Mars4_5.jar'),
    (Join-Path $tools 'Mars4_5.jar'),
    (Join-Path $env:USERPROFILE 'Downloads\Mars4_5.jar'),
    (Join-Path $env:USERPROFILE 'Apps\mars\Mars4_5.jar')
)
$logisimCandidates = @(
    (Join-Path $raiz 'logisim-evolution-5.0.0-all.jar'),
    (Join-Path $env:ProgramFiles 'logisim-evolution\app\logisim-evolution-5.0.0-all.jar'),
    (Join-Path $env:ProgramFiles 'Logisim Evolution\logisim-evolution-5.0.0-all.jar')
)
if (${env:ProgramFiles(x86)}) {
    $logisimCandidates += Join-Path ${env:ProgramFiles(x86)} 'logisim-evolution\app\logisim-evolution-5.0.0-all.jar'
}
$env:MARS_JAR = Resolve-DependencyFile 'MARS 4.5 JAR' $env:MARS_JAR $marsCandidates @('Mars4_5.jar')
$env:LOGISIM_JAR = Resolve-DependencyFile 'Logisim Evolution 5.0.0 JAR' $env:LOGISIM_JAR $logisimCandidates @('logisim-evolution-5.0.0-all.jar', 'logisim-evolution.jar')

$java = Get-Command java.exe -ErrorAction SilentlyContinue
$javac = Get-Command javac.exe -ErrorAction SilentlyContinue
if (-not $java) { throw 'Java was not found on PATH.' }
if (-not $javac) { throw 'javac was not found on PATH; install a JDK and add its bin directory to PATH.' }
$env:JAVA = $java.Source

$python = Get-Command python.exe -ErrorAction SilentlyContinue
$pythonPrefix = @()
if (-not $python) {
    $python = Get-Command py.exe -ErrorAction SilentlyContinue
    if ($python) { $pythonPrefix = @('-3') }
}
if (-not $python) { throw 'Python was not found on PATH (python.exe or py.exe).' }

Write-Host "Repository: $raiz"
Write-Host "MARS: $env:MARS_JAR"
Write-Host "Logisim: $env:LOGISIM_JAR"
Write-Host "Java: $($java.Source)"
Write-Host "Python: $($python.Source)"

New-Item -ItemType Directory -Force -Path $work, $clases | Out-Null
$env:SMIPS_WORK = $work
$env:SMIPS_JVM_OPTS = '-Djava.util.prefs.PreferencesFactory=MemPrefsFactory'
if ($JvmOpts) { $env:SMIPS_JVM_OPTS += " $JvmOpts" }
$env:SMIPS_CP_EXTRA = $clases
$env:SMIPS_MAX_CYCLES = $MaxCycles.ToString()
$env:SMIPS_TRACE = $Trace.ToString()
if ($Circuit) {
    $env:SMIPS_CIRCUIT = $Circuit
} else {
    Remove-Item Env:\SMIPS_CIRCUIT -ErrorAction SilentlyContinue
}
if ($NoVhdl) {
    $env:SMIPS_NO_VHDL = '1'
} else {
    Remove-Item Env:\SMIPS_NO_VHDL -ErrorAction SilentlyContinue
}

foreach ($archivo in 'MemPrefsFactory.java', 'ListAttrs.java') {
    & $javac.Source -encoding UTF-8 -cp $env:LOGISIM_JAR -d $clases (Join-Path $tools $archivo)
    if ($LASTEXITCODE -ne 0) { throw "javac fallo con $archivo" }
}

Push-Location $raiz
try {
    if ($Assemble) {
        if (-not $Fuentes) { $Fuentes = @('programs\hello.asm') }
        foreach ($fuente in $Fuentes) {
            & $python.Source @pythonPrefix (Join-Path $tools 'assemble.py') $fuente
            if ($LASTEXITCODE -ne 0) { throw "assemble.py fallo con $fuente" }
        }
    } else {
        $circuitPath = if ($Circuit) { $Circuit } else { Join-Path $raiz 'circuit\smips.circ' }
        $testArgs = @(
            '--circuito', $circuitPath,
            '--max-ciclos', $MaxCycles.ToString(),
            '--traza', $Trace.ToString()
        )
        if ($NoVhdl) { $testArgs += '--no-vhdl' }
        & $python.Source @pythonPrefix (Join-Path $tools 'run_tests.py') @Fuentes @testArgs
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
