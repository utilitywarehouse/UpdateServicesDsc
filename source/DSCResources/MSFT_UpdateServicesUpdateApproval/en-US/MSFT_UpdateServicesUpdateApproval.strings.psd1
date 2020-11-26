# Localized Strings for UpdateServicesApprovalRule resource
ConvertFrom-StringData @'
GetWsusServerFailed                 = Get-WsusServer failed to return a WSUS Server. The server may not yet have been configured.
WSUSConfigurationFailed             = WSUS Computer Target Group configuration failed.
GetWsusServerSucceeded              = WSUS Server information has been successfully retrieved from server '{0}'.
UpdateNotFound                      = The update with UpdateId '{0}' and RevisionNumber '{1}' could not be found on the server.
UpdateFound                         = The update with UpdateId '{0}' and RevisionNumber '{1}' was successfully located.
NotFoundComputerTargetGroup         = A Computer Target Group with Name '{0}' could not be found.
NotFoundUpdateApproval              = An Update Approval for the update with UpdateId '{0}', RevisionNumber '{1}' and for Computer Target Group Name '{2}' was not found.
FoundUpdateApproval                 = An Update Approval for the update with UpdateId '{0}', RevisionNumber '{1}' and for Computer Target Group Name '{2}' was found with Id '{3}'.
ResourceInDesiredStateAbsent        = The Update Approval for the update with UpdateId '{0}', RevisionNumber '{1}' and for Computer Target Group Name '{2}' is '{3}' which is the desired state.
ResourceInDesiredState              = The Update Approval for the update with UpdateId '{0}', RevisionNumber '{1}' and for Computer Target Group Name '{2}' is 'Present' with an 'Action' of '{3}' which is the desired state ('{4}').
ResourceNotInDesiredStateEnsure     = The Update Approval for the update with UpdateId '{0}', RevisionNumber '{1}' and for Computer Target Group Name '{2}' is '{3}' which is not the desired state ('{4}').
ResourceNotInDesiredStateAction     = The Update Approval 'Action' for the update with UpdateId '{0}', RevisionNumber '{1}' and for Computer Target Group Name '{2}' is set to'{3}' which is not the desired state ('{4}').
DeleteUpdateApproval                = Update Approval '{0}' for  UpdateId '{1}', RevisionNumber '{2}' and for Computer Target Group Name '{3}' has been deleted.
ApproveUpdateApproval               = Update Approval '{0}' for  UpdateId '{1}', RevisionNumber '{2}', for Computer Target Group Name '{3}' and with Action '{4}' has been successfully created.
'@
