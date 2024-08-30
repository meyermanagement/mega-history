public with sharing class MetaDataParams {
    public String getPackageXml() {
        if (Deployed)
          // package.xml for undeploy
          return '<?xml version="1.0" encoding="UTF-8"?>' +
            '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '<version>' +
            componentApiVersion +
            '</version>' +
            '</Package>';
        else
          // package.xml for deploy
          return '<?xml version="1.0" encoding="UTF-8"?>' +
            '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '<types>' +
            '<members>' +
            RollupTriggerName +
            '</members>' +
            '<name>ApexTrigger</name>' +
            '</types>' +
            '<types>' +
            '<members>' +
            RollupTriggerTestName +
            '</members>' +
            '<name>ApexClass</name>' +
            '</types>' +
            (ParentTriggerRequired
              ? ('<types>' +
                '<members>' +
                RollupParentTriggerName +
                '</members>' +
                '<name>ApexTrigger</name>' +
                '</types>' +
                '<types>' +
                '<members>' +
                RollupParentTriggerTestName +
                '</members>' +
                '<name>ApexClass</name>' +
                '</types>')
              : '') +
            '<version>' +
            componentApiVersion +
            '</version>' +
            '</Package>';
      }
    
      public String getDestructiveChangesXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
          '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' +
          '<types>' +
          '<members>' +
          RollupTriggerName +
          '</members>' +
          '<name>ApexTrigger</name>' +
          '</types>' +
          '<types>' +
          '<members>' +
          RollupTriggerTestName +
          '</members>' +
          '<name>ApexClass</name>' +
          '</types>' +
          (ParentTriggerRequired
            ? ('<types>' +
              '<members>' +
              RollupParentTriggerName +
              '</members>' +
              '<name>ApexTrigger</name>' +
              '</types>' +
              '<types>' +
              '<members>' +
              RollupParentTriggerTestName +
              '</members>' +
              '<name>ApexClass</name>' +
              '</types>')
            : '') +
          '<version>' +
          componentApiVersion +
          '</version>' +
          '</Package>';
      }
    
      /**
       * CHILD OBJECT CODE
       **/
    
      public String getTriggerTestCodeMetadata() {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
          '<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">' +
          '<apiVersion>' +
          componentApiVersion +
          '</apiVersion>' +
          '<status>Active</status>' +
          '</ApexClass>';
      }
    
      public String getTriggerTestCode() {
        if (Deployed && RollupTriggerTest != null)
          // Display currently deployed code for confirmation
          return RollupTriggerTest.Body;
        else {
          // Deploy generated code
          return '/**\n' +
            ' * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)\n' +
            ' **/\n' +
            '@IsTest\n' +
            'private class ' +
            RollupTriggerTestName +
            '\n' +
            '{\n' +
            (RollupSummary.TestCodeSeeAllData == true
              ? '    @IsTest(SeeAllData=true)\n'
              : '    @IsTest\n') +
            '    private static void testTrigger()\n' +
            '    {\n' +
            ((RollupSummary.TestCode != null &&
              RollupSummary.TestCode.length() > 0)
              ? RollupSummary.TestCode + '\n'
              : ('        // Force the ' +
                RollupTriggerName +
                ' to be invoked, fails the test if org config or other Apex code prevents this.\n' +
                '        ' +
                Utilities.classPrefix() +
                'RollupService.testHandler(new ' +
                RollupSummary.ChildObject +
                '());\n')) +
            '    }\n' +
            '}';
        }
      }
    
      public String getTriggerCodeMetadata() {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
          '<ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">' +
          '<apiVersion>' +
          componentApiVersion +
          '</apiVersion>' +
          '<status>Active</status>' +
          '</ApexTrigger>';
      }
    
      public String getTriggerCode() {
        if (Deployed && RollupTrigger != null) {
          // Display currently deployed code for confirmation
          return RollupTrigger.Body;
        } else {
          // Namespace?
          String namespace = Utilities.namespace();
          // Deploy generated code
          return '/**\n' +
            ' * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)\n' +
            ' **/\n' +
            'trigger ' +
            RollupTriggerName +
            ' on ' +
            RollupSummary.ChildObject +
            '\n' +
            '    (before delete, before insert, before update, after delete, after insert, after undelete, after update)\n' +
            '{\n' +
            '    ' +
            (namespace.length() > 0 ? namespace + '.' : '') +
            'RollupService.triggerHandler(' +
            RollupSummary.ChildObject +
            '.SObjectType);\n' +
            '}\n';
        }
      }
}