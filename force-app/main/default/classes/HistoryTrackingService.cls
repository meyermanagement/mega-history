public without sharing class HistoryTrackingService {
    
    static Map<String, String> operationTypeMap = new Map<String, String>{'AFTER_INSERT'=>'Create', 'AFTER_DELETE'=>'Delete', 'AFTER_UNDELETE'=>'Undelete'};
    public static void track(List<Sobject> newList, Map<Id, sObject> oldMap, System.TriggerOperation operationType){
        System.debug(operationType.toString());
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
        List<Record_History__c> histories = new List<Record_History__c>();
        if(operationType.toString() != 'AFTER_UPDATE'){
            if(tobj.Parent_Reference_Field__c != null){
                String operationEvent = operationTypeMap.get(operationType.toString());
                if((tobj.Track_Create__c && operationEvent == 'Create') || (tobj.Track_Delete__c && operationEvent == 'Delete') || (tobj.Track_Undelete__c && operationEvent == 'Undelete')){
                    List<SObject> recordList = newList != null ? newList : oldMap.values();
                    for(Sobject so : recordList){
                        String recordId = String.valueOf(so.get('Id'));
                        String recordName = so.get('Name') != null ? String.valueOf(so.get('Name')) : null;
                        Record_History__c rh = new Record_History__c();
                        rh.Event__c = operationEvent;
                        rh.Record__c = recordId;
                        rh.Record_Name__c = recordName;
                        rh.ParentId__c = String.valueOf(so.get(tobj.Parent_Reference_Field__c));
                        histories.add(rh);
                    }
                }
            }
        } else {
            Map<String,Schema.SObjectField> mfields = objectDescribe.fields.getMap();
            Map<String, Schema.DescribeFieldResult> fieldMap = new Map<String, Schema.DescribeFieldResult>();
            for(Tracked_Field__mdt field : [SELECT Field_API_Name__c FROM Tracked_Field__mdt WHERE Tracked_Object__c = :tobj.Id]) {
                fieldMap.put(field.Field_API_Name__c, mfields.get(field.Field_API_Name__c).getDescribe());
            }
            for(Sobject so : newList){
                for(String field : fieldMap.keySet()){
                    Schema.DescribeFieldResult fieldResult = fieldMap.get(field);
                    //logic dependent on field type
                    String recordId = String.valueOf(so.get('Id'));
                    String newValue = String.valueOf(so.get(field));
                    String oldValue = String.valueOf(oldMap.get(recordId).get(field));
                    if(newValue <> oldValue){
                        Record_History__c rh = new Record_History__c();
                        rh.Event__c = 'Updated';
                        rh.Field__c = fieldResult.getLabel();
                        rh.New_Value__c = newValue.left(255);
                        rh.Old_Value__c = oldValue.left(255);
                        if(newValue.length() > 255 || oldValue.length() > 255){
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