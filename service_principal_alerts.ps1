<#
Data: June, 2025
Developer: @adejonghm
Environment: Windows 11

Description:
This script checks the expiration date of Azure Service Principal credentials
and sends notifications to a Microsoft Teams channel via a webhook URL. To use
this script it is mandatory to install the AzureRM Powershell module.

To install this module you could use this command.:
  
  Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
  
---
Official documentation: https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows
#>


# VARIABLES
$currentDate = Get-Date
$expirationThreshold = $currentDate.AddDays(30)

# MICROSOFT TEAMS WEBHOOK URL
$webhookUrl = ""

# AZURE LOGIN
$accountContext = Get-AzContext
if ($null -eq $accountContext) {
  $sub = Read-Host -Prompt "What subscription do you want to use?"
  Connect-AzAccount -Subscription $sub | Out-Null
}

$appRegistrationList = Get-AzADApplication
foreach ($spn in $appRegistrationList) {
  $credentials = $spn.PasswordCredentials
  if ($credentials.Length -ge 1) {
    foreach ($credential in $credentials) {
      $expirationDate = $credential.EndDateTime
      $daysLeft = ($expirationDate - $currentDate).Days

      # DEFINE THE ALERT LEVEL
      if ($daysLeft -le 7) {
        $level = "CRITICAL"
        $color = "FF0000"
      }
      elseif ($daysLeft -le 15) {
        $level = "HIGH"
        $color = "FFA500"
      }
      else {
        $level = "MODERATE"
        $color = "FFFF00"
      }

      if (($expirationDate -ge $currentDate) -and ($expirationDate -le $expirationThreshold)) {
        
        # SEND ALERT TO MICROSOFT TEAMS
        $message = @{
          "@type"    = "MessageCard"
          "@context" = "http://schema.org/extensions"
          summary    = "Secret Expiration Alert"
          themeColor = $color
          title      = "[Alert: $level] Secret expires in $daysLeft days"
          text       = "**Alert date:** $($currentDate.ToShortDateString())`n`n**Display Name:** $($spn.DisplayName)`n`n**Client ID:** $($spn.AppId)`n`n**Expire in:** $($expirationDate.ToShortDateString())"
        }

        $body = ConvertTo-Json -Depth 3 -InputObject $message
        try {
          $null = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType 'application/json'
        }
        catch {
          Write-Host "Error sending the message: $($_.Exception.Message)"
        }
      }
    }	
  }
}
Write-Host "Alerts sent successfully!"