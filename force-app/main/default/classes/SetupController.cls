global with sharing class SetupController {

    @AuraEnabled(cacheable=true)
    global static Boolean checkMetadataAPIConnection() {
        try {
            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
            service.SessionHeader = new MetadataService.SessionHeader_element();
            service.SessionHeader.sessionId = getSessionIdFromVFPage();
            List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
            MetadataService.ListMetadataQuery remoteSites = new MetadataService.ListMetadataQuery();
            remoteSites.type_x = 'RemoteSiteSetting';
            queries.add(remoteSites);
            service.listMetadata(queries, 58);
            //return true;
        } catch (Exception e) {
            System.debug(e.getMessage());
            return true;
        }
        return false;
    }

    @AuraEnabled(cacheable=true)
    global static Boolean checkPermissionAssignment() {
        try {
            List<PermissionSetAssignment> assignments = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Mega_History_User' AND AssigneeId != :UserInfo.getUserId()];
            return assignments.isEmpty();
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    global static Boolean checkRecordTracking() {
        try {
            List<Tracked_Object__mdt> records = [SELECT Id FROM Tracked_Object__mdt LIMIT 1];
            return records.isEmpty();
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    global static Boolean checkViews() {
        try {
            List<Historical_View__mdt> records = [SELECT Id FROM Historical_View__mdt LIMIT 1];
            return records.isEmpty();
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    global static String getSessionIdFromVFPage(){
        try {
            String content = Page.SessionIdPage.getContent().toString();
            Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
                    e = content.indexOf('End_Of_Session_Id');
            return content.substring(s, e);
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    global static String getOrgURL(){
        try {
            return URL.getOrgDomainUrl().toExternalForm();
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


}