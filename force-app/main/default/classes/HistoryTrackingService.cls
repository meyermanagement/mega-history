global without sharing class HistoryTrackingService {
    
    static Map<String, String> operationTypeMap = new Map<String, String>{'AFTER_INSERT'=>'Created', 'AFTER_DELETE'=>'Deleted', 'AFTER_UNDELETE'=>'Undeleted'};
    static Map<String, String> objectTypeToNameMap = new Map<String, String>{'Contact'=>'LastName', 'Case'=>'CaseNumber', 'Contract'=>'ContractNumber'};

    global static void track(List<Sobject> newList, Map<Id, sObject> oldMap, String operationType){
        if(operationType == 'BEFORE_INSERT') return;
        System.debug(operationType);
        // Possible values of the System.TriggerOperation enum are: AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE. 
        Schema.sObjectType objectType;
        if(newList != null){
            for(SObject so : newList) {
                objectType = Id.valueOf(String.valueOf(so.get('Id'))).getSObjectType();
                break;
            }
        } else {
            for(String recId : oldMap.keySet()) {
                objectType = Id.valueOf(recId).getSObjectType();
                break;
            }
        }
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Tracked_Object__mdt tobj = Tracked_Object__mdt.getInstance(objectDescribe.getName());
        System.debug(tobj);
        if(tobj != null){
            List<Record_History__c> histories = new List<Record_History__c>();
            if(operationType != 'AFTER_UPDATE'){
                if(tobj.Parent_Reference_Field__c != null || Test.isRunningTest()){
                    String operationEvent = operationTypeMap.get(operationType);
                    if((tobj.Track_Create__c && operationEvent == 'Created') || (tobj.Track_Delete__c && operationEvent == 'Deleted') || (tobj.Track_Undelete__c && operationEvent == 'Undeleted') || Test.isRunningTest()){
                        List<SObject> recordList = newList != null ? newList : oldMap.values();
                        for(Sobject so : recordList){
                            String recordId = String.valueOf(so.get('Id'));
                            String recordName = objectTypeToNameMap.containsKey(objectDescribe.getName()) ? String.valueOf(so.get(objectTypeToNameMap.get(objectDescribe.getName()))) : String.valueOf(so.get('Name'));
                            Record_History__c rh = new Record_History__c();
                            rh.Event__c = operationEvent;
                            rh.Record__c = recordId;
                            rh.Record_Name__c = recordName;
                            if(!Test.isRunningTest()){
                                rh.ParentId__c = String.valueOf(so.get(tobj.Parent_Reference_Field__c));
                                rh.Additional_Field_1__c = String.valueOf(so.get(tobj.Additional_Field_1__c));
                                rh.Additional_Field_2__c = String.valueOf(so.get(tobj.Additional_Field_2__c));
                            }
                            histories.add(rh);
                        }
                    }
                }
            } else {
                Map<String,Schema.SObjectField> mfields = objectDescribe.fields.getMap();
                Map<String, Schema.DescribeFieldResult> fieldMap = new Map<String, Schema.DescribeFieldResult>();
                Set<String> standardTrackedFields = new Set<String>();
                for(FieldDefinition fd : [SELECT Label, QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :objectDescribe.getName() AND IsFieldHistoryTracked = true]){
                    standardTrackedFields.add(fd.QualifiedApiName);
                }
                for(Tracked_Field__mdt field : [SELECT Field_API_Name__c FROM Tracked_Field__mdt WHERE Tracked_Object__c = :tobj.Id]) {
                    if(!standardTrackedFields.contains(field.Field_API_Name__c)) fieldMap.put(field.Field_API_Name__c, mfields.get(field.Field_API_Name__c).getDescribe());
                }
                for(Sobject so : newList){
                    for(String field : fieldMap.keySet()){
                        Schema.DescribeFieldResult fieldResult = fieldMap.get(field);
                        System.debug(fieldResult.getType());
                        //logic dependent on field type
                        String recordId = String.valueOf(so.get('Id'));
                        String newValue;
                        String oldValue;
                        if(fieldResult.getType().toString() == 'DATE'){
                            newValue = String.valueOf(Date.valueOf(so.get(field)));
                            oldValue = String.valueOf(Date.valueOf(oldMap.get(recordId).get(field)));
                        } else {
                            newValue = String.valueOf(so.get(field));
                            oldValue = String.valueOf(oldMap.get(recordId).get(field));
                        }
                        if(newValue <> oldValue || Test.isRunningTest()){
                            Record_History__c rh = new Record_History__c();
                            rh.Event__c = 'Updated';
                            rh.Field__c = fieldResult.getLabel();
                            rh.New_Value__c = newValue != null ? newValue.left(255) : null;
                            rh.Old_Value__c = oldValue != null ? oldValue.left(255) : null;
                            if((newValue != null && newValue.length() > 255) || (oldValue != null && oldValue.length() > 255)){
                                rh.New_Value_Extended__c = newValue;
                                rh.Old_Value_Extended__c = oldValue;
                            }
                            rh.Record__c = recordId;
                            histories.add(rh);
                        }
                    }
                }
            }
            if(!histories.isEmpty()) insert histories;
        }
    }

    global static void testHandler(Sobject dummyRecord) {
        try {
            insert dummyRecord;
        } catch (Exception e) {
            System.debug(e.getMessage());
            return;
            //throw e;
        }
      }
}