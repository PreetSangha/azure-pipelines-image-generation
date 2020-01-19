$bigBangSub = '70e79a08-a3f2-4656-9b89-1d263835ba25';

$imageRoot = "ImageGenerationRepositoryRoot"

#$preetMpnSub = "c0c577e0-1dee-42d3-bf3c-c3124f7a948c";
$resourceGroup = "preet-test-rg" ;
$imageType = 1;
$location = "australiaeast";
$SecondsToWaitForServicePrincipalSetup = 1;
$SubscriptionId = $bigBangSub

Write-Output "Installing Azure RM"
Install-Module AzureRM -Force -AllowClobber #-Verbose
Import-Module AzureRM

" ---- "
Get-ChildItem Env: | Sort-Object Name
" ---- "

Write-Output "Create Service Credential"
$password = $env:servicePrincipalKey | ConvertTo-SecureString -asPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential($env:servicePrincipalId,$password)  -ErrorAction Stop

Write-Output "Logging in"
Login-AzureRmAccount -Credential $Credential -TenantId $env:tenantId -ServicePrincipal

Write-Output "Setting Subscription"
Set-AzureRmContext -SubscriptionId $SubscriptionId

Write-Output "Getting Service Principal"
$sp = Get-AzureRmADServicePrincipal -ServicePrincipalName $env:servicePrincipalId
$spAppId = $sp.ApplicationI
$spClientId = $sp.ApplicationId
$spObjectId = $sp.Id
Write-Output "Service Principal: " $spAppId $spClientId $spObjectId
