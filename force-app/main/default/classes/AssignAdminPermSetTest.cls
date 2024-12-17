/**
 * @description     DEPRECATED - Test to Assign super admin access to installing user of package
 * @author          Mark Meyer
 * @date            09/27/2024
 */
@isTest
public class AssignAdminPermSetTest {

    // /**
    //  * @description WHEN install script is run
    //  *              THEN permission set is assigned
    //  */
    // @isTest
    // static void testInstallScript() {
    //     AssignAdminPermSet postinstall = new AssignAdminPermSet();
    //     Test.testInstall(postinstall, null);
    //     List<PermissionSetAssignment> a = [Select id from PermissionSetAssignment where AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'MEGA_History_Super_Admin'];
    //     System.assertEquals(1, a.size(), 'Permission Set not assigned correctly');
    // }

    // /**
    //  * @description WHEN install script is run
    //  *              THEN permission set is assigned
    //  */
    // @isTest
    // static void testSendEmail() {
    //     AssignAdminPermSet.send(UserInfo.getUserId(), 'Test', 'Test');
    //     System.assertEquals(UserInfo.getUserId(), UserInfo.getUserId(), 'UserId not set as expected');
    // }
}