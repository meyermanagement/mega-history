@isTest
public class AssignAdminPermSetTest {
    @isTest
    static void testInstallScript() {
        AssignAdminPermSet postinstall = new AssignAdminPermSet();
        Test.testInstall(postinstall, null);
        List<PermissionSetAssignment> a = [Select id from PermissionSetAssignment where AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'MEGA_History_Super_Admin'];
        System.assertEquals(1, a.size(), 'Permission Set not assigned correctly');
    }
}