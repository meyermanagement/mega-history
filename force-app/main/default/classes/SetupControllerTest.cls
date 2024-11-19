/**
 * @description     test for Setup Controller
 * @author          Mark Meyer
 * @date            09/27/2024
 */
@isTest
public class SetupControllerTest {
    
    /**
     * @description     test all methods
     */
    @isTest public static void testInit(){
        SetupController.checkMetadataAPIConnection();
        SetupController.checkPermissionAssignment();
        SetupController.checkRecordTracking();
        SetupController.checkViews();
        String sessionId = SetupController.getSessionIdFromVFPage();
        SetupController.getOrgURL();
        System.assertEquals(null, sessionId, 'sessionId not set as expected');
    }
}