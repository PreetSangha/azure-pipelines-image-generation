Write-Output "login to Azure"

Get-ChildItem Env: | Sort-Object Name

$Credential = Get-AutomationPSCredential -Name $env:USERNAME

$Credential | Get-Member

Connect-AzureRmAccount -Credential $Credential -TenantId $env:tenantId -ServicePrincipal