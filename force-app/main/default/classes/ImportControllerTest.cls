/**
 * @description     test for Import Controller
 * @author          Mark Meyer
 * @date            09/27/2024
 */
@isTest
public class ImportControllerTest {

    /**
     * @description     test all methods
     */
    @isTest public static void testInit(){
        Account acc = new Account(Name = 'test');
        insert acc;
        Account acc1 = new Account(Name = 'test2');
        insert acc1;
        Contact cnt = new Contact(LastName = 'test', AccountId = acc.Id);
        insert cnt;
        List<TrackingWrapper> wrapper = ImportController.getRecords();
        ObjectDetailsWrapper objectDetails = ImportController.getObjectDetails('Account');
        Integer recordCount = ImportController.getRecordCount('Account');
        List<ResultsWrapper> results = ImportController.getSelectedObjectRecords('Account');
        Record_History__c rh = new Record_History__c();
        rh.Record__c = cnt.Id;
        rh.Record_Name__c = cnt.LastName;
        rh.ParentId__c = acc.Id;
        rh.Event__c = 'Updated';
        recordCount = ImportController.generateHistoryRecords(JSON.serialize(new List<Record_History__c>{rh}));
    }
}