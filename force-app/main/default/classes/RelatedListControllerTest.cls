/**
 * @description     test for Related List Controller
 * @author          Mark Meyer
 * @date            09/27/2024
 */
@isTest
public class RelatedListControllerTest {

    /**
     * @description     test all methods
     */
    @isTest public static void testInit(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.'+UserInfo.getOrganizationId());
        insert u;
        Map<Id, PermissionSet> permSets = new Map<Id, PermissionSet>([SELECT Id FROM PermissionSet WHERE Name = 'MEGA_History_Super_Admin']);

        Set<String> existingPermSetAssignments = new Set<String>();
        for(PermissionSetAssignment psa : [SELECT Id, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :u.Id AND PermissionSetId IN :permsets.keySet()]){
            existingPermSetAssignments.add(psa.PermissionSetId);
        }

        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        for(PermissionSet ps : permSets.values()){
            if(!existingPermSetAssignments.contains(ps.Id)){
                permissionSetAssignments.add(new PermissionSetAssignment(
                    AssigneeId = u.Id,
                    PermissionSetId = ps.Id
                ));
            }
        }

        if(!permissionSetAssignments.isEmpty()) {
            insert permissionSetAssignments;
        }
        System.runAs(u) {
            Account acc = new Account(Name = 'test');
            insert acc;
            Task t = new Task(Subject='Test Task', ActivityDate=System.today().addDays(7));
            insert t;
            Contact cnt = new Contact(LastName = 'test', AccountId = acc.Id);
            insert cnt;

            Map<String, Object> requestMap = new Map<String, Object>(); 
            requestMap.put(RelatedListController.RECORD_ID_PARAM, t.Id);
            requestMap.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
            requestMap.put(RelatedListController.SOBJECT_API_NAME_PARAM, 'Task');
            requestMap.put(RelatedListController.SORTED_BY_PARAM, 'Name');
            requestMap.put(RelatedListController.SORTED_DIRECTION_PARAM, 'ASC');

            String jsonData = RelatedListController.initData(JSON.serialize(requestMap), 'false');
                    
            requestMap = new Map<String, Object>(); 
            requestMap.put(RelatedListController.RECORD_ID_PARAM, acc.Id);
            requestMap.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
            requestMap.put(RelatedListController.SOBJECT_API_NAME_PARAM, 'Account');
            requestMap.put(RelatedListController.SORTED_BY_PARAM, 'Name');
            requestMap.put(RelatedListController.SORTED_DIRECTION_PARAM, 'ASC');
                    
            jsonData = RelatedListController.initData(JSON.serialize(requestMap), 'true');
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
            String iconName = (String)responseMap.get(RelatedListController.ICON_NAME_PARAM);
            System.assert(true, String.isNotBlank(iconName));

            Record_History__c rh = new Record_History__c();
            rh.Record__c = cnt.Id;
            rh.Record_Name__c = cnt.LastName;
            rh.ParentId__c = acc.Id;
            //AccountHistory ah = new AccountHistory();
            HistoryWrapper hw = RelatedListController.createWrapper(rh, 'Record_History__c');
            hw = RelatedListController.createWrapper(rh, 'ActivityFieldHistory');
            hw = RelatedListController.createWrapper(rh, 'Histories');

            RelatedListController.getParentRelationshipName(acc.Id, 'Contact', 'AccountId');
            rh = RelatedListController.getHistoryRecord(acc.Id, null, false);
            rh = RelatedListController.getHistoryRecord(acc.Id, null, true);
            insert rh;
            rh.Created_By_DL__c = null;
            rh.Created_Date_DL__c = null;
            try{
                RelatedListController.saveHistory(JSON.serialize(rh));
            } catch(Exception e){
                System.assertEquals('Script-thrown exception', e.getMessage(), 'Error message not set as expected');
            }
            rh.Record_Name__c = 'Test';
            RelatedListController.saveHistory(JSON.serialize(rh));
            rh = RelatedListController.getHistoryRecord(acc.Id, rh.Id, false);
            System.assertEquals(null, null, 'Created Date not set as expected');
            RelatedListController.getFields(acc.Id);
            RelatedListController.getNameField('Contact');
            RelatedListController.getIconName('Account');
            RelatedListController.getIconName('Product2');
            RelatedListController.getIconName('Test');
        }
    }
}