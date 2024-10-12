/**
 * @description     Assigns super admin access to installing user of package
 * @author          Mark Meyer
 * @date            09/27/2024
 */
global class AssignAdminPermSet implements InstallHandler {

    /**
     * @description runs the install
     * @param context
     */
    global void onInstall(InstallContext context) {
        if(context.previousVersion() == null) {
            /*
            * Assign the MEGA_History_Super_Admin permission set to the defailt DX User so that you can access the MEGA History Admin app
            */
            try{
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

                if(!permissionSetAssignments.isEmpty()) {
                    insert permissionSetAssignments;
                }
            } catch(Exception e) {
                send(
                context.installerId(),
                'Installation Failure' + context.organizationId(),
                ' e: ' + e.getMessage() + ' stack trace ' + e.getStackTraceString()
                );
            }
        }
    }

    /**
     * @description runs the install
     * @param userId
     * @param subject
     * @param htmlBody
     */
    public static void send(Id userId, String subject, String htmlBody) {
        List<User> users = [SELECT Name, FirstName, LastName, UserName, Email FROM User WHERE Id = :userId ];
        User u = users.size() > 0 ? users[0] : new User(Id = userId);
        sendEmail(
            new List<String>{u.Email, 'jetsetandboogie@gmail.com'}, // <= replace with your default email
            subject,
            htmlBody
        );
    }
    
    /**
     * @description runs the install
     * @param recipients
     * @param subject
     * @param htmlBody
     * @param attachments
     */
    public static void sendEmail(List<String> recipients, String subject, String htmlBody) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipients);
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        /* 
        * Currently there is no way to avoid this exception 
        * https://success.salesforce.com/ideaView?id=08730000000cHBEAA2
        */
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        } catch (EmailException e) {
            //emailInvocationFailures++;
            System.debug(e.getMessage());
        }
    }
}