$script:dscModuleName = 'UpdateServicesDsc'
$script:dscResourceName = 'MSFT_UpdateServicesUpdateApproval'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module -Name DscResource.Test -Force -ErrorAction Stop

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType Unit

#endregion HEADER


# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {

        #region Pester Test Initialization
        Import-Module $PSScriptRoot\..\Helpers\ImitateUpdateServicesModule.psm1 -Force

        #endregion

        #region Function Get-TargetResource
        Describe "MSFT_UpdateServicesUpdateApproval\Get-TargetResource." {
            BeforeEach {
                if (Test-Path -Path variable:script:resource) { Remove-Variable -Scope 'script' -Name 'resource' }
            }

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.UpdateServices.Administration.UpdateRevisionId'
            } -MockWith {
                $result = [pscustomobject] @{
                    UpdateId = $UpdateId
                    RevisionNumber = $RevisionNumber
                }
                # used to pass a parameter to the mock representation of GetUpdates()
                $wsusServer.UpdateRevisionId = $result
                return $result
            }

            Mock -CommandName Get-UpdateServicesUpdateApproval -MockWith {
                if ($null -eq $ComputerTargetGroup)
                {
                    return $Update.GetUpdateApprovals()

                }
                else
                {
                    return ( $Update.GetUpdateApprovals() | Where-Object -FilterScript {
                        $_.ComputerTargetGroupId -eq $ComputerTargetGroup.Id.Guid
                    } )
                }
            }

            $UpdateServicesApprovalParamsUpdateWithApprovals = @{
                UpdateId = "bb8a1680-c531-4cd7-8eb1-38f23bda31a6"
                RevisionNumber = 201
                ComputerTargetGroupName = 'All Computers'
            }

            $UpdateServicesApprovalParamsUpdateWithoutApprovals = @{
                UpdateId = "2a56c7b4-2d7f-4390-8cd5-b0169d559327"
                RevisionNumber = 200
                ComputerTargetGroupName = 'All Computers'
            }

            $UpdateServicesApprovalParamsNonExistentUpdate = @{
                UpdateId = "94d82e01-5813-4b88-925b-490039555b28"
                RevisionNumber = 201
                ComputerTargetGroupName = 'All Computers'
            }

            Mock -CommandName Write-Verbose -MockWith {}

            Context 'An error occurs retrieving WSUS Server configuration information.' {
                Mock -CommandName Get-WsusServer -MockWith { throw 'An error occurred.' }

                It 'Calling Get should throw when an error occurrs retrieving WSUS Server information.' {
                    { $script:resource = Get-TargetResource @UpdateServicesApprovalParamsUpdateWithApprovals } | Should -Throw ($script:localizedData.WSUSConfigurationFailed)
                    $script:resource | Should -Be $null
                    Assert-MockCalled -CommandName Get-WsusServer -Exactly 1
                }
            }

            Context 'The WSUS Server is not yet configured.' {
                Mock -CommandName Get-WsusServer -MockWith {}

                It 'Calling Get should not throw when the WSUS Server is not yet configuration / cannot be found.' {
                    { $script:resource = Get-TargetResource @UpdateServicesApprovalParamsUpdateWithApprovals } | Should -Not -Throw
                    Assert-MockCalled -CommandName Write-Verbose  -ParameterFilter {
                        $message -eq $script:localizedData.GetWsusServerFailed
                    }
                    $script:resource.Ensure | Should -Be 'Absent'
                    $script:resource.UpdateId | should -Be 'bb8a1680-c531-4cd7-8eb1-38f23bda31a6'
                    $script:resource.RevisionNumber | should -Be 201
                    $script:resource.ComputerTargetGroupName | should -Be 'All Computers'
                    $script:resource.Action | should -Be $null
                    $script:resource.Id | should -Be $null
                }
            }

            Context 'The Update associated with the Approval cannot be found on the WSUS Server.' {

                It 'Calling Get should throw when the specified update cannot be found.' {
                    { $script:resource = Get-TargetResource @UpdateServicesApprovalParamsNonExistentUpdate } | Should -Throw `
                    ($script:localizedData.UpdateNotFound -f '94d82e01-5813-4b88-925b-490039555b28', 201)
                    $script:resource | Should -Be $null
                }
            }

            Context 'The Update associated with the Approval is found on the WSUS Server but has no approvals.' {

                It 'Calling Get should return an object without any defined approvals (Ensure = "Absent").' {
                    $script:resource = Get-TargetResource @UpdateServicesApprovalParamsUpdateWithoutApprovals
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.UpdateFound -f '2a56c7b4-2d7f-4390-8cd5-b0169d559327', 200)
                    }
                    Assert-MockCalled -CommandName Get-UpdateServicesUpdateApproval -ParameterFilter {
                        $Update.Id.UpdateId -eq '2a56c7b4-2d7f-4390-8cd5-b0169d559327' `
                        -and $Update.Id.RevisionNumber -eq 200 `
                        -and $ComputerTargetGroup.Id.Guid -eq '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                    }
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.NotFoundUpdateApproval -f '2a56c7b4-2d7f-4390-8cd5-b0169d559327', `
                        200, 'All Computers')
                    }
                    $script:resource.Ensure | Should -Be 'Absent'
                    $script:resource.UpdateId | should -Be '2a56c7b4-2d7f-4390-8cd5-b0169d559327'
                    $script:resource.RevisionNumber | should -Be 200
                    $script:resource.ComputerTargetGroupName | should -Be 'All Computers'
                    $script:resource.Action | should -Be $null
                    $script:resource.Id | should -Be $null
                }
            }

            Context 'The Update associated with the Approval is found on the WSUS Server and has approvals.' {

                It 'Calling Get should return an object without defined approval (Ensure = "Present").' {
                    $script:resource = Get-TargetResource @UpdateServicesApprovalParamsUpdateWithApprovals
                    Assert-MockCalled -CommandName Get-UpdateServicesUpdateApproval -ParameterFilter {
                        $Update.Id.UpdateId -eq 'bb8a1680-c531-4cd7-8eb1-38f23bda31a6' `
                        -and $Update.Id.RevisionNumber -eq 201 `
                        -and $ComputerTargetGroup.Id.Guid -eq '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                    }
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.FoundUpdateApproval -f 'bb8a1680-c531-4cd7-8eb1-38f23bda31a6', `
                        201, 'All Computers', 'a96e9d8f-23b8-429c-ad0d-11a41d6f891e')
                    }
                    $script:resource.Ensure | Should -Be 'Present'
                    $script:resource.UpdateId | should -Be 'bb8a1680-c531-4cd7-8eb1-38f23bda31a6'
                    $script:resource.RevisionNumber | should -Be 201
                    $script:resource.ComputerTargetGroupName | should -Be 'All Computers'
                    $script:resource.Action | should -Be 'Install'
                    $script:resource.Id | should -Be 'a96e9d8f-23b8-429c-ad0d-11a41d6f891e'
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe "MSFT_UpdateServicesComputerTargetGroup\Test-TargetResource." {
            Mock -CommandName Write-Verbose -MockWith {}

            $UpdateServicesApprovalParamsUpdateWithApprovals = @{
                UpdateId = "bb8a1680-c531-4cd7-8eb1-38f23bda31a6"
                RevisionNumber = 201
                ComputerTargetGroupName = 'All Computers'
            }

            $UpdateServicesApprovalParamsUpdateWithoutApprovals = @{
                UpdateId = "2a56c7b4-2d7f-4390-8cd5-b0169d559327"
                RevisionNumber = 200
                ComputerTargetGroupName = 'All Computers'
            }

            Context 'The Update Approval is defined and (Ensure = "Absent").' {
                $approval = $UpdateServicesApprovalParamsUpdateWithApprovals
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        UpdateId = $approval.UpdateId
                        RevisionNumber = $approval.RevisionNumber
                        ComputerTargetGroupName = $approval.ComputerTargetGroupName
                        Action = 'Install'
                        Id = 'a96e9d8f-23b8-429c-ad0d-11a41d6f891e'
                    }
                }

                It 'Test-TargetResource should return $false where Update Approval is defined and Ensure = "Absent"'  {
                    $resource = Test-TargetResource @approval -Ensure 'Absent'
                    $resource | Should -Be $false
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ResourceNotInDesiredStateEnsure -f `
                        $approval.UpdateId, $approval.RevisionNumber, $approval.ComputerTargetGroupName, 'Present', 'Absent')
                    }
                }
            }

            Context 'The Update Approval is not defined and (Ensure = "Present").' {
                $approval = $UpdateServicesApprovalParamsUpdateWithoutApprovals
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Absent'
                        UpdateId = $approval.UpdateId
                        RevisionNumber = $approval.RevisionNumber
                        ComputerTargetGroupName = $approval.ComputerTargetGroupName
                        Action = $null
                        Id = $null
                    }
                }

                It 'Test-TargetResource should return $false where Update Approval is not defined and Ensure = "Present"'  {
                    $resource = Test-TargetResource @approval
                    $resource | Should -Be $false
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ResourceNotInDesiredStateEnsure -f `
                        $approval.UpdateId, $approval.RevisionNumber, $approval.ComputerTargetGroupName, 'Absent', 'Present')
                    }
                }
            }

            Context 'The Update Approval is defined but Action does not match expected value ("Uninstall").' {
                $approval = $UpdateServicesApprovalParamsUpdateWithApprovals
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        UpdateId = $approval.UpdateId
                        RevisionNumber = $approval.RevisionNumber
                        ComputerTargetGroupName = $approval.ComputerTargetGroupName
                        Action = 'Install'
                        Id = 'a96e9d8f-23b8-429c-ad0d-11a41d6f891e'
                    }
                }

                It 'Test-TargetResource should return $false where Update Approval is defined and Action does not match expected value.'  {
                    $resource = Test-TargetResource @approval -Action 'Uninstall'
                    $resource | Should -Be $false
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ResourceNotInDesiredStateAction -f `
                        $approval.UpdateId, $approval.RevisionNumber, $approval.ComputerTargetGroupName, 'Install', 'Uninstall')
                    }
                }
            }

            Context 'The Update Approval is not defined and (Ensure = "Absent").' {
                $approval = $UpdateServicesApprovalParamsUpdateWithoutApprovals
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Absent'
                        UpdateId = $approval.UpdateId
                        RevisionNumber = $approval.RevisionNumber
                        ComputerTargetGroupName = $approval.ComputerTargetGroupName
                        Action = $null
                        Id = $null
                    }
                }

                It 'Test-TargetResource should return $false where Update Approval is not defined and Ensure = "Present"'  {
                    $resource = Test-TargetResource @approval -Ensure 'Absent'
                    $resource | Should -Be $true
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ResourceInDesiredStateAbsent -f `
                        $approval.UpdateId, $approval.RevisionNumber, $approval.ComputerTargetGroupName, 'Absent', 'Absent')
                    }
                }
            }

            Context 'The Update Approval is defined and Action matches expected value ("Install").' {
                $approval = $UpdateServicesApprovalParamsUpdateWithApprovals
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        UpdateId = $approval.UpdateId
                        RevisionNumber = $approval.RevisionNumber
                        ComputerTargetGroupName = $approval.ComputerTargetGroupName
                        Action = 'Install'
                        Id = 'a96e9d8f-23b8-429c-ad0d-11a41d6f891e'
                    }
                }

                It 'Test-TargetResource should return $false where Update Approval is defined and Action does not match expected value.'  {
                    $resource = Test-TargetResource @approval -Action 'Install'
                    $resource | Should -Be $true
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ResourceInDesiredState -f `
                        $approval.UpdateId, $approval.RevisionNumber, $approval.ComputerTargetGroupName, 'Install', 'Install')
                    }
                }
            }

        }
        #endregion

        #region Function Set-TargetResource
        Describe "MSFT_UpdateServicesComputerTargetGroup\Set-TargetResource" {
            BeforeEach {
                if (Test-Path -Path variable:script:resource) { Remove-Variable -Scope 'script' -Name 'resource' }
            }

            Mock -CommandName Write-Verbose -MockWith {}

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.UpdateServices.Administration.UpdateRevisionId'
            } -MockWith {
                $result = [pscustomobject] @{
                    UpdateId = $UpdateId
                    RevisionNumber = $RevisionNumber
                }
                # used to pass a parameter to the mock representation of GetUpdates()
                $wsusServer.UpdateRevisionId = $result
                return $result
            }

            $UpdateServicesApprovalParamsUpdateWithApprovals = @{
                UpdateId = "bb8a1680-c531-4cd7-8eb1-38f23bda31a6"
                RevisionNumber = 201
                ComputerTargetGroupName = 'All Computers'
            }

            $UpdateServicesApprovalParamsUpdateWithoutApprovals = @{
                UpdateId = "2a56c7b4-2d7f-4390-8cd5-b0169d559327"
                RevisionNumber = 200
                ComputerTargetGroupName = 'All Computers'
            }

            Context 'An Update Approval already exists for the specified update but is does not match the desired state.' {
                $approval = $UpdateServicesApprovalParamsUpdateWithApprovals
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        UpdateId = $approval.UpdateId
                        RevisionNumber = $approval.RevisionNumber
                        ComputerTargetGroupName = $approval.ComputerTargetGroupName
                        Action = 'Install'
                        Id = 'a96e9d8f-23b8-429c-ad0d-11a41d6f891e'
                    }
                }

                It 'Set-TargetResource will delete and then recreate the current approval to match the required "Action".'  {
                    $resource = Set-TargetResource @approval -Action 'Uninstall'
                    $resource | Should -Be $null
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.DeleteUpdateApproval -f `
                        'a96e9d8f-23b8-429c-ad0d-11a41d6f891e', $approval.UpdateId, $approval.RevisionNumber, `
                        $approval.ComputerTargetGroupName)
                    }
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ApproveUpdateApproval -f `
                        '93e7cf4f-eb92-477a-9111-82ef103d8284', $approval.UpdateId, $approval.RevisionNumber, `
                        $approval.ComputerTargetGroupName, 'Uninstall')
                    }
                }
            }

            Context 'The Update Approval is "Present" and should be "Absent".' {
                $approval = $UpdateServicesApprovalParamsUpdateWithApprovals
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        UpdateId = $approval.UpdateId
                        RevisionNumber = $approval.RevisionNumber
                        ComputerTargetGroupName = $approval.ComputerTargetGroupName
                        Action = 'Install'
                        Id = 'a96e9d8f-23b8-429c-ad0d-11a41d6f891e'
                    }
                }

                It 'Set-TargetResource will delete the existing approval.'  {
                    $resource = Set-TargetResource @approval -Ensure 'Absent'
                    $resource | Should -Be $null
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.DeleteUpdateApproval -f `
                        'a96e9d8f-23b8-429c-ad0d-11a41d6f891e', $approval.UpdateId, $approval.RevisionNumber, `
                        $approval.ComputerTargetGroupName)
                    }
                }
            }

            Context 'An Update Approval does not exist and Ensure = "Present".' {
                $approval = $UpdateServicesApprovalParamsUpdateWithoutApprovals
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Absent'
                        UpdateId = $approval.UpdateId
                        RevisionNumber = $approval.RevisionNumber
                        ComputerTargetGroupName = $approval.ComputerTargetGroupName
                        Action = $null
                        Id = $null
                    }
                }

                It 'Set-TargetResource will create the new approval to match the required "Action".'  {
                    $resource = Set-TargetResource @approval
                    $resource | Should -Be $null
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ApproveUpdateApproval -f `
                        '93e7cf4f-eb92-477a-9111-82ef103d8284', $approval.UpdateId, $approval.RevisionNumber, `
                        $approval.ComputerTargetGroupName, 'Install')
                    }
                }
            }
        }
        #endregion
    }
}

finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
