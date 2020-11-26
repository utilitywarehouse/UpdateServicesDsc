function Get-WsusServer
{
    $WsusServer = [pscustomobject] @{
        Name = 'ServerName'
        # the following properties are used for mocking purposes only
        UpdateRevisionId = $null
    }

    $ApprovalRule = [scriptblock]{
        $ApprovalRule = [pscustomobject] @{
            Name = 'ServerName'
            Enabled = $true
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
            $UpdateClassification = [pscustomobject] @{
                Name = 'Update Classification'
                ID = [pscustomobject] @{
                    GUID = '00000000-0000-0000-0000-0000testguid'
                }
            }
            return $UpdateClassification
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name GetCategories -Value {
            $Products = [pscustomobject] @{
                Title = 'Product'
            }
            $Products | Add-Member -MemberType ScriptMethod -Name Add -Value {}
            return $Products
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name GetComputerTargetGroups -Value {
            $ComputerTargetGroups = [pscustomobject] @{
                Name = 'Computer Target Group'
            }
            $ComputerTargetGroups | Add-Member -MemberType ScriptMethod -Name Add -Value {}
            return $ComputerTargetGroups
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name Save -Value {}

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name SetCategories -Value {}

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name SetComputerTargetGroups -Value {}

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name SetUpdateClassifications -Value {}

        return $ApprovalRule
    }

    $ComputerTargetGroups = [scriptblock]{
        $ComputerTargetGroups = @(
            [pscustomobject] @{
                Name = 'All Computers'
                Id = [pscustomobject] @{
                    GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                }
            },
            [pscustomobject] @{
                Name = 'Servers'
                Id = [pscustomobject] @{
                    GUID = '14adceba-ddf3-4299-9c1a-e4cf8bd56c47'
                }
                ParentTargetGroup = [pscustomobject] @{
                    Name = 'All Computers'
                    Id = [pscustomobject] @{
                        GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                    }
                }
                ChildTargetGroup = [pscustomobject] @{
                    Name = 'Web'
                    Id = [pscustomobject] @{
                        GUID = 'f4aa59c7-e6a0-4e6d-97b0-293d00a0dc60'
                    }
                }
            },
            [pscustomobject] @{
                Name = 'Web'
                Id = [pscustomobject] @{
                    GUID = 'f4aa59c7-e6a0-4e6d-97b0-293d00a0dc60'
                }
                ParentTargetGroup = [pscustomobject] @{
                    Name = 'Servers'
                    Id = [pscustomobject] @{
                        GUID = '14adceba-ddf3-4299-9c1a-e4cf8bd56c47'
                    }
                    ParentTargetGroup = [pscustomobject] @{
                        Name = 'All Computers'
                        Id = [pscustomobject] @{
                            GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                        }
                    }
                }
            },
            [pscustomobject] @{
                Name = 'Workstations'
                Id = [pscustomobject] @{
                    GUID = '31742fd8-df6f-4836-82b4-b2e52ee4ba1b'
                }
                ParentTargetGroup = [pscustomobject] @{
                    Name = 'All Computers'
                    Id = [pscustomobject] @{
                        GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                    }
                }
            },
            [pscustomobject] @{
                Name = 'Desktops'
                Id = [pscustomobject] @{
                    GUID = '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'
                }
                ParentTargetGroup = [pscustomobject] @{
                    Name = 'Workstations'
                    Id = [pscustomobject] @{
                        GUID = '31742fd8-df6f-4836-82b4-b2e52ee4ba1b'
                    }
                    ParentTargetGroup = [pscustomobject] @{
                        Name = 'All Computers'
                        Id = [pscustomobject] @{
                            GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                        }
                    }
                }
            }
        )

        foreach ($ComputerTargetGroup in $ComputerTargetGroups)
        {
            Add-Member -InputObject $ComputerTargetGroup -MemberType ScriptMethod -Name Delete -Value {}

            Add-Member -InputObject $ComputerTargetGroup -MemberType ScriptMethod -Name GetParentTargetGroup -Value {
                return $this.ParentTargetGroup
            }

            if ($null -ne $ComputerTargetGroup.ParentTargetGroup)
            {
                Add-Member -InputObject $ComputerTargetGroup.ParentTargetGroup -MemberType ScriptMethod -Name GetParentTargetGroup -Value {
                    return $this.ParentTargetGroup
                }
            }

            if ($null -ne $ComputerTargetGroup.ChildTargetGroup)
            {
                Add-Member -InputObject $ComputerTargetGroup -MemberType ScriptMethod -Name GetChildTargetGroups -Value {
                    return $this.ChildTargetGroup
                }

                Add-Member -InputOBject $ComputerTargetGroup.ChildTargetGroup -MemberType ScriptMethod -Name Delete -Value {}
            }
        }

        return $ComputerTargetGroups
    }

    $Updates = [scriptblock]{
        $Updates = @(
            [pscustomobject] @{
                Id = [pscustomobject] @{
                    UpdateId = 'bb8a1680-c531-4cd7-8eb1-38f23bda31a6'
                    RevisionNumber = 201
                }
                Title = 'Critical Update for...'
                UpdateApprovals = @(
                    [pscustomobject] @{
                        Id = [pscustomobject] @{
                            GUID = 'a96e9d8f-23b8-429c-ad0d-11a41d6f891e'
                        }
                        Action = 'Install'
                        ComputerTargetGroupId = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                    },
                    [pscustomobject] @{
                        Id = [pscustomobject] @{
                            GUID = 'ad437fc1-8195-481a-a531-cb2bd30d04ab'
                        }
                        Action = 'NotApproved'
                        ComputerTargetGroupId = '14adceba-ddf3-4299-9c1a-e4cf8bd56c47'
                    }
                )
            },
            [pscustomobject] @{
                Id = [pscustomobject] @{
                    UpdateId = '5df07312-fca5-43af-a72d-5ac84c0596d9'
                    RevisionNumber = 201
                }
                Title = 'Critical Update for...'
                UpdateApprovals = @(
                    [pscustomobject] @{
                        Id = [pscustomobject] @{
                            GUID = '2696a1d3-b612-4458-8ed3-708f995b73ba'
                        }
                        Action = 'Install'
                        ComputerTargetGroupId = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                    }
                )
            },
            [pscustomobject] @{
                Id = [pscustomobject] @{
                    UpdateId = '2a56c7b4-2d7f-4390-8cd5-b0169d559327'
                    RevisionNumber = 200
                }
                Title = 'Critical Update for...'
                UpdateApprovals = @(
                )
            }
        )

        foreach ($Update in $Updates)
        {
            Add-Member -InputOBject $Update -MemberType ScriptMethod -Name GetUpdateApprovals -Value {
                return $this.UpdateApprovals
            }

            Add-Member -InputOBject $Update -MemberType ScriptMethod -Name Approve -Value {
                return  [pscustomobject] @{
                    Id = [pscustomobject] @{
                        GUID = '93e7cf4f-eb92-477a-9111-82ef103d8284'
                    }
                }
            }

            foreach ($UpdateApproval in $Update.UpdateApprovals)
            {
                Add-Member -InputOBject $UpdateApproval -MemberType ScriptMethod -Name Delete -Value {}
            }
        }

        return $Updates
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name CreateComputerTargetGroup -Value {
        param
        (
            [Parameter(Mandatory = $true)]
            [string]
            $Name,

            [Parameter(Mandatory = $true)]
            [object]
            $ComputerTargetGroup
        )
        {
            Write-Output $Name
            Write-Output $ComputerTargetGroup
        }
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetInstallApprovalRules -Value $ApprovalRule

    $WsusServer | Add-Member -MemberType ScriptMethod -Name CreateInstallApprovalRule -Value $ApprovalRule

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdateClassification -Value {}

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetComputerTargetGroups -Value $ComputerTargetGroups

    $WsusServer | Add-Member -MemberType ScriptMethod -Name DeleteInstallApprovalRule -Value {}

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetSubscription -Value {
            $Subscription = [pscustomobject] @{
                SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                NumberOfSynchronizationsPerDay = 24
                SynchronizeAutomatically = $true
            }
            $Subscription | Add-Member -MemberType ScriptMethod -Name StartSynchronization -Value {}
            $Subscription | Add-Member -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
                $UpdateClassification = [pscustomobject] @{
                    Name = 'Update Classification'
                    ID = [pscustomobject] @{
                        GUID = '00000000-0000-0000-0000-0000testguid'
                    }
                }
                return $UpdateClassification
            }
            $Subscription | Add-Member -MemberType ScriptMethod -Name GetUpdateCategories -Value {
                $Categories = [pscustomobject] @{
                    Title = 'Category'
                }
                return $Categories
            }
            return $Subscription
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdates -Value $Updates

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdate -Value {
        $Update = ( $this.GetUpdates() | Where-Object -FilterScript {
            $_.Id.UpdateId -eq $this.UpdateRevisionId.UpdateId -and `
            $_.Id.RevisionNumber -eq $this.UpdateRevisionId.RevisionNumber
        } )

        if ($null -ne $Update)
        {
            return $Update
        }
        else
        {
            throw 'Exception calling "GetUpdate" with "1" argument(s): "The specified item could not be found in the database.'
        }
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdateApproval -Value {
        $UpdateApproval =  [pscustomobject] @{
            Id = [pscustomobject] @{
                GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
            }
        }

        Add-Member -InputOBject $UpdateApproval -MemberType ScriptMethod -Name Delete -Value {}
        return $UpdateApproval
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetConfiguration -Value {
        $Configuration = @{
            ProxyName = ''
            ProxyServerPort = $null
            ProxyServerBasicAuthentication = $false
            UpstreamWsusServerName = ''
            UpstreamWsusServerPortNumber = $null
            UpStreamServerSSL =  $false
            MURollupOptin = $true
            AllUpdateLanguagesEnabled = $true
        }
        $Configuration | Add-Member -MemberType ScriptMethod -Name GetEnabledUpdateLanguages -Value {}
        return $Configuration
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
        $UpdateClassification = [pscustomobject] @{
            Name = 'Update Classification'
            ID = [pscustomobject]@{
                GUID = '00000000-0000-0000-0000-0000testguid'
            }
        }
        return $UpdateClassification
    }

    $WsusServer  | Add-Member -MemberType ScriptMethod -Name GetUpdateCategories -Value {
        $Categories = [pscustomobject] @{
            Title = 'Category'
        }
        return $Categories
    }

    return $WsusServer
}

function Get-WsusClassification
{
    $WsusClassification = [pscustomobject] @{
        Classification = [pscustomobject] @{
            ID = [pscustomobject] @{
                Guid = '00000000-0000-0000-0000-0000testguid'
            }
        }
    }
    return $WsusClassification
}

function Get-WsusProduct {}
