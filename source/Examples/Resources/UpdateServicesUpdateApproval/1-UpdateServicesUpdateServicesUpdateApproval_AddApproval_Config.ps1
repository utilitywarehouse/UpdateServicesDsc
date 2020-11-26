<#PSScriptInfo
.VERSION 1.0.0
.GUID 5071565e-dd47-48fe-9d59-16bad187b7a0
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/UpdateServicesDsc/blob/master/LICENSE
.PROJECTURI https://github.com/dsccommunity/UpdateServicesDsc
.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png
.RELEASENOTES
Updated author, copyright notice, and URLs.
#>

#Requires -Module UpdateServicesDsc

<#
    .DESCRIPTION
        This configuration will create two Update Approval Rules
        (a Parent and a Child)
#>
Configuration UpdateServicesUpdateServicesUpdateApproval_AddApproval_Config
{
    param
    (
    )

    Import-DscResource -ModuleName UpdateServicesDsc

    node localhost
    {
        UpdateServicesUpdateApproval 'UpdateServicesUpdateApproval_KB12345678_AllComputers'
        {
            UpdateId = '5d5c4e52-4c94-4a47-895b-0f00c71d1787'
            RevisionNumber = 201
            ComputerTargetGroupName = 'All Computers'
            Ensure = 'Present'
            Action = 'Install'
        }

        UpdateServicesUpdateApproval 'UpdateServicesUpdateApproval_KB12345678_Servers'
        {
            UpdateId = '5d5c4e52-4c94-4a47-895b-0f00c71d1787'
            RevisionNumber = 201
            ComputerTargetGroupName = 'Servers'
            Ensure = 'Present'
            Action = 'NotApproved'
        }
    }
}
