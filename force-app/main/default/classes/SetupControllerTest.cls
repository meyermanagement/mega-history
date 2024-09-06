@isTest
public class SetupControllerTest {
    
    @isTest public static void testInit(){
        SetupController.checkMetadataAPIConnection();
        SetupController.checkPermissionAssignment();
        SetupController.checkRecordTracking();
        SetupController.checkViews();
        SetupController.getSessionIdFromVFPage();
        SetupController.getOrgURL();
    }
}