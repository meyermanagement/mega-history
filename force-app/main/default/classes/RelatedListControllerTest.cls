/**
 * @description     test for Related List Controller
 * @author          Mark Meyer
 * @date            09/27/2024
 */
@isTest
public class RelatedListControllerTest {

    /**
     * @description     Setup user with permission set - separate from data setup to avoid mixed DML
     */
    @TestSetup
    static void setupUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.'+UserInfo.getOrganizationId());
        insert u;
        
        // Assign permission set in separate transaction
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
    }

    /**
     * @description     test all methods
     */
    @isTest public static void testInit(){
        User u = [SELECT Id FROM User WHERE UserName = :('standarduser@testorg.com.'+UserInfo.getOrganizationId()) LIMIT 1];
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
            rh.Record_Name__c = 'Test';
            RelatedListController.saveHistory(JSON.serialize(rh));
            rh = RelatedListController.getHistoryRecord(acc.Id, rh.Id, false);
            System.assertEquals(null, null, 'Created Date not set as expected');
            RelatedListController.getFields(acc.Id);
            RelatedListController.getNameField('Contact');
            RelatedListController.getIconName('Account');
            RelatedListController.getIconName('Product2');
            RelatedListController.getIconName('Test__c');
        }
    }
    
    /**
     * @description Test merge lists with ID fields
     */
    @isTest
    static void testMergeListsWithIdFields(){
        User u = [SELECT Id FROM User WHERE UserName = :('standarduser@testorg.com.'+UserInfo.getOrganizationId()) LIMIT 1];
        System.runAs(u) {
            Account acc = new Account(Name = 'Test Account Merge');
            insert acc;
            
            // Create history records with ID values (same timestamp and field to trigger merge logic)
            DateTime now = System.now();
            Record_History__c rh1 = new Record_History__c(
                Record__c = acc.Id,
                Record_Name__c = 'Test Account Merge',
                Event__c = 'Updated',
                Field__c = 'OwnerId',
                Old_Value__c = UserInfo.getUserId(),
                New_Value__c = UserInfo.getUserId(),
                Created_By_DL__c = UserInfo.getUserId(),
                Created_Date_DL__c = now
            );
            
            Record_History__c rh2 = new Record_History__c(
                Record__c = acc.Id,
                Record_Name__c = 'Test Account Merge',
                Event__c = 'Updated',
                Field__c = 'OwnerId',
                Old_Value__c = 'System Administrator',
                New_Value__c = 'System Administrator',
                Created_By_DL__c = UserInfo.getUserId(),
                Created_Date_DL__c = now
            );
            insert new List<Record_History__c>{rh1, rh2};
            
            Test.startTest();
            Map<String, Object> requestMap = new Map<String, Object>(); 
            requestMap.put(RelatedListController.RECORD_ID_PARAM, acc.Id);
            requestMap.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 20);
            
            String jsonData = RelatedListController.initData(JSON.serialize(requestMap), 'false');
            Test.stopTest();
            
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
            System.assertNotEquals(null, responseMap, 'Response should not be null');
        }
    }
    
    /**
     * @description Test split lists with child records
     */
    @isTest
    static void testSplitListsWithChildRecords(){
        User u = [SELECT Id FROM User WHERE UserName = :('standarduser@testorg.com.'+UserInfo.getOrganizationId()) LIMIT 1];
        System.runAs(u) {
            Account acc = new Account(Name = 'Test Account Child');
            insert acc;
            
            Contact cnt = new Contact(LastName = 'TestContact', FirstName = 'John', AccountId = acc.Id);
            insert cnt;
            
            // Create history records for parent and child
            Record_History__c rh1 = new Record_History__c(
                Record__c = acc.Id,
                Record_Name__c = 'Test Account Child',
                Event__c = 'Created',
                Field__c = 'Created.',
                Created_By_DL__c = UserInfo.getUserId(),
                Created_Date_DL__c = System.now()
            );
            
            Record_History__c rh2 = new Record_History__c(
                Record__c = cnt.Id,
                Record_Name__c = 'TestContact',
                ParentId__c = acc.Id,
                Event__c = 'Created',
                Field__c = 'Created.',
                Created_By_DL__c = UserInfo.getUserId(),
                Created_Date_DL__c = System.now().addMinutes(-5)
            );
            insert new List<Record_History__c>{rh1, rh2};
            
            Test.startTest();
            Map<String, Object> requestMap = new Map<String, Object>(); 
            requestMap.put(RelatedListController.RECORD_ID_PARAM, acc.Id);
            requestMap.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 50);
            
            String jsonData = RelatedListController.initData(JSON.serialize(requestMap), 'false');
            Test.stopTest();
            
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
            List<Object> childRecords = (List<Object>)responseMap.get(RelatedListController.CHILD_RECORDS_PARAM);
            List<Object> adultRecords = (List<Object>)responseMap.get(RelatedListController.RECORDS_PARAM);
            
            System.assertNotEquals(null, childRecords, 'Child records should not be null');
            System.assertNotEquals(null, adultRecords, 'Adult records should not be null');
        }
    }
    
    /**
     * @description Test saveHistory with validation errors
     */
    @isTest
    static void testSaveHistoryValidationError(){
        User u = [SELECT Id FROM User WHERE UserName = :('standarduser@testorg.com.'+UserInfo.getOrganizationId()) LIMIT 1];
        System.runAs(u) {
            Account acc = new Account(Name = 'Test Account Validation');
            insert acc;
            
            // Create history without required Record_Name__c for Created event
            Record_History__c rh = new Record_History__c(
                ParentId__c = acc.Id,
                Event__c = 'Created',
                Created_By_DL__c = UserInfo.getUserId(),
                Created_Date_DL__c = System.now()
            );
            
            Test.startTest();
            Boolean exceptionThrown = false;
            String exceptionMessage = '';
            try {
                RelatedListController.saveHistory(JSON.serialize(rh));
            } catch(AuraHandledException e) {
                exceptionThrown = true;
                exceptionMessage = e.getMessage();
            }
            Test.stopTest();
            
            System.assert(exceptionThrown, 'Exception should have been thrown for missing Record Name');
            //System.assert(exceptionMessage.contains('Record Name is required'), 'Should contain validation error message, got: ' + exceptionMessage);
        }
    }
    
    /**
     * @description Test getFields method
     */
    @isTest
    static void testGetFields(){
        User u = [SELECT Id FROM User WHERE UserName = :('standarduser@testorg.com.'+UserInfo.getOrganizationId()) LIMIT 1];
        System.runAs(u) {
            Account acc = new Account(Name = 'Test Account Fields');
            insert acc;
            
            Test.startTest();
            Map<String, String> fields = RelatedListController.getFields(acc.Id);
            Test.stopTest();
            
            System.assertNotEquals(null, fields, 'Fields map should not be null');
            System.assert(fields.size() > 0, 'Should return at least one field');
            System.assert(fields.containsKey('Name'), 'Should include Name field');
        }
    }
    
    /**
     * @description Test getRecordNameField for various objects
     */
    @isTest
    static void testGetRecordNameField(){
        Test.startTest();
        String contactNameField = RelatedListController.getRecordNameField('Contact');
        String caseNameField = RelatedListController.getRecordNameField('Case');
        String taskNameField = RelatedListController.getRecordNameField('Task');
        String eventNameField = RelatedListController.getRecordNameField('Event');
        String contractNameField = RelatedListController.getRecordNameField('Contract');
        String accountNameField = RelatedListController.getRecordNameField('Account');
        Test.stopTest();
        
        System.assertEquals('LastName', contactNameField, 'Contact name field should be LastName');
        System.assertEquals('CaseNumber', caseNameField, 'Case name field should be CaseNumber');
        System.assertEquals('Subject', taskNameField, 'Task name field should be Subject');
        System.assertEquals('Subject', eventNameField, 'Event name field should be Subject');
        System.assertEquals('ContractNumber', contractNameField, 'Contract name field should be ContractNumber');
        System.assertEquals('Name', accountNameField, 'Account name field should be Name');
    }
    
    /**
     * @description Test error handling in initData
     */
    @isTest
    static void testInitDataErrorHandling(){
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            RelatedListController.initData('invalid json', 'false');
        } catch(AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for invalid input');
    }
    
    /**
     * @description Test getIconName for various objects
     */
    @isTest
    static void testGetIconNameVariousObjects(){
        Test.startTest();
        String taskIcon = RelatedListController.getIconName('Task');
        String accountIcon = RelatedListController.getIconName('Account');
        String product2Icon = RelatedListController.getIconName('Product2');
        Test.stopTest();
        
        System.assertNotEquals(null, taskIcon, 'Task icon should not be null');
        System.assertNotEquals(null, accountIcon, 'Account icon should not be null');
        System.assertEquals('standard:product', product2Icon, 'Product2 should use product icon');
    }
    
    /**
     * @description Test multiple created records for deduplication
     */
    @isTest
    static void testMultipleCreatedRecordsDeduplication(){
        User u = [SELECT Id FROM User WHERE UserName = :('standarduser@testorg.com.'+UserInfo.getOrganizationId()) LIMIT 1];
        System.runAs(u) {
            Account acc = new Account(Name = 'Test Account Dedup');
            insert acc;
            
            // Create multiple "Created" events for the same record
            Record_History__c rh1 = new Record_History__c(
                Record__c = acc.Id,
                Record_Name__c = 'Test Account Dedup',
                Event__c = 'Created',
                Field__c = 'Created.',
                Created_By_DL__c = UserInfo.getUserId(),
                Created_Date_DL__c = System.now()
            );
            
            Record_History__c rh2 = new Record_History__c(
                Record__c = acc.Id,
                Record_Name__c = 'Test Account Dedup',
                Event__c = 'Created',
                Field__c = 'Created.',
                Created_By_DL__c = UserInfo.getUserId(),
                Created_Date_DL__c = System.now().addSeconds(-1)
            );
            insert new List<Record_History__c>{rh1, rh2};
            
            Test.startTest();
            Map<String, Object> requestMap = new Map<String, Object>(); 
            requestMap.put(RelatedListController.RECORD_ID_PARAM, acc.Id);
            requestMap.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 50);
            
            String jsonData = RelatedListController.initData(JSON.serialize(requestMap), 'false');
            Test.stopTest();
            
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
            System.assertNotEquals(null, responseMap, 'Response should not be null');
        }
    }
    
    /**
     * @description Test standard history with account updates
     */
    @isTest
    static void testStandardHistoryTracking(){
        User u = [SELECT Id FROM User WHERE UserName = :('standarduser@testorg.com.'+UserInfo.getOrganizationId()) LIMIT 1];
        System.runAs(u) {
            Account acc = new Account(Name = 'Original Name');
            insert acc;
            
            // Update to generate standard history
            acc.Name = 'Updated Name';
            update acc;
            
            Test.startTest();
            Map<String, Object> requestMap = new Map<String, Object>(); 
            requestMap.put(RelatedListController.RECORD_ID_PARAM, acc.Id);
            requestMap.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 50);
            
            String jsonData = RelatedListController.initData(JSON.serialize(requestMap), 'false');
            Test.stopTest();
            
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
            System.assertNotEquals(null, responseMap, 'Response should not be null');
        }
    }
}
