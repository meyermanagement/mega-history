/**
 * @description     Test to create custom history records
 * @author          Mark Meyer
 * @date            09/27/2024
 */
@isTest
public class HistoryTrackingServiceTest {
    
    /**
     * @description WHEN record is created
     *              THEN history is generated
     */
    @isTest static void testTrack(){
        List<Account> accts = new List<Account>();
        Account acc = new Account(Name='Test');
        accts.add(acc);
        insert accts;

        HistoryTrackingService.track(accts, null, 'AFTER_INSERT');
        HistoryTrackingService.track(accts, new Map<Id, SObject>(accts), 'AFTER_UPDATE');
        HistoryTrackingService.track(null, new Map<Id, SObject>(accts), 'AFTER_DELETE');
        HistoryTrackingService.testHandler(new Account());
    }
}