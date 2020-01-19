Write-Output "login to Azure"

Get-ChildItem Env: | Sort-Object Name

$password = $env:servicePrincipalKey | ConvertTo-SecureString -asPlainText -Force

$credential = New-Object -TypeName System.Management.Automation.PSCredential($env:servicePrincipalId,$password)  -ErrorAction Stop

$Credential | Get-Member

Connect-AzureRmAccount -Credential $Credential -TenantId $env:tenantId -ServicePrincipal