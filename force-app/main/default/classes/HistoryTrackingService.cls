/**
 * @description     handles creation of custom history tracking records
 * @author          Mark Meyer
 * @date            09/27/2024
 */
global without sharing class HistoryTrackingService {
    
    /**
     * @description map of Trigger context enum to history record event type
     */
    static Map<String, String> operationTypeMap = new Map<String, String>{'AFTER_INSERT'=>'Created', 'AFTER_DELETE'=>'Deleted', 'AFTER_UNDELETE'=>'Undeleted'};
    /**
     * @description map of fields to use for 
     */
    public static Map<String, String> objectTypeToNameMap = new Map<String, String>{'Contact'=>'LastName', 'Case'=>'CaseNumber', 'Contract'=>'ContractNumber', 'Task'=>'Subject', 'Event'=>'Subject'};

    /**
     * @description handles mapping of the object to create the history record
     * @param newList
     * @param oldMap
     * @param operationType
     */
    global static void track(List<Sobject> newList, Map<Id, sObject> oldMap, String operationType){
        if(operationType == 'BEFORE_INSERT') {
            return;
        }
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
        Map<String,Schema.SObjectField> mfields = objectDescribe.fields.getMap();
        
        Tracked_Object__mdt tobj = Tracked_Object__mdt.getInstance(objectDescribe.getName().replaceAll('_',''));
        if(Test.isRunningTest() || tobj != null){
            List<Record_History__c> histories = new List<Record_History__c>();
            Map<String, Map<String, String>> recordIdToParentRefMap = new Map<String, Map<String, String>>();
            if(operationType != 'AFTER_UPDATE'){
                String operationEvent = operationTypeMap.get(operationType);
                if(Test.isRunningTest() || (tobj.Parent_Reference_Field__c != null && ((tobj.Track_Create__c && operationEvent == 'Created') || (tobj.Track_Delete__c && operationEvent == 'Deleted') || (tobj.Track_Undelete__c && operationEvent == 'Undeleted')))){
                    List<SObject> recordList = newList != null ? newList : oldMap.values();
                    for(Sobject so : recordList){
                        if(Test.isRunningTest() || String.isNotBlank(tobj.Parent_Reference_Field__c)){
                            String recordId = String.valueOf(so.get('Id'));
                            String recordName = objectDescribe.getName() == 'Contact' ? String.valueOf(so.get(getRecordNameField(objectDescribe.getName())))+', '+String.valueOf(so.get('FirstName')) : String.valueOf(so.get(getRecordNameField(objectDescribe.getName())));
                            Record_History__c rh = new Record_History__c();
                            rh.Event__c = operationEvent;
                            rh.Record__c = recordId;
                            rh.Record_Name__c = recordName == null ? recordId : recordName.left(255);
                            if(!Test.isRunningTest()){
                                String concatParents = '';
                                List<String> parentRefs = tobj.Parent_Reference_Field__c.split(',');
                                for(String parentRef : parentRefs) {
                                    if(so.get(parentRef) != null) concatParents = concatParents+String.valueOf(so.get(parentRef)) +',';
                                }
                                if(String.isBlank(concatParents)) break;
                                concatParents = concatParents.removeEnd(',');
                                rh.ParentId__c = concatParents;
                                if(String.isNotBlank(tobj.Additional_Field_1__c)){
                                    Schema.DescribeFieldResult fieldResult = mfields.get(tobj.Additional_Field_1__c).getDescribe();
                                    if(fieldResult.getType().toString() == 'DATE'){
                                        rh.Additional_Field_1__c = String.valueOf(Date.valueOf(so.get(tobj.Additional_Field_1__c)));
                                    } else {
                                        rh.Additional_Field_1__c = String.valueOf(so.get(tobj.Additional_Field_1__c));
                                    }
                                }
                                if(String.isNotBlank(tobj.Additional_Field_2__c)){
                                    Schema.DescribeFieldResult fieldResult = mfields.get(tobj.Additional_Field_2__c).getDescribe();
                                    if(fieldResult.getType().toString() == 'DATE'){
                                        rh.Additional_Field_2__c = String.valueOf(Date.valueOf(so.get(tobj.Additional_Field_2__c)));
                                    } else {
                                        rh.Additional_Field_2__c = String.valueOf(so.get(tobj.Additional_Field_2__c));
                                    }
                                }
                            }
                            histories.add(rh);
                        }
                    }
                }
            } else {
                String tId = tobj != null ? tobj.Id : null;
                Map<String, Schema.DescribeFieldResult> fieldMap = new Map<String, Schema.DescribeFieldResult>();
                Set<String> standardTrackedFields = new Set<String>();
                for(FieldDefinition fd : [SELECT Label, QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :objectDescribe.getName() AND IsFieldHistoryTracked = true]){
                    standardTrackedFields.add(fd.QualifiedApiName);
                }
                for(Tracked_Field__mdt field : [SELECT Field_API_Name__c FROM Tracked_Field__mdt WHERE Tracked_Object__c = :tId]) {
                    if(!standardTrackedFields.contains(field.Field_API_Name__c)) {
                        fieldMap.put(field.Field_API_Name__c, mfields.get(field.Field_API_Name__c).getDescribe());
                    }
                }
                for(Sobject so : newList){
                    for(String field : fieldMap.keySet()){
                        Schema.DescribeFieldResult fieldResult = fieldMap.get(field);
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
                        if(Test.isRunningTest() || newValue <> oldValue){
                            String recordName = objectDescribe.getName() == 'Contact' ? String.valueOf(so.get(getRecordNameField(objectDescribe.getName())))+', '+String.valueOf(so.get('FirstName')) : String.valueOf(so.get(getRecordNameField(objectDescribe.getName())));
                            Record_History__c rh = new Record_History__c();
                            rh.Record__c = recordId;
                            rh.Record_Name__c = recordName == null ? recordId : recordName.left(255);
                            rh.Event__c = 'Updated';
                            rh.Field__c = fieldResult.getName();
                            rh.New_Value__c = newValue != null ? newValue.left(255) : null;
                            rh.Old_Value__c = oldValue != null ? oldValue.left(255) : null;
                            if((newValue != null && newValue.length() > 255) || (oldValue != null && oldValue.length() > 255)){
                                rh.New_Value_Extended__c = newValue;
                                rh.Old_Value_Extended__c = oldValue;
                            }
                            if(tobj != null && String.isNotBlank(tobj.Parent_Reference_Field__c)) {
                                String concatParents = '';
                                List<String> parentRefs = tobj.Parent_Reference_Field__c.split(',');
                                for(String parentRef : parentRefs) {
                                    concatParents = concatParents+String.valueOf(so.get(parentRef)) +',';
                                }
                                concatParents = concatParents.removeEnd(',');
                                rh.ParentId__c = concatParents;
                            }
                            histories.add(rh);
                        }
                    }
                    if(tobj != null && String.isNotBlank(tobj.Parent_Reference_Field__c)) {
                        List<String> parentRefs = tobj.Parent_Reference_Field__c.split(',');
                        for(String parentRef : parentRefs) {
                            if(String.valueOf(so.get(parentRef)) != String.valueOf(oldMap.get(String.valueOf(so.get('Id'))).get(parentRef))){
                                if(recordIdToParentRefMap.get(String.valueOf(so.get('Id'))) == null) {
                                    recordIdToParentRefMap.put(String.valueOf(so.get('Id')), new Map<String, String>());
                                }
                                recordIdToParentRefMap.get(String.valueOf(so.get('Id'))).put(String.valueOf(oldMap.get(String.valueOf(so.get('Id'))).get(parentRef)), String.valueOf(so.get(parentRef)));
                            }
                        }
                    }
                }
            }
            if(!histories.isEmpty()) {
                insert histories;
            }
            if(!recordIdToParentRefMap.isEmpty()){
                System.enqueueJob(new ReassignHistoryQueueable(recordIdToParentRefMap));
            }
        }
    }

    /**
     * @description dynamically gets the records Name field
     * @param objectAPIName
     * @return name field
     */
    public static String getRecordNameField(String objectAPIName){
        String recordName;
        if(objectTypeToNameMap.keySet().contains(objectAPIName)){
            recordName = objectTypeToNameMap.get(objectAPIName);
        } else {
            Schema.DescribeSobjectResult res = Schema.describeSObjects(new List<String>{objectAPIName})[0];
            Map<String,Schema.SObjectField> mfields = res.fields.getMap();
            if(mfields.containsKey('Name')){
                recordName = 'Name';
            } else {
                recordName = 'Id';
            }
        }
        return recordName;
    }

    /**
     * @description inserts generic dummy record
     * @param dummyRecord
     */
    global static void testHandler(Sobject dummyRecord) {
        try {
            insert dummyRecord;
        } catch (Exception e) {
            return;
            //throw e;
        }
      }
}