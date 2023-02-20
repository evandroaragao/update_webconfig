###################################
# Parametro de path da aplicacao  #
###################################
# Informar o path principal onde estao as aplicacoes
param ([Parameter(Mandatory)]$Main_Path)

#Funcao para imprimir na tela a data e hora da execução dos comandos.
function Get-DateLogInfo {
    $Today = Get-Date
    $LogTimeInfo = [string] $Today.Year + "-" + $Today.Month + "-" + $Today.Day + "_" + $Today.Hour + "h-" + $Today.Minute  + "m-" + $Today.Second + "s"
    Write-Host "-- $LogTimeInfo --" -ForegroundColor Gray
}

#Montagem do arquivo de log e inicio do transcript
$Today = Get-Date
$LogFile = "Restore_WebConfig_LogFile_" + [string]$Today.Year + "-" + $Today.Month + "-" + $Today.Day + "_" + $Today.Hour + "-" + $Today.Minute + "-" + $Today.Second +".txt"
$LogPathExists = Test-Path "C:\Restore_WebConfig\Logs"
If ($LogPathExists -eq "True") {
    Start-Transcript "C:\Restore_WebConfig\Logs\$LogFile"
    } Else {
    New-Item -ItemType "directory" -Path "C:\Restore_WebConfig\Logs"
    Start-Transcript "C:\Restore_WebConfig\Logs\$LogFile"
}

Get-DateLogInfo
Write-Host "Iniciando a execucao do script de RESTORE dos arquivos webconfig"
Write-Host ""

#Busca os arquivos web.config-script.bak no path mencionado e exporta o caminho deles para o arquivo .\webconfig_files.txt
Get-DateLogInfo
Write-Host "Inventariando arquivos web.config-script.bak" -ForegroundColor Green
$App_Files = ""
$Webconfig_files = "C:\Restore_WebConfig\webconfig_files.txt"
if (Test-Path $Webconfig_files) {
  Remove-Item $Webconfig_files
}

#Procura os arquivos WebConfig dentro do path $Main_Path
$App_Files = (Get-ChildItem -Path $Main_Path -filter web.config -Recurse -ErrorAction SilentlyContinue -Force | %{$_.FullName})

#ForEach para popular o arquivo $Webconfig_file com o caminho dos arquivos Webconfig.
ForEach ($Item in $App_Files) {
    Add-Content $Webconfig_files $Item
    Get-DateLogInfo

    #Restaura o contaudo do arquivo de backup para o arquivo web.config original
    Write-Host "Restaurando o backup do arquivo" $Item
    $WebConfig_File = Get-Content "$Item-script.bak"
    Set-Content -Path $Item -Value $WebConfig_File
}

Write-Host "Fim da execucao do script." -ForegroundColor Cyan
Write-Host "Em caso de problemas, consulte o arquivo de log" -ForegroundColor Yellow

#####################
# Fim do Transcript #
#####################
Stop-Transcript