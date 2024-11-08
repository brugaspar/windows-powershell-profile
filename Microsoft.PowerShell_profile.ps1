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

    Write-Output "Variáveis de ambiente carregadas de $envFilePath"
  }
  else {
    Write-Output "Arquivo .env não encontrado: $envFilePath"
  }
}

load-env-file

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
