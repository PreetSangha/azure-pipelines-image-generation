Write-Output "login to Azure"

Get-ChildItem Env: | Sort-Object Name

$credential = New-Object System.Management.Automation.PSCredential($env:servicePrincipalId, $env:servicePrincipalKey) -ErrorAction Stop

$Credential | Get-Member

Connect-AzureRmAccount -Credential $Credential -TenantId $env:tenantId -ServicePrincipal