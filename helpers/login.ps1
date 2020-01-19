Write-Output "login to Azure"

Get-ChildItem Env: | Sort-Object Name

$password = $env:servicePrincipalKey | ConvertTo-SecureString -asPlainText -Force

$credential = New-Object -TypeName System.Management.Automation.PSCredential($env:servicePrincipalId,$password)  -ErrorAction Stop

Write-Output "Credential created, installing Azure RM"


Install-Module AzureRM -Force -AllowClobber #-Verbose
Import-Module AzureRM

Write-Output "Installed Azure RM, logging in"

Login-AzureRmAccount -Credential $Credential -TenantId $env:tenantId -ServicePrincipal

Write-Output "Logged In"
