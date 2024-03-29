####### Read Me ######
# This PowerShell script connects to the MME via Microsoft Graph to retrieve and analyze user license information. 
# It identifies users with specific licenses, checks account statuses, and reports on disabled licensed users. 
# Results are displayed in the terminal and exported to CSV for further analysis or visualization. 
# The reading and reporting have been tested, however, user # license management it self HAS NOT BEEN TESTED.
# As of 3/15/2024 only interacts with accounts not groups
####### Read Me ######
####### If applicable install nesecary requirements (Windows)
#winget install --id Microsoft.Powershell --source winget
#Install-Module -Name Microsoft.Graph -Scope CurrentUser -AllowClobber -Force
####### Connect to Azure via Microsoft Graph with Gov hook. Look for the interactive log on a pop up screen. 
Connect-MgGraph -Environment USGov -Scopes "Directory.Read.All,Auditlog.Read.All"
####### Retrieve all user accounts with properties/details. 
$users = Get-MgUser -All -Property "Id,UserPrincipalName,Department,AccountEnabled"
####### Add and save lists to hold the user details/properties.
$allUsersDetails = @()
####### Initialize counters to enable looping.why the @ 
$totalUserAccounts = $users.Count
$totalLicensedUsers = 0
$totalM365E5Users = 0
$totalVisioUsers = 0
$totalEMSPremiumUsers = 0
$totalLicensedAndDisabledUsers = 0
######## Looping through each user to check for licenses and if they are disabled
foreach ($user in $users) {
    # Capture license details for each user
    $licenses = Get-MgUserLicenseDetail -UserId $user.Id
    ####### Determine if the user is disabled or not
    $isUserDisabled = -not $user.AccountEnabled
    ####### Check for each license type and add user details to the list with LicenseType In order of Visio, MSFT 365, and Mobil. 
    foreach ($license in $licenses) {
        $hasLicense = $false
        $licenseType = ""
        if ($license.SkuPartNumber -eq 'VISIOCLIENT_USGOV_GCCHIGH') {
            $licenseType = "Visio"
            $totalVisioUsers++
            $hasLicense = $true
        }
        elseif ($license.SkuPartNumber -eq 'SPE_E5_USGOV_GCCHIGH') {
            $licenseType = "Microsoft 365 E5 - GCCHIGH"
            $totalM365E5Users++
            $hasLicense = $true
        }
        elseif ($license.SkuPartNumber -eq 'EMSPREMIUM_USGOV_GCCHIGH') {
            $licenseType = "EMSPREMIUM"
            $totalEMSPremiumUsers++
            $hasLicense = $true
        }
        if ($hasLicense) {
            $totalLicensedUsers++
            if ($isUserDisabled) {
                $totalLicensedAndDisabledUsers++
            }
            $allUsersDetails += [PSCustomObject]@{
                UserPrincipalName = $user.UserPrincipalName
                Department        = $user.Department
                LicenseType       = $licenseType
                DisabledUser      = if ($isUserDisabled) { "Yes" } else { "No" }
            }
        }
    }
}
######## Display snapshot of license numbers including disabled licensed users
######## This includes school and obfusctaed accounts. 
Write-Output "MME Current User Accounts: $totalUserAccounts"
######## All users holding a license.
Write-Output "Current MME Licensed users: $totalLicensedUsers"
Write-Output "Current Microsoft 365 E5 - GCCHIGH users: $totalM365E5Users"
Write-Output "Current Visio Users: $totalVisioUsers"
Write-Output "Current EMSPREMIUM (Mobility) Users: $totalEMSPremiumUsers"
######## This users are potentials for license removal, probably the most value added portion here OMHO. 
Write-Output "Current Licensed and Disabled Users: $totalLicensedAndDisabledUsers"
######## Display combined list in a table format in the terminal and sorted by LicenseType. 
$allUsersDetails | Sort-Object LicenseType | Format-Table -Property UserPrincipalName, Department, LicenseType, DisabledUser -AutoSize
######## Export combined list to CSV for potential PowerBI requirements. Also can be sorted to summarized disabled 
#licensed users. <--MUST USE RELEVANT PATH TO YOUR SYSTEM. 
#Way ahead, add error handling to advice if wrong path is used
$allUsersDetails | Export-Csv -Path "C:\Users\edwar\OneDrive\Desktop\LicensedUsersAudit.csv" -NoTypeInformation
######## End tested Script##############
######################################################
######## NOT TESTED ############## NOT TESTED ########
######################################################
######## UNDER DEVELOPMENT TO Remove licenses from disabled users
######## Need to add Error handling...
# foreach ($userDetail in $allUsersDetails) {
#     if ($userDetail.DisabledUser -eq "Yes") {
#         # Define the licenses to remove with the appropriate SkuId of the license.
#         $licensesToRemove = @{"removeLicenses" = @("should we remove some or all?")}
        
#         # Remove the license from the disabled user
#         Set-MgUserLicense -UserId $userDetail.UserPrincipalName -BodyParameter $licensesToRemove 
#         Write-Output "License removed from disabled user: $($userDetail.UserPrincipalName)"
#     }
# }
######################################################
######## NOT TESTED ############## NOT TESTED ########
######################################################
