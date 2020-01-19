Write-Output "login to Azure"

Get-ChildItem Env: | Sort Name

$Credential = Get-Credential

$Credential | Get-Member

Connect-AzureRmAccount -?