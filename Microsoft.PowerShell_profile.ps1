function load-env-file {
  param (
    [string]$envFilePath = "$PSScriptRoot\.env"
  )

  if (Test-Path -Path $envFilePath) {
    Get-Content $envFilePath | ForEach-Object {
      # Ignora linhas em branco e comentários
      if ($_ -match '^\s*$' -or $_ -match '^\s*#') { return }

      # Divide a linha na chave e valor
      $parts = $_ -split '=', 2
      if ($parts.Length -eq 2) {
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
      }
    }
  }
  else {
    Write-Output "Environment file '.env' not found: $envFilePath"
  }
}

load-env-file

function upload-ftp {
  param (
    [Parameter(Mandatory=$false)]
    [Alias("H")]
    [string]$ftphost = "senha.zapto.org:50000",
    [Parameter(Mandatory=$false)]
    [Alias("F")]
    [string]$currentFolder
  )

  $continue = Read-Host "`nCurrent host: $ftphost. Do you want to continue? (y/n)"
  Write-Host ""

  if ($continue -ne "y") {
    return
  }

  $path = (Get-Item -Path ".\").FullName
  $folder = (Get-Item -Path ".\").Name

  if ($currentFolder) {
    $folder = $currentFolder
  }

  $date = Get-Date -Format "yyMMdd-HHmm"
  $filename = "$folder-$date.zip"

  $ftp_server = "ftp://$ftphost/Update/API/"
  $ftp_username = $env:FTP_USERNAME
  $ftp_password = $env:FTP_PASSWORD

  echo "Uploading files to $ftp_server, filename: $filename"
  return

  $destination_path = "$path/$filename"

  $ignore_items = @()

  if (Test-Path -Path "$path\.gitignore") {
    $ignore_items = Get-Content -Path "$path\.gitignore"
    $ignore_items = $ignore_items -replace "/", ""
  }

  $items = Get-ChildItem -Path $path -Exclude $ignore_items | Select-Object -ExpandProperty FullName

  $compress = @{
    Path = $items
    CompressionLevel = "Fastest"
    DestinationPath = $destination_path
  }

  Compress-Archive @compress

  # Renomear arquivos existentes no servidor FTP
  try {
    $request = [System.Net.FtpWebRequest]::Create("$ftp_server")
    $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
    $request.Credentials = New-Object System.Net.NetworkCredential($ftp_username, $ftp_password)

    $response = $request.GetResponse()
    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    $files = $reader.ReadToEnd().Split("`n") -replace "`r", ""
    $reader.Close()
    $response.Close()

    foreach ($file in $files) {
      if ($file -match "^$folder-\d{6}-\d{4}\.zip$") {
        $oldName = "$ftp_server$file"
        $newName = "$ftp_serverxxx-$file"

        $renameRequest = [System.Net.FtpWebRequest]::Create($oldName)
        $renameRequest.Method = [System.Net.WebRequestMethods+Ftp]::Rename
        $renameRequest.Credentials = New-Object System.Net.NetworkCredential($ftp_username, $ftp_password)
        $renameRequest.RenameTo = "bkp-$file"

        $renameResponse = $renameRequest.GetResponse()
        $renameResponse.Close()
      }
    }
  } catch {
    Write-Host "`nError renaming files on FTP server: $($_.Exception.Message)`n" -ForegroundColor Red
  }

  # Fazer o upload do novo arquivo
  $client = New-Object System.Net.WebClient
  $client.Credentials = New-Object System.Net.NetworkCredential($ftp_username, $ftp_password)

  try {
    $client.UploadFile("$ftp_server$filename", $destination_path)
  } catch {
    Write-Host "`nError on FTP request, try again.`n"
    Write-Host "$($_.Exception.Message)`n" -ForegroundColor Red
  } finally {
    $client.Dispose()
  }

  Remove-Item -Path $destination_path
}

function goto-profile {
  Set-Location "C:/Users/Bruno/Documents/WindowsPowerShell"
}

function goto-projects {
  Set-Location "D:/Projetos"
}

function goto-senhag {
  Set-Location "D:/Projetos/senha-info/senha-erp-group"
}

function dotini {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$false)]
    [Alias("F")]
    [string]$FileDestination
  )

  $Destination = "SenhaERP/senha.ini"

  if ($FileDestination) {
    $Destination = $FileDestination
  }

  notepad.exe "D:/Projetos/senha-info/senha-erp-group/$Destination"
}

function fb-restore {
  $origin = $args[0]
  $destination = $args[1]

  $currlocation = Get-Location
  $fblocation = "C:\Program Files\Firebird\Firebird_2_5\bin"

  if (!$origin) {
    Write-Host "Error: origin file is not set, please provide a valid file path" -ForegroundColor Red
    return
  }

  if (!$destination) {
    $destination = "SENHA.GDB"
  }

  try {
    Set-Location $fblocation
    ./gbak.exe -c -user SYSDBA -password $env:FIREBIRD_PASSWORD $currlocation\$origin $currlocation\$destination
  } finally {
    Set-Location $currlocation
  }
}

function glog {
  $git_log = git log --oneline

  if ($git_log) {
    "`n"; git log --oneline; "`n"
  }
}

function gclone {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Repository,
    [Parameter(Mandatory=$false, Position=1)]
    [string]$Rename,
    [Parameter(Mandatory=$false)]
    [Alias("O")]
    [string]$Organization
  )

  if ($Organization) {
    $Repository = "$Organization/$Repository"
  } else {
    $Repository = "brugaspar/$Repository"
  }

  git clone https://github.com/"$Repository".git $Rename
}

function gstatus {
  $git_status = git status -s

  if ($git_status) {
    "`n"; git status -s; "`n"
  }
}

function prompt {
  $git_branch = git rev-parse --abbrev-ref HEAD
  $path = Split-Path -leaf -path (Get-Location)

  Write-Host ">  " -Foreground "green" -NoNewLine
  Write-Host "$env:username".toLower() -Foreground "red" -NoNewLine
  Write-Host " on " -Foreground "green" -NoNewLine
  Write-Host "$path" -Foreground "cyan" -NoNewLine

  if($git_branch) {
    if($git_branch -eq "HEAD") {
      $git_commit = git log --pretty=format:'%h' -n 1
      $git_default_branch = git config init.defaultbranch
      $git_log = git log

      if(!$git_log) {
        Write-Host " ($git_default_branch)" -Foreground "red" -NoNewLine
      } else {
        Write-Host " (($git_commit...))" -Foreground "blue" -NoNewLine
      }
    } else {
      Write-Host " ($git_branch)" -Foreground "blue" -NoNewLine
    }
  }

  Write-Host ":" -Foreground "cyan" -NoNewLine

  return " "
}
