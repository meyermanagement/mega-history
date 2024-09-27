/**
 * @description     Assigns super admin access to installing user of package
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public class AssignAdminPermSet implements InstallHandler {

    /**
     * @description runs the install
     * @param context
     */
    public void onInstall(InstallContext context) {
        if(context.previousVersion() == null) {
            /*
            * Assign the MEGA_History_Super_Admin permission set to the defailt DX User so that you can access the MEGA History Admin app
            */
            // Find the FNS_SystemAdminSuperset permission set
            Map<Id, PermissionSet> permSets = new Map<Id, PermissionSet>([SELECT Id FROM PermissionSet WHERE Name = 'MEGA_History_Super_Admin']);

            Set<String> existingPermSetAssignments = new Set<String>();
            for(PermissionSetAssignment psa : [SELECT Id, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId IN :permsets.keySet()]){
                existingPermSetAssignments.add(psa.PermissionSetId);
            }

            List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
            for(PermissionSet ps : permSets.values()){
                if(!existingPermSetAssignments.contains(ps.Id)){
                    permissionSetAssignments.add(new PermissionSetAssignment(
                        AssigneeId = UserInfo.getUserId(),
                        PermissionSetId = ps.Id
                    ));
                }
            }

            if(!permissionSetAssignments.isEmpty()) insert permissionSetAssignments;
        }
    }
}