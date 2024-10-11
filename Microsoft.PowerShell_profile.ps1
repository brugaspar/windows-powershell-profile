function goto-profile {
  Set-Location "C:/Users/Bruno/Documents/WindowsPowerShell"
}

function goto-projects {
  Set-Location "D:/Projetos"
}

function goto-senha-group {
  Set-Location "D:/Projetos/senha-info/senha-erp-group"
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
