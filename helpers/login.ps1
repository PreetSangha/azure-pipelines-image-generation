Write-Output "login to Azure"

Get-ChildItem Env: | Sort-Object Name

Install-Module AzureAutomationAuthoringToolkit -Scope CurrentUser -Force
$Credential = Get-AutomationPSCredential -Name $env:USERNAME

$Credential | Get-Member

Connect-AzureRmAccount -Credential $Credential -TenantId $env:tenantId -ServicePrincipal