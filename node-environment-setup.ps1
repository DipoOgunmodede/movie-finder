#make sure correct version number is set
$requiredVersion= "18.4.0"


Write-Host  "Required Node.js Version: $requiredVersion"

$nodeVersions = (nvm list) | Out-String

$nodeVersionsArray = $nodeVersions.split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)

Write-Host "node versions installed:"

foreach ($version in $nodeVersionsArray) {
    Write-Host "version:  $version "
    
    $index = $version.indexOf("*")

    if($requiredVersion -eq $version.Trim()){
        #already installed, switch to it
        cmd.exe /c "nvm use $requiredVersion"
        exit
    }
    elseif($index -ne -1)
    {
      #parse the current version in use
      $lastIndex = $version.Trim().indexOf("(")
      $parsedVersion = $version.Trim().Substring($index, $lastIndex - 2).Trim()
      Write-Host "current version:$parsedVersion"

      if($parsedVersion -eq $requiredVersion){
          Write-Host "required version is installed and in use"
          exit
      }
    }

}


if($parsedVersion -ne  $requiredVersion){

    cmd.exe /c "nvm install $requiredVersion"

    cmd.exe /c "nvm use $requiredVersion"

    start-process powershell 'cmd.exe /k "npm install --global gulp-cli && exit"'
    exit
}