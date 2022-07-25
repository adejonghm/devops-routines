<#
    Author: Alejandro de Jongh
    Envmnt: Windows 10

#>


## Global parameters
$cdgPath = "$env:APPDATA\cdg"
$path = (Get-Location).Path
$stages = @('dev', 'pre', 'pro')

## Create a branch where the changes will be committed.
git checkout -b fix/cdg-bugfix

## Clone the necessary files.
$gitUrl = Read-Host -Prompt "Enter the url of the Git you want to clone: "
git clone $gitUrl $cdgPath

## Copy the cloned files to the local repository.
Copy-Item "$cdgPath\.ci" . -Recurse
Copy-Item "$cdgPath\OPENSHIFT" . -Recurse

## Get the APP_NAME by folder name.
$appName = ($path).Split('\')[-1]

foreach ($stg in $stages) {
    $fullPath = $path + '\OPENSHIFT\DEPLOYMENT_CONFIG\' + $stg + '\env.conf'
    $file = Get-Content $fullPath
    
    ## Change the APP_NAME in the file.
    $newFile = @("APP_NAME=$appname")
    for ($i = 1; $i -lt $file.Length; $i++) {
        $newFile += $file[$i]
    }
    
    ## Save the file.
    Remove-Item $fullPath
    $newFile | Out-File $fullPath -Append   
}

## Prepare the changes to add them to the repository.
git add .ci\* OPENSHIFT\*
git commit -m "add: pipeline config files"
git push origin -u fix/cdg-bugfix:fix/cdg-bugfix

## Delete the created branch.
git checkout develop
git branch -d fix/cdg-bugfix

## Delete cloned files.
Remove-Item $cdgPath -Recurse -Force
Remove-Item fixing_files.ps1 -Force

Write-Host "Process completed successfully!"
