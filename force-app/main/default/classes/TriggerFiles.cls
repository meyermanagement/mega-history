/**
 * @description     Class containing metadata file configuration for Triggers
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class TriggerFiles {

    private static String componentApiVersion = '61.0';

    /**
     * @description     generates the package.xml file
     */
    public static String getPackageXml(MetadataWrapper wrapp, Boolean includeMembers) {
        String triggerName = wrapp.mdName;
        String className = wrapp.mdName.removeEnd('Trigger');
        className = className + '_Test';
          // package.xml for deploy
          if(includeMembers){
            return '<?xml version="1.0" encoding="UTF-8"?>' +
              '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' +
              '<types>' +
              '<members>' +
              triggerName +
              '</members>' +
              '<name>ApexTrigger</name>' +
              '</types>' +
              '<types>' +
              '<members>' +
              className +
              '</members>' +
              '<name>ApexClass</name>' +
              '</types>' +
              '<version>' +
              componentApiVersion +
              '</version>' +
              '</Package>';
          } else {
            return '<?xml version="1.0" encoding="UTF-8"?>' +
              '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' +
              '<version>' +
              componentApiVersion +
              '</version>' +
              '</Package>';
          }
      }
    
      /**
     * @description     generates the destructivechanges.xml file
     */
    public static String getDestructiveChangesXml(MetadataWrapper wrapp) {
        String triggerName = wrapp.mdName;
        String className = wrapp.mdName.removeEnd('Trigger');
        className = className + '_Test';
        return '<?xml version="1.0" encoding="UTF-8"?>' +
          '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' +
          '<types>' +
          '<members>' +
          triggerName +
          '</members>' +
          '<name>ApexTrigger</name>' +
          '</types>' +
          '<types>' +
          '<members>' +
          className +
          '</members>' +
          '<name>ApexClass</name>' +
          '</types>' +
          '<version>' +
          componentApiVersion +
          '</version>' +
          '</Package>';
      }
    
      /**
     * @description     generates the trigger test code xml file
     */
    public static String getTriggerTestCodeMetadata() {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
          '<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">' +
          '<apiVersion>' +
          componentApiVersion +
          '</apiVersion>' +
          '<status>Active</status>' +
          '</ApexClass>';
      }
    
       /**
     * @description     generates the trigger test code file
     */
    public static String getTriggerTestCode(MetadataWrapper wrapp) {
        String triggerName = wrapp.mdName;
        String className = wrapp.mdName.removeEnd('Trigger');
        className = className + '_Test';
        // Deploy generated code
        return '/**\n' +
        ' * Auto Generated and Deployed by the MegaHistory package (megahistory)\n' +
        ' **/\n' +
        '@IsTest\n' +
        'private class ' +
        className +
        '\n' +
        '{\n' +
        '    @IsTest\n' +
        '    private static void testTrigger()\n' +
        '    {\n' +
        '        // Force the ' +
            triggerName +
            ' to be invoked, fails the test if org config or other Apex code prevents this.\n' +
            '        ' +
            'megahistory.HistoryTrackingService.testHandler(new ' +
            wrapp.mdObject +
            '());\n' +
        '    }\n' +
        '}';
      }
    
       /**
     * @description     generates the trigger code xml file
     */
    public static String getTriggerCodeMetadata() {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
        '<ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">' +
        '<apiVersion>' +
        componentApiVersion +
        '</apiVersion>' +
        '<status>Active</status>' +
        '</ApexTrigger>';
    }
    

     /**
     * @description     generates the trigger code file
     */
    public static String getTriggerCode(MetadataWrapper wrapp) {
        // Namespace?
        // Deploy generated code
        return '/**\n' +
        ' * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)\n' +
        ' **/\n' +
        'trigger ' +
        wrapp.mdName +
        ' on ' +
        wrapp.mdObject +
        '\n' +
        '    (before insert, after insert, after update, after delete, after undelete)\n' +
        '{\n' +
        '    ' +
        'megahistory.HistoryTrackingService.track(Trigger.new, Trigger.oldMap, Trigger.OperationType.toString());\n' +
        '}\n';
    }
}