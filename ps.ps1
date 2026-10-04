<#
.SYNOPSIS
    Script de limpeza do Xeno com animações no console.
.DESCRIPTION
    - Finaliza processos chamados Xeno / XENO / xeno.
    - Remove as pastas C:\Users\benic\AppData\Roaming\Xeno e C:\Users\benic\AppData\Local\Xeno.
    - Limpa todos os logs do Gerenciador de Eventos do Windows.
    - Exibe animações (fade, spinner, barras) para tornar a execução “bonita” no CMD.
.NOTES
    Requer privilégios de Administrador para limpar os logs de eventos.
#>

#region ---------- FUNÇÕES DE ANIMAÇÃO ----------

function Write-FadeText {
    param(
        [string]$Text,
        [int]$Delay = 20,
        [ConsoleColor]$StartColor = 'DarkGray',
        [ConsoleColor]$EndColor = 'White'
    )
    # Simula um fade-in alterando a cor da string inteira
    $steps = 5
    for ($s = 1; $s -le $steps; $s++) {
        $color = if ($s -eq $steps) { $EndColor } else { $StartColor }
        Write-Host -NoNewline -ForegroundColor $color "`r$Text"
        Start-Sleep -Milliseconds $Delay
        $StartColor = switch ($StartColor) {
            'DarkGray' { 'Gray' }
            'Gray'     { 'White' }
            default    { $EndColor }
        }
    }
    Write-Host
}

function Show-Spinner {
    param(
        [string]$Message,
        [int]$Duration = 1000
    )
    $spin = @('|', '/', '-', '\')
    $end = (Get-Date).AddMilliseconds($Duration)
    $i = 0
    while ((Get-Date) -lt $end) {
        Write-Host -NoNewline -ForegroundColor Cyan "`r$($spin[$i % 4]) $Message"
        Start-Sleep -Milliseconds 100
        $i++
    }
    Write-Host -NoNewline -ForegroundColor Green "`r✔ $Message"
    Write-Host
}

function Show-Bar {
    param(
        [string]$Message,
        [int]$Total = 20,
        [int]$Delay = 50
    )
    Write-Host -NoNewline -ForegroundColor Yellow "$Message "
    for ($i = 1; $i -le $Total; $i++) {
        Write-Host -NoNewline -ForegroundColor Green '█'
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host -ForegroundColor Green ' OK'
}

#endregion

#region ---------- BANNER INICIAL ----------

Clear-Host
$banner = @"
  ██╗  ██╗███████╗███╗   ██╗ ██████╗ 
  ██║  ██║██╔════╝████╗  ██║██╔═══██╗
  ███████║█████╗  ██╔██╗ ██║██║   ██║
  ██╔══██║██╔══╝  ██║╚██╗██║██║   ██║
  ██║  ██║███████╗██║ ╚████║╚██████╔╝
  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ 
        Limpeza Automática
"@

Write-FadeText -Text $banner -Delay 30 -StartColor DarkGray -EndColor Red
Write-Host "`n"

#endregion

#region ---------- VERIFICAÇÃO DE PRIVILÉGIOS ----------

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "⚠  Este script requer privilégios de Administrador para limpar os logs de eventos." -ForegroundColor Yellow
    Write-Host "   Execute o PowerShell como Administrador e tente novamente." -ForegroundColor Yellow
    Read-Host "`nPressione ENTER para sair"
    exit 1
}

#endregion

#region ---------- ETAPA 1: FINALIZAR PROCESSOS XENO ----------

Write-FadeText -Text "🔍 Procurando processos Xeno..." -Delay 25 -StartColor DarkCyan -EndColor Cyan
Show-Spinner -Message "Escaneando processos" -Duration 800

$processos = Get-Process -Name Xeno -ErrorAction SilentlyContinue
if ($processos) {
    foreach ($proc in $processos) {
        Write-Host "   → Encontrado: $($proc.Name) (PID: $($proc.Id))" -ForegroundColor Yellow
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            Write-Host "   ✔ Processo finalizado com sucesso." -ForegroundColor Green
        } catch {
            Write-Host "   ✖ Falha ao finalizar: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ✔ Nenhum processo Xeno em execução." -ForegroundColor Green
}
Start-Sleep -Milliseconds 500

#endregion

#region ---------- ETAPA 2: REMOVER PASTAS ASSOCIADAS ----------

$pastas = @(
    "C:\Users\benic\AppData\Roaming\Xeno",
    "C:\Users\benic\AppData\Local\Xeno"
)

Write-FadeText -Text "🗑  Removendo pastas associadas..." -Delay 25 -StartColor DarkCyan -EndColor Cyan
foreach ($pasta in $pastas) {
    if (Test-Path -LiteralPath $pasta) {
        Write-Host "   → Removendo: $pasta" -ForegroundColor Yellow
        try {
            Remove-Item -LiteralPath $pasta -Recurse -Force -ErrorAction Stop
            Write-Host "   ✔ Pasta removida." -ForegroundColor Green
        } catch {
            Write-Host "   ✖ Erro ao remover: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "   ✔ Pasta não encontrada (já limpa): $pasta" -ForegroundColor Gray
    }
}
Start-Sleep -Milliseconds 500

#endregion

#region ---------- ETAPA 3: LIMPAR LOGS DE EVENTOS ----------

Write-FadeText -Text "📋 Limpando logs do Gerenciador de Eventos..." -Delay 25 -StartColor DarkCyan -EndColor Cyan
Show-Bar -Message "Limpando logs" -Total 15 -Delay 60

try {
    # Lista todos os logs e limpa um por um
    $logs = wevtutil el
    $total = $logs.Count
    $i = 0
    foreach ($log in $logs) {
        $i++
        Write-Progress -Activity "Limpando logs de eventos" -Status "$i de $total: $log" -PercentComplete (($i / $total) * 100)
        wevtutil cl "$log" 2>$null
    }
    Write-Progress -Activity "Limpando logs de eventos" -Completed
    Write-Host "   ✔ Todos os logs foram limpos." -ForegroundColor Green
} catch {
    Write-Host "   ✖ Erro ao limpar logs: $($_.Exception.Message)" -ForegroundColor Red
}
Start-Sleep -Milliseconds 500

#endregion

#region ---------- FINALIZAÇÃO ----------

Write-Host "`n"
Write-FadeText -Text "✅ Limpeza concluída com sucesso!" -Delay 40 -StartColor DarkGreen -EndColor Green
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

#endregion
