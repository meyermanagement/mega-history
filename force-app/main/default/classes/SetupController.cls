/**
 * @description     Controller for the Setup LWC
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class SetupController {

    /**
     * @description     Checks that the connection to the MetaData API will work
     */
    @AuraEnabled(cacheable=true)
    public static Boolean checkMetadataAPIConnection() {
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

    /**
     * @description     Checks that other users have been assigned to the MEGA History permission sets
     */
    @AuraEnabled(cacheable=true)
    public static Boolean checkPermissionAssignment() {
        try {
            List<PermissionSetAssignment> assignments = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Mega_History_User' AND AssigneeId != :UserInfo.getUserId()];
            return assignments.isEmpty();
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     Checks that tracking on objects has been configured
     */
    @AuraEnabled(cacheable=true)
    public static Boolean checkRecordTracking() {
        try {
            List<Tracked_Object__mdt> records = [SELECT Id FROM Tracked_Object__mdt LIMIT 1];
            return records.isEmpty();
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     Checks that the lightning web compnent has been embedded on any lightning record pages
     */
    @AuraEnabled(cacheable=true)
    public static Boolean checkViews() {
        try {
            Initialization__c initialization = Initialization__c.getInstance();
            return !initialization.initialized__c;
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     get the session id from a VF Page
     */
    @AuraEnabled(cacheable=true)
    public static String getSessionIdFromVFPage(){
        try {
            if(!Test.isRunningTest()){
                String content = Page.SessionIdPage.getContent().toString();
                Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
                        e = content.indexOf('End_Of_Session_Id');
                return content.substring(s, e);
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     get the Org URL
     */
    @AuraEnabled(cacheable=true)
    public static String getOrgURL(){
        try {
            return URL.getOrgDomainUrl().toExternalForm();
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


}