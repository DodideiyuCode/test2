<#
.SYNOPSIS
    Script de limpeza do Xeno com animacoes avancadas no console.
.DESCRIPTION
    - Finaliza processos chamados Xeno / XENO / xeno.
    - Remove as pastas C:\Users\benic\AppData\Roaming\Xeno e C:\Users\benic\AppData\Local\Xeno.
    - Limpa todos os logs do Gerenciador de Eventos do Windows.
.NOTES
    Requer privilegios de Administrador para limpar os logs de eventos.
#>

#region ---------- FUNCOES DE ANIMACAO ----------

# Efeito typewriter: digita o texto caractere por caractere
function Write-TypeText {
    param(
        [string]$Text,
        [int]$Speed = 15,
        [ConsoleColor]$Color = 'White',
        [switch]$NewLine
    )
    foreach ($char in $Text.ToCharArray()) {
        Write-Host -NoNewline -ForegroundColor $Color $char
        Start-Sleep -Milliseconds $Speed
    }
    if ($NewLine) { Write-Host }
}

# Efeito fade: transiciona cor do texto em ondas
function Write-FadeText {
    param(
        [string]$Text,
        [int]$Delay = 40,
        [ConsoleColor[]]$Colors = @('DarkGray', 'Gray', 'White')
    )
    foreach ($color in $Colors) {
        Write-Host -NoNewline "`r$Text" -ForegroundColor $color
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host
}

# Spinner moderno com rotacao fluida e cor pulsante
function Show-Spinner {
    param(
        [string]$Message,
        [int]$Duration = 1000
    )
    $frames = @([char]0x25DC, [char]0x25DD, [char]0x25DE, [char]0x25DF)
    # Fallback ASCII se os caracteres unicode nao renderizarem
    $ascii = @('|', '/', '-', '\')
    $useAscii = $true

    $end = (Get-Date).AddMilliseconds($Duration)
    $i = 0
    while ((Get-Date) -lt $end) {
        $frame = if ($useAscii) { $ascii[$i % 4] } else { $frames[$i % 4] }
        $color = switch ($i % 4) {
            0 { 'Cyan' }
            1 { 'DarkCyan' }
            2 { 'Blue' }
            3 { 'DarkCyan' }
        }
        Write-Host -NoNewline -ForegroundColor $color "`r  $frame  $Message"
        Start-Sleep -Milliseconds 90
        $i++
    }
    Write-Host -NoNewline -ForegroundColor Green "`r  [OK]  $Message"
    Write-Host
}

# Barra de progresso com porcentagem, preenchimento animado e cor dinamica
function Show-ProgressBar {
    param(
        [string]$Message,
        [int]$Duration = 1500,
        [int]$Width = 30
    )
    $steps = 60
    $delay = [int]($Duration / $steps)
    $end = $steps
    $i = 0

    Write-Host ""
    Write-Host "  $Message" -ForegroundColor Gray
    Write-Host -NoNewline "  "

    while ($i -le $end) {
        $pct = [int](($i / $end) * 100)
        $filled = [int](($i / $end) * $Width)
        $empty = $Width - $filled

        # Cor dinamica conforme avanca
        $color = switch ($pct) {
            { $_ -lt 30 }  { 'Red' }
            { $_ -lt 60 }  { 'Yellow' }
            { $_ -lt 90 }  { 'DarkYellow' }
            default        { 'Green' }
        }

        # Monta a barra
        $bar = ''
        if ($filled -gt 0) {
            if ($filled -ge $Width) {
                $bar = '#' * $Width
            } else {
                $bar = ('#' * ($filled - 1)) + '>' + (' ' * $empty)
            }
        } else {
            $bar = '>' + (' ' * ($Width - 1))
        }

        # Aplica cor apenas no preenchimento
        $line = "  ["
        Write-Host -NoNewline -ForegroundColor DarkGray "`r  ["
        Write-Host -NoNewline -ForegroundColor $color $bar
        Write-Host -NoNewline -ForegroundColor DarkGray "]  "
        Write-Host -NoNewline -ForegroundColor White ("{0,3}%" -f $pct)

        Start-Sleep -Milliseconds $delay
        $i++
    }

    Write-Host -NoNewline -ForegroundColor DarkGray "]  "
    Write-Host -ForegroundColor Green "  OK"
    Write-Host ""
}

# Cabecalho de secao com efeito fade em ciano
function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-FadeText -Text "  >> $Title" -Delay 40 -Colors @('DarkGray', 'DarkCyan', 'Cyan', 'Cyan')
}

#endregion

#region ---------- VERIFICACAO DE PRIVILEGIOS ----------

Clear-Host
Write-TypeText -Text "  Inicializando script de limpeza do Xeno..." -Speed 12 -Color DarkCyan -NewLine
Start-Sleep -Milliseconds 400
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  [!] Execute o PowerShell como Administrador." -ForegroundColor Yellow
    Read-Host "      Pressione ENTER para sair"
    exit 1
}
Write-Host "  [OK] Privilegios de Administrador confirmados." -ForegroundColor Green
Start-Sleep -Milliseconds 600

#endregion

#region ---------- ETAPA 1: FINALIZAR PROCESSOS XENO ----------

Write-Section "Procurando processos Xeno"
Write-TypeText -Text "      Escaneando lista de processos do sistema..." -Speed 8 -Color Gray -NewLine
Show-Spinner -Message "Verificando processos ativos" -Duration 1200

$processos = Get-Process -Name Xeno -ErrorAction SilentlyContinue
if ($processos) {
    foreach ($proc in $processos) {
        Write-Host "      -> Encontrado: $($proc.Name) (PID: $($proc.Id))" -ForegroundColor Yellow
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            Write-Host "      [OK] Processo finalizado." -ForegroundColor Green
        } catch {
            Write-Host "      [ERRO] $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "      [OK] Nenhum processo Xeno em execucao." -ForegroundColor Green
}
Start-Sleep -Milliseconds 400

#endregion

#region ---------- ETAPA 2: REMOVER PASTAS ASSOCIADAS ----------

$pastas = @(
    "C:\Users\benic\AppData\Roaming\Xeno",
    "C:\Users\benic\AppData\Local\Xeno"
)

Write-Section "Removendo pastas associadas"

foreach ($pasta in $pastas) {
    if (Test-Path -LiteralPath $pasta) {
        Write-Host "      -> Removendo: $pasta" -ForegroundColor Yellow
        Show-ProgressBar -Message "Apagando arquivos..." -Duration 1200 -Width 28
        try {
            Remove-Item -LiteralPath $pasta -Recurse -Force -ErrorAction Stop
            Write-Host "      [OK] Pasta removida com sucesso." -ForegroundColor Green
        } catch {
            Write-Host "      [ERRO] $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "      [OK] Pasta nao encontrada (ja limpa): $pasta" -ForegroundColor Gray
    }
    Start-Sleep -Milliseconds 300
}

#endregion

#region ---------- ETAPA 3: LIMPAR LOGS DE EVENTOS ----------

Write-Section "Limpando logs do Gerenciador de Eventos"

$logs = wevtutil el
$total = $logs.Count
Write-TypeText -Text "      Encontrados $total logs para limpar." -Speed 8 -Color Gray -NewLine
Start-Sleep -Milliseconds 400

$i = 0
foreach ($log in $logs) {
    $i++
    $pct = [int](($i / $total) * 100)
    $filled = [int](($pct / 100) * 30)
    $empty = 30 - $filled

    $color = if ($pct -lt 50) { 'Yellow' } elseif ($pct -lt 90) { 'DarkYellow' } else { 'Green' }
    $bar = if ($filled -ge 30) { '#' * 30 } else { ('#' * $filled) + (' ' * $empty) }

    Write-Host -NoNewline "`r      ["
    Write-Host -NoNewline -ForegroundColor $color $bar
    Write-Host -NoNewline "]  "
    Write-Host -NoNewline -ForegroundColor White ("{0,3}%" -f $pct)

    wevtutil cl "$log" 2>$null
}
Write-Host ""
Write-Host "      [OK] Todos os logs foram limpos." -ForegroundColor Green
Start-Sleep -Milliseconds 400

#endregion

#region ---------- FINALIZACAO ----------

Write-Host ""
Write-FadeText -Text "  [OK] Limpeza concluida com sucesso!" -Delay 60 -Colors @('DarkGray', 'DarkGreen', 'Green', 'Green', 'Green')
Start-Sleep -Milliseconds 400

Write-Host ""
Write-Host "  Pressione qualquer tecla para sair..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

#endregion
