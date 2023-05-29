<#
.SYNOPSIS
ARM template deployments
.DESCRIPTION
This scriptis a collection of ARM template deployment requirement.
.NOTES
https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/best-practices
Limitations:
    256 parameters
    256 variables
    800 resources (including copy count)
    64 output values
    10 unique locations per subscription/tenant/management group scope
    24,576 characters in a template expression
    4MB size file

#>
#variables
$NewResourceName = Read-Host -Prompt "Enter a name for the new resource"

#set-execution policy
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

#variables
Write-Progress "Setting variables" -Status "Please wait..."
    $name = $NewResourceName
    $location = 'Australia East'
    $rgName = $name + "-RG"
        #create random string for storage account name
        function New-RandomString {
            $characters = "abcdefghijklmnopqrstuvwxyz0123456789"
            $random = Get-Random -Minimum 0 -Maximum ($characters.Length - 1)
            $randomString = ""
        
            for ($i = 0; $i -lt 5; $i++) {
                $randomString += $characters[$random]
                $random = Get-Random -Minimum 0 -Maximum ($characters.Length - 1)
            }
        
            return $randomString
        }
        $randomString = New-RandomString
    $stgName = $name.ToLower() + "stg" + $randomString

    #connect Az
    Write-Progress "Checking if Az module is installed" -Status "Please wait..."
    if (Get-AzSubscription -SubscriptionName 'Azure subscription 1' -ErrorAction SilentlyContinue) {
        Write-Progress "Confirmed connected to Azure" -Status "proceeding..."
    } else {
        Write-Progress -Activity "Connecting to Azure" -Status "Please wait..."
        Connect-AzAccount
    }
    $Azcontext = Set-AzContext -Subscription 'Azure subscription 1'
    
#Create resource group
    #check if resource group exists, else create it
    Write-Progress "Checking if Resource Group exists" -Status "Please wait..."
    if (Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue) {
        Write-Progress "Resource Group exists" -Status "proceeding..."
    } else {
        Write-Progress -Activity "Creating Resource Group" -Status "Please wait..."
        $rg = New-AzResourceGroup -Name $rgName -Location $location
        Write-Host "New Resource Group: $rgName" -f Green
    }

#Deploy ARM template
$tf = "C:\Temp\Training\Ex_Files_MS_Azure_Design_and_Deploy_ARM_Templates\Ex_Files_MS_Azure_Design_and_Deploy_ARM_Templates\Exercise Files\MyScripts\ARMTemplates\LinkedTemplate.json"
$params = @{
    stgName = $stgName
}
New-AzResourceGroupDeployment -Name $stgName -ResourceGroupName $rgName -TemplateFile $tf -TemplateParameterObject $params



#list az resources in resource group
Write-Progress -Activity "Listing resources in Resource Group" -Status "Please wait..."
Get-AzResource -ResourceGroupName $rgName | Select-Object Name,ResourceType,Location

#CleanUp
$rgName = "ARM-RG"
$cleanUpJob = Start-Job -ScriptBlock {
    param(
        $rgName
    )
    Write-Progress -Activity "Cleaning Up" -Status "Please wait..."
    Write-Host "Removing Resource Group: $rgName" -f Green

    try {
        Remove-AzResourceGroup -Name $rgName -Force
        $results =[string]"$rgName Resource group removed Successfully!"
    } catch {
        throw
        $results =[string]"$vmName Resource group removal failed!" 
    }
    Write-Host $results
    
    #Check if burnToast module is installed
    $time = Get-Date
    if (!(Get-Module -Name BurntToast)) { Install-Module -Name BurntToast -Scope CurrentUser }
    $notificationTitle = "$($rgName): Resource group removal Job Completed $time"
    $notificationMessage = $results
    $toastHeader = New-BTHeader -Title $notificationTitle
    New-BurntToastNotification -Text $notificationMessage -Sound 'Default' -Header $toastHeader

    
} -Name "CleanUp" -ArgumentList $rgName