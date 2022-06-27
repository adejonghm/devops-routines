<#
    Author: Alejandro de Jongh 
    Envmnt: Windows 10
    
    Note:   You must create the environment variable called PASSWDST to store your password,
            that way it is not exposed in the code.
#>


## Read URL where the log is stored.
$source = Read-Host -Prompt "Enter the log URL: "

## Create the folder to store the log.
$path = New-Item -Path "$env:APPDATA" -Name "Logs" -itemType "Directory" -Force
$destination = "$path\dblog.log"

## Define username and password to access the log on the web.
$username = $env:USERNAME
$password = $env:PASSWDST

## Convert to secure String.
$secPassword = ConvertTo-SecureString $password -AsPlainText -Force

## Create the Object credentials.
$credObject = New-Object System.Management.Automation.PSCredential ($username, $secPassword)

## Download the file.
Invoke-WebRequest -Uri $source -OutFile $destination -Credential $credObject

## Check the number of cursors in the log.
$notification = New-Object -ComObject Wscript.Shell
if (Select-String -Path $destination -Pattern "de cursores abertos excedido" -SimpleMatch -Quiet) {
    $notification.Popup("The maximum number of open cursors is exceeded.", 0, "Warning, Self Healing", 64 + 4096)
    Clear-Host
}
