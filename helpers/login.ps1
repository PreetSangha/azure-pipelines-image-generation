Write-Output "login to Azure"

Get-ChildItem Env: | Sort-Object Name

$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:servicePrincipalId,$env:servicePrincipalKey  -ErrorAction Stop

$Credential | Get-Member

Connect-AzureRmAccount -Credential $Credential -TenantId $env:tenantId -ServicePrincipal