/**
 * @description     test for Reusable Lookup Controller
 * @author          Mark Meyer
 * @date            09/27/2024
 */
@isTest
public class ReusableLookupControllerTest {

    /**
     * @description     test lookup
     */
    @isTest public static void testInit(){
        Account acc = new Account(Name = 'test');
        insert acc;
        Contact cnt = new Contact(LastName = 'test', AccountId = acc.Id);
        insert cnt;


        ReusableLookupController.SearchWrapper wrapper = new ReusableLookupController.SearchWrapper();
        wrapper.objectApiName = 'Contact';
        wrapper.fieldApiName = 'LastName';
        wrapper.otherFieldApiName = 'FirstName';
        wrapper.searchString = 't';
        wrapper.selectedRecordId = cnt.Id;
        wrapper.parentRecordId = acc.Id;
        wrapper.parentFieldApiName = 'AccountId';
        List<ReusableLookupController.ResultWrapper> results = ReusableLookupController.fetchRecords(JSON.serialize(wrapper));

        wrapper = new ReusableLookupController.SearchWrapper();
        wrapper.objectApiName = 'Contact';
        wrapper.fieldApiName = 'LastName';
        wrapper.otherFieldApiName = 'FirstName';
        wrapper.searchString = 't';
        wrapper.parentRecordId = acc.Id;
        wrapper.parentFieldApiName = 'AccountId';
        results = ReusableLookupController.fetchRecords(JSON.serialize(wrapper));

        wrapper = new ReusableLookupController.SearchWrapper();
        wrapper.objectApiName = 'Contact';
        wrapper.fieldApiName = 'LastName';
        wrapper.otherFieldApiName = 'FirstName';
        wrapper.searchString = 't';
        results = ReusableLookupController.fetchRecords(JSON.serialize(wrapper));
        results = ReusableLookupController.fetchRecords(null);
        System.assertEquals(null, results, 'Results size not set as expected');
    }
}