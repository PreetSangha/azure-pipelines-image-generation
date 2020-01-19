Install-Module AzureRM -Force -AllowClobber #-Verbose
Import-Module AzureRM


$ErrorActionPreference = 'Stop'

enum ImageType {
    VS2017 = 0
    VS2019 = 1
    Ubuntu1604 = 2
    WinCon = 3
}

Function Get-PackerTemplatePath {
    param (
        [Parameter(Mandatory = $True)]
        [string] $RepositoryRoot,
        [Parameter(Mandatory = $True)]
        [ImageType] $ImageType
    )

    $relativePath = "N/A"

    switch ($ImageType) {
        ([ImageType]::VS2017) {
            $relativePath = "\images\win\vs2017-Server2016-Azure.json"
        }
        ([ImageType]::VS2019) {
            $relativePath = "\images\win\vs2019-Server2019-Azure.json"
        }
        ([ImageType]::Ubuntu1604) {
            $relativePath = "\images\linux\ubuntu1604.json"
        }
        ([ImageType]::WinCon) {
            $relativePath = "\images\win\WindowsContainer1803-Azure.json"
        }
    }

    return $RepositoryRoot + $relativePath;
}

Function GenerateResourcesAndImage {
    <#
        .SYNOPSIS
            A helper function to help generate an image.

        .DESCRIPTION
            Creates Azure resources and kicks off a packer image generation for the selected image type.

        .PARAMETER SubscriptionId
            The Azure subscription Id where resources will be created.

        .PARAMETER ResourceGroupName
            The Azure resource group name where the Azure resources will be created.

        .PARAMETER ImageGenerationRepositoryRoot
            The root path of the image generation repository source.

        .PARAMETER ImageType
            The type of the image being generated. Valid options are: {"VS2017", "VS2019", "Ubuntu164", "WinCon"}.

        .PARAMETER AzureLocation
            The location of the resources being created in Azure. For example "East US".

        .PARAMETER Force
            Delete the resource group if it exists without user confirmation.

        .EXAMPLE
            GenerateResourcesAndImage -SubscriptionId {YourSubscriptionId} -ResourceGroupName "shsamytest1" -ImageGenerationRepositoryRoot "C:\azure-pipelines-image-generation" -ImageType Ubuntu1604 -AzureLocation "East US"
    #>
    param (
        [Parameter(Mandatory = $True)]
        [string] $SubscriptionId,
        [Parameter(Mandatory = $True)]
        [string] $ResourceGroupName,
        [Parameter(Mandatory = $True)]
        [string] $ImageGenerationRepositoryRoot,
        [Parameter(Mandatory = $True)]
        [ImageType] $ImageType,
        [Parameter(Mandatory = $True)]
        [string] $AzureLocation,
        [Parameter(Mandatory = $True)]
        [int] $SecondsToWaitForServicePrincipalSetup,
        [Parameter(Mandatory = $True)]
        [Switch] $Force
    )

    $builderScriptPath = Get-PackerTemplatePath -RepositoryRoot $ImageGenerationRepositoryRoot -ImageType $ImageType
    $ServicePrincipalClientSecret = $env:servicePrincipalKey;
   
    Write-Output "", "Creating Service Credential"
    $password = $env:servicePrincipalKey | ConvertTo-SecureString -asPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential($env:servicePrincipalId,$password)  -ErrorAction Stop
    $InstallPassword = $env:UserName + [System.GUID]::NewGuid().ToString().ToUpper();
    
    Write-Output "Logging in"
    Login-AzureRmAccount -Credential $Credential -TenantId $env:tenantId -ServicePrincipal

    Write-Output "Setting Subscription"
    Set-AzureRmContext -SubscriptionId $SubscriptionId

    # $alreadyExists = $true;
    # try {
    #     Get-AzureRmResourceGroup -Name $ResourceGroupName
    # }
    # catch {
    #     $alreadyExists = $false;
    # }

    # if ($alreadyExists) {
    #     if($Force -eq $true) {

    #         Write-Output "Cleanup existing resource group $ResourceGroupName if it already exitsted before"
    #         Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force
    #     }
    # }

    # Write-Output "", "Creating resource group $ResourceGroupName"
    # New-AzureRmResourceGroup -Name $ResourceGroupName -Location $AzureLocation

    # This script should follow the recommended naming conventions for azure resources
    $storageAccountName = if($ResourceGroupName.EndsWith("-rg")) {
        $ResourceGroupName.Substring(0, $ResourceGroupName.Length -3)
    } else { $ResourceGroupName }

    # Resource group names may contain special characters, that are not allowed in the storage account name
    $storageAccountName = $storageAccountName.Replace("-", "").Replace("_", "").Replace("(", "").Replace(")", "").ToLower()
    $storageAccountName += "001"

    # Write-Output "", "Creating Storage Account $storageAccountName"
    # New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $storageAccountName -Location $AzureLocation -SkuName "Standard_LRS"

    Write-Output "", "Getting Service Principal"
    $sp = Get-AzureRmADServicePrincipal -ServicePrincipalName $env:servicePrincipalId
    #$spAppId = $sp.ApplicationId
    $spClientId = $sp.ApplicationId
    $spObjectId = $sp.Id
    Write-Output "Got Service Principal: $sp.DisplayName $spAppIdd $spClientId $spObjectId"

    Start-Sleep -Seconds $SecondsToWaitForServicePrincipalSetup

    # Write-Output "", "Adding Contributor Role to Service Principal"
    # New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $spAppId

    Start-Sleep -Seconds $SecondsToWaitForServicePrincipalSetup

    Write-Output "", "Gettting tenant id"
    $tenantId = $env:tenantId

" ---- "
Get-ChildItem Env: | Sort-Object Name
" ---- "

    Write-Output "", "Note this variable-setting script for running Packer with these Azure resources in the future:", "==============================================================================================", "`$spClientId = `"$spClientId`"", "`$ServicePrincipalClientSecret = `"$ServicePrincipalClientSecret`"", "`$SubscriptionId = `"$SubscriptionId`"", "`$tenantId = `"$tenantId`"", "`$spObjectId = `"$spObjectId`"", "`$AzureLocation = `"$AzureLocation`"", "`$ResourceGroupName = `"$ResourceGroupName`"", "`$storageAccountName = `"$storageAccountName`"", "`$install_password = `"$install_password`"", ""

    packer.exe build -on-error=ask `
        -var "client_id=$($spClientId)"  `
        -var "client_secret=$($ServicePrincipalClientSecret)"  `
        -var "subscription_id=$($SubscriptionId)"  `
        -var "tenant_id=$($tenantId)"  `
        -var "object_id=$($spObjectId)"  `
        -var "location=$($AzureLocation)"  `
        -var "resource_group=$($ResourceGroupName)"  `
        -var "storage_account=$($storageAccountName)"  `
        -var "install_password=$($InstallPassword)"  `
        $builderScriptPath
}


$bigBangSub = '70e79a08-a3f2-4656-9b89-1d263835ba25';

$imageRoot = $env:BUILD_SOURCESDIRECTORY

#$preetMpnSub = "c0c577e0-1dee-42d3-bf3c-c3124f7a948c";
$resourceGroup = "preet-test-rg" ;
$imageType = 1;
$location = "australiaeast";
$SecondsToWaitForServicePrincipalSetup = 1;



$mySubscription = $bigBangSub

Write-Output "Started on sub $mySubscription"


Write-Output $mySubscription.GetType().FullName

GenerateResourcesAndImage  -Force `
    -SubscriptionId $mySubscription `
    -ResourceGroupName $resourceGroup `
    -ImageGenerationRepositoryRoot $imageRoot `
    -ImageType $imageType `
    -AzureLocation $location `
    -SecondsToWaitForServicePrincipalSetup 30

Write-Output "Finished";