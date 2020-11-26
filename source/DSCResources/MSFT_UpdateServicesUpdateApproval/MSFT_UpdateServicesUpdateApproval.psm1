# DSC resource to manage WSUS Approvals.

# Load Common Module
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
Import-Module -Name $script:resourceHelperModulePath
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US' -FileName 'MSFT_UpdateServicesUpdateApproval.strings.psd1'

# Defines the variable update approval values
$UpdateApprovalAction = @{
    Install = 0
    Uninstall = 1
    NotApproved = 3
}

<#
    .SYNOPSIS
        Retrieves the current state of the WSUS Computer Target Group.

        The returned object provides the following properties:
            Ensure: An enumerated value that describes if the WSUS Update Approval is Present or Absent.
            UpdateId: The Update ID GUID in string format.
            RevisionNumber: The Revision Number of Update which (in combination with UpdateId) uniquely identifies the update.
            ComputerTargetGroupName: The Name of the Computer Target Group on which to define the approval.
            Action: The Approval Action associated with the approval.
            Id: The ID of the Update Approval Object (if present).
    .PARAMETER Name
        The Name of the WSUS Computer Target Group.

    .PARAMETER Path
        The Path to the WSUS Compter Target Group in the format 'Parent/Child'.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $UpdateId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RevisionNumber,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ComputerTargetGroupName
    )

    try
    {
        $WsusServer = Get-WsusServer
        $Ensure = 'Absent'
        $Action = $null
        $Id = $null

        if ($null -ne $WsusServer)
        {
            Write-Verbose -Message ($script:localizedData.GetWsusServerSucceeded -f $WsusServer.Name)

            # confirm that the specified update exists
            try
            {
                $Update = Get-UpdateServicesUpdate -WSUSServer $WsusServer -UpdateId $UpdateId -RevisionNumber $RevisionNumber
                Write-Verbose -Message ($script:localizedData.UpdateFound -f $UpdateId, $RevisionNumber)
            }
            catch
            {
                New-InvalidOperationException -Message ($script:localizedData.UpdateNotFound -f $UpdateId, $RevisionNumber) -ErrorRecord $_
            }

            # confirm that the specified computer target group exists
            $ComputerTargetGroup = $WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq $ComputerTargetGroupName }

            if ($null -eq $ComputerTargetGroup)
            {
                New-InvalidOperationException -Message ($script:localizedData.NotFoundComputerTargetGroup -f $Name)
            }

            # retrieve any approvals associated with the update / computer target group
            $UpdateApproval = Get-UpdateServicesUpdateApproval -Update $Update -ComputerTargetGroup $ComputerTargetGroup

        }
        else
        {
            Write-Verbose -Message $script:localizedData.GetWsusServerFailed
        }
    }
    catch
    {
        New-InvalidOperationException -Message $script:localizedData.WSUSConfigurationFailed -ErrorRecord $_
    }

    if ($null -ne $UpdateApproval)
    {
        $Action = $UpdateApproval.Action
        $Id = $UpdateApproval.Id.Guid
        $Ensure = 'Present'
        Write-Verbose -Message ($script:localizedData.FoundUpdateApproval -f $UpdateId, $RevisionNumber, $ComputerTargetGroupName, $Id)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotFoundUpdateApproval -f $UpdateId, $RevisionNumber, $ComputerTargetGroupName)
    }

    $returnValue = @{
        Ensure                      = $Ensure
        UpdateId                    = $UpdateId
        RevisionNumber              = $RevisionNumber
        ComputerTargetGroupName     = $ComputerTargetGroupName
        Action                      = $Action
        Id                          = $Id
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the state of the WSUS Update Approval.

    .PARAMETER Ensure
        Determines if the Update Approval should be created or removed. Accepts 'Present' (default) or 'Absent'.

    .PARAMETER UpdateId
        The Update ID GUID in string format.

    .PARAMETER RevisionNumber
        The Revision Number of Update which (in combination with UpdateId) uniquely identifies the update.

    .PARAMETER ComputerTargetGroupName
        The Name of the Computer Target Group on which to define the approval.

    .PARAMETER Action
        The Approval Action associated with the approval.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $UpdateId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RevisionNumber,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ComputerTargetGroupName,

        [Parameter()]
        [ValidateSet('Install', 'NotApproved', 'Uninstall')]
        [System.String]
        $Action = 'Install'
    )

    $result = Get-TargetResource -UpdateId $UpdateId -RevisionNumber $RevisionNumber -ComputerTargetGroupName $ComputerTargetGroupName

    try
    {
        $WsusServer = Get-WsusServer

        if ($result.Ensure -eq 'Present')
        {
            if ($Ensure -eq 'Present')
            {
                # existing update approval action does not match desired state (requires a deletion and recreation)
                $UpdateApproval = $WsusServer.GetUpdateApproval($result.Id)

                $UpdateApproval.Delete()
                Write-Verbose -Message ($script:localizedData.DeleteUpdateApproval -f `
                $result.Id, $UpdateId, $RevisionNumber, $ComputerTargetGroupName)

                $Update = Get-UpdateServicesUpdate -WSUSServer $WsusServer -UpdateId $UpdateId -RevisionNumber $RevisionNumber
                $ComputerTargetGroup = $WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq $ComputerTargetGroupName }

                $result = $Update.Approve($UpdateApprovalAction."$Action", $ComputerTargetGroup)
                Write-Verbose -Message ($script:localizedData.ApproveUpdateApproval -f `
                $result.Id.Guid, $UpdateId, $RevisionNumber, $ComputerTargetGroupName, $Action)
            }
            else
            {
                # desired state must be absent so delete update approval
                $UpdateApproval = $WsusServer.GetUpdateApproval($result.Id)
                $UpdateApproval.Delete()
                Write-Verbose -Message ($script:localizedData.DeleteUpdateApproval -f `
                $result.Id, $UpdateId, $RevisionNumber, $ComputerTargetGroupName)
            }
        }
        else
        {
            # ensure must be present so create update approval
            $Update = Get-UpdateServicesUpdate -WSUSServer $WsusServer -UpdateId $UpdateId -RevisionNumber $RevisionNumber
            $ComputerTargetGroup = $WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq $ComputerTargetGroupName }
            $result = $Update.Approve($UpdateApprovalAction."$Action", $ComputerTargetGroup)
            Write-Verbose -Message ($script:localizedData.ApproveUpdateApproval -f `
            $result.Id.Guid, $UpdateId, $RevisionNumber, $ComputerTargetGroupName, $Action)
        }
    }
    catch
    {
        New-InvalidOperationException -Message $script:localizedData.WSUSConfigurationFailed -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests the current state of the WSUS Update Approval.

    .PARAMETER Ensure
        Determines if the Update Approval should be created or removed. Accepts 'Present' (default) or 'Absent'.

    .PARAMETER UpdateId
        The Update ID GUID in string format.

    .PARAMETER RevisionNumber
        The Revision Number of Update which (in combination with UpdateId) uniquely identifies the update.

    .PARAMETER ComputerTargetGroupName
        The Name of the Computer Target Group on which to define the approval.

    .PARAMETER Action
        The Approval Action associated with the approval.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $UpdateId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RevisionNumber,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ComputerTargetGroupName,

        [Parameter()]
        [ValidateSet('Install', 'NotApproved', 'Uninstall')]
        [System.String]
        $Action = 'Install'
    )

    $result = Get-TargetResource -UpdateId $UpdateId -RevisionNumber $RevisionNumber -ComputerTargetGroupName $ComputerTargetGroupName

    if ($result.Ensure -eq 'Present')
    {
        if ($Ensure -eq 'Present')
        {
            if ($result.Action -eq $Action)
            {
                Write-Verbose -Message ($script:localizedData.ResourceInDesiredState -f `
                $UpdateId, $RevisionNumber, $ComputerTargetGroupName, $result.Action, $Action)
                return $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.ResourceNotInDesiredStateAction -f `
                $UpdateId, $RevisionNumber, $ComputerTargetGroupName, $result.Action, $Action)
                return $false
            }
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.ResourceNotInDesiredStateEnsure -f `
            $UpdateId, $RevisionNumber, $ComputerTargetGroupName, $result.Ensure, $Ensure)
            return $false
        }
    }
    else
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.ResourceNotInDesiredStateEnsure -f `
            $UpdateId, $RevisionNumber, $ComputerTargetGroupName, $result.Ensure, $Ensure)
            return $false
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.ResourceInDesiredStateAbsent -f `
            $UpdateId, $RevisionNumber, $ComputerTargetGroupName, $result.Ensure, $Ensure)
            return $true
        }
    }
}


<#
    .SYNOPSIS
        Gets the specified Update Services Update from the WSUS Server.

    .PARAMETER WSUSServer
        A reference to the WSUS Server object.

    .PARAMETER UpdateId
        The Update ID GUID in string format.

    .PARAMETER RevisionNumber
        RevisionNumber: The Revision Number of the Update which (in combination with UpdateId) uniquely identifies the update.
#>
function Get-UpdateServicesUpdate
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [object]
        $WSUSServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $UpdateId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RevisionNumber
    )

    # create the UpdateRevisionId to retrieve the required update
    $UpdateRevisionId = New-Object -TypeName 'Microsoft.UpdateServices.Administration.UpdateRevisionId' -ArgumentList $UpdateId, $RevisionNumber
    return $WSUSServer.GetUpdate($UpdateRevisionId)
}

<#
    .SYNOPSIS
        Gets the specified Update Services Update Approval from the WSUS Server.

    .PARAMETER Update
        A reference to the Update object.

    .PARAMETER ComputerTargetGroup
        A reference to the Computer Target Group. If not provided all Update Approvals are returned for the specified update.
#>
function Get-UpdateServicesUpdateApproval
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [object]
        $Update,

        [Parameter()]
        [object]
        $ComputerTargetGroup
    )

    if ($null -eq $ComputerTargetGroup)
    {
        return $Update.GetUpdateApprovals()
    }
    else
    {
        return $Update.GetUpdateApprovals($ComputerTargetGroup)
    }
}

Export-ModuleMember -Function *-TargetResource
