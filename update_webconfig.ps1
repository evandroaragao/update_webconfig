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
$LogFile = "Update_WebConfig_LogFile_" + [string]$Today.Year + "-" + $Today.Month + "-" + $Today.Day + "_" + $Today.Hour + "-" + $Today.Minute + "-" + $Today.Second +".txt"
$LogPathExists = Test-Path "C:\Update_WebConfig\Logs"
If ($LogPathExists -eq "True") {
    Start-Transcript "C:\Update_WebConfig\Logs\$LogFile"
    } Else {
    New-Item -ItemType "directory" -Path "C:\Update_WebConfig\Logs"
    Start-Transcript "C:\Update_WebConfig\Logs\$LogFile"
}

Get-DateLogInfo
Write-Host "Iniciando a execucao do script de UPDATE dos arquivos webconfig"
Write-Host ""

#Funcao para popular a HashTable com os valores do arquivo CSV.
$CSVFile='.\DbServersList.csv'
function ConvertCsvToHashTable($CSVFile){
$CSV=import-csv $CSVFile -header ("Old_DbServer","New_DbServer") -Delimiter ";"
$Headers=$CSV[0].psobject.properties.name
$Key=$Headers[0]
$Value=$Headers[1]
$HashTable = @{}
$CSV | % {$HashTable[$_.Old_DbServer] = $_.New_DbServer}
return $HashTable
}

#Busca os arquivos web.config no path mencionado e exporta o caminho deles para o arquivo .\webconfig_files.txt
Get-DateLogInfo
Write-Host "Inventariando arquivos web.config" -ForegroundColor Green
$App_Files = ""
$Webconfig_files = "C:\Update_WebConfig\webconfig_files.txt"
if (Test-Path $Webconfig_files) {
  Remove-Item $Webconfig_files
}

#Procura os arquivos WebConfig dentro do path $Main_Path
$App_Files = (Get-ChildItem -Path $Main_Path -filter web.config -Recurse -ErrorAction SilentlyContinue -Force | %{$_.FullName})

#ForEach para popular o arquivo $Webconfig_file com o caminho dos arquivos Webconfig.
ForEach ($Item in $App_Files) {
    Add-Content $Webconfig_files $Item
    Get-DateLogInfo

    #Faz um backup do arquivo Webconfig no mesmo diretorio do original
    Write-Host "Fazendo backup do arquivo" $Item
    Copy-Item -Path $Item -Destination "$Item-script.bak"

    #Define os valores da HashTable
    $HashTable = ConvertCsvToHashTable $CSVFile

    <# Pega o conteudo do arquivo web.config e procura pelos nomes dos antigos bancos de dados 
    e os substituem pelos respectivos nomes dos novos bancos de dados a partir dos valores
    contidos na HashTable
    #>
    $WebConfig_File = Get-Content $Item
    foreach ($e in $HashTable.keys) {
        $WebConfig_File = $WebConfig_File -replace $e, $HashTable[$e]
    }
    #Substitui o arquivo web.config com o conteudo alterado.
    Set-Content -Path $Item -Value $WebConfig_File
}

Write-Host "Fim da execucao do script." -ForegroundColor Cyan
Write-Host "Em caso de problemas, consulte o arquivo de log" -ForegroundColor Yellow

#####################
# Fim do Transcript #
#####################
Stop-Transcript