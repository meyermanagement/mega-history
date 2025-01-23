/**
 * @description     Controller for the Import LWC
 * @author          Mark Meyer
 * @date            01/15/2025
 */
public with sharing class ImportController {

    /**
     * @description     get all tracking records
     * @return List of TrackingWrapper
     */
    @AuraEnabled(cacheable=true)
    public static List<TrackingWrapper> getRecords() {
        try {
            Map<String, TrackingWrapper> wrapperMap = Test.isRunningTest() ? new Map<String, TrackingWrapper>{'Account'=>new TrackingWrapper()} : new Map<String, TrackingWrapper>();
            for(Tracked_Object__mdt to : [SELECT Id, MasterLabel, DeveloperName, Additional_Field_1__c, Additional_Field_2__c, Parent_Reference_Field__c, Track_Create__c, Track_Delete__c, Track_Undelete__c FROM Tracked_Object__mdt WITH USER_MODE ORDER BY MasterLabel]){
                TrackingWrapper wrapper = new TrackingWrapper();
                wrapper.objectName = to.MasterLabel;
                wrapperMap.put(to.MasterLabel, wrapper);
            }
            Map<String, Schema.DescribeSObjectResult> objectDescribeMap = new Map<String, Schema.DescribeSObjectResult>();
            for(Schema.DescribeSObjectResult result : Schema.describeSObjects(new List<String>(wrapperMap.keySet()))){
                TrackingWrapper wrapper = wrapperMap.get(result.getName());
                wrapper.objectLabel = result.getLabel();
                wrapperMap.put(result.getName(), wrapper);
            }
            return wrapperMap.values();
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     get Object Details
     * @param objectApiName
     * @return ObjectDetailsWrapper
     */
    @AuraEnabled
    public static ObjectDetailsWrapper getObjectDetails(String objectApiName) {
        try {
            ObjectDetailsWrapper wrapper = new ObjectDetailsWrapper();
            wrapper.objectApiName = objectApiName;
            for(Schema.DescribeSObjectResult result : Schema.describeSObjects(new List<String>{objectApiName})){
                wrapper.objectLabel = result.getLabel();
            }
            wrapper.objectNameField = RelatedListController.getRecordNameField(objectApiName);
            for(Tracked_Object__mdt to : [SELECT Id, MasterLabel, DeveloperName, Additional_Field_1__c, Additional_Field_2__c, Parent_Reference_Field__c, Track_Create__c, Track_Delete__c, Track_Undelete__c FROM Tracked_Object__mdt WHERE MasterLabel = :objectApiName WITH USER_MODE ORDER BY MasterLabel]){
                wrapper.objectSecondaryField = to.Additional_Field_1__c;
            }
            wrapper.objectIcon = RelatedListController.getIconName(objectApiName);
            return wrapper;
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     get count of records
     * @param objectApiName
     * @return Integer
     */
    @AuraEnabled
    public static Integer getRecordCount(String objectApiName) {
        try {
            String query = 'SELECT Id FROM '+ String.escapeSingleQuotes(objectApiName)+' ORDER BY CreatedDate DESC LIMIT 50000';
            Map<String, Object> binds = new Map<String, Object>{ };
            List<SObject> results = Database.queryWithBinds(query, binds, AccessLevel.USER_MODE);
            return results.size();
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     get results of object
     * @param objectApiName
     * @return List<ResultsWrapper>
     */
    @AuraEnabled
    public static List<ResultsWrapper> getSelectedObjectRecords(String objectApiName) {
        try {
            List<String> parentRefs = Test.isRunningTest() ? new List<String>{'ParentId'} : new List<String>();
            for(Tracked_Object__mdt to : [SELECT Id, Parent_Reference_Field__c FROM Tracked_Object__mdt WHERE MasterLabel = :objectApiName WITH USER_MODE ORDER BY MasterLabel]){
                parentRefs = to.Parent_Reference_Field__c.split(',');
            }
            String query = 'SELECT Id, ';
            if(!parentRefs.isEmpty()){
                for(String parentRef : parentRefs){
                    query = query + String.escapeSingleQuotes(parentRef) +', ';
                }
            }
            String fieldAPIName = RelatedListController.getRecordNameField(objectApiName);
            query = query + String.escapeSingleQuotes(fieldAPIName) +' ';
            System.debug(query);
            query = query + ' FROM '+ String.escapeSingleQuotes(objectApiName)+' ORDER BY CreatedDate DESC LIMIT 50000';
            System.debug(query);
            List<ResultsWrapper> returnWrapperList = new List<ResultsWrapper>();
            Map<String, Object> binds = new Map<String, Object>{ };
            for(SObject s : Database.queryWithBinds(query, binds, AccessLevel.USER_MODE)) {
                ResultsWrapper wrap = new ResultsWrapper();
                wrap.mainField = (String)s.get(fieldAPIName);
                if(!parentRefs.isEmpty()){
                    String concatParents = '';
                    List<String> parentIds = new List<String>();
                    for(String parentRef : parentRefs){
                        if(s.get(parentRef) != null) parentIds.add((String)s.get(parentRef));
                    }
                    for(String parentId : parentIds){
                        concatParents = concatParents + parentId +',';
                    }
                    concatParents = concatParents.removeEnd(',');
                    wrap.parentIds = concatParents;
                }
                wrap.id = (String)s.get('id');
                returnWrapperList.add(wrap);
            }
            return returnWrapperList;
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     generate History Records
     * @param records
     * @return Integer
     */
    @AuraEnabled
    public static Integer generateHistoryRecords(String records) {
        try {
            List<Record_History__c> histories = new List<Record_History__c>();
            List<Object> recordList = (List<Object>)JSON.deserializeUntyped(records); 
            System.debug(recordList);
            for(Object rec : recordList){
                Map<String, Object> recMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(rec));
                System.debug(recMap);
                Record_History__c hist = new Record_History__c();
                for(String recKey : recMap.keySet()){
                    System.debug(recKey);
                    if(recKey.contains('megatools__')){
                        String fieldKey = recKey.substring(recKey.indexOf('megatools__'), recKey.length());
                        if(fieldKey.contains('Date')){
                            hist.put(fieldKey, DateTime.ValueofGmt(String.valueOf(recMap.get(recKey)).replace('T', ' ')));
                        } else {
                            hist.put(fieldKey, String.valueOf(recMap.get(recKey)));
                        }
                    }
                }
                histories.add(hist);
            }
            if(Record_History__c.SObjectType.getDescribe().isCreateable()  && 
                Schema.SObjectType.Record_History__c.fields.Created_By_DL__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Created_Date_DL__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Old_Value__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Old_Value_Extended__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.New_Value__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.New_Value_Extended__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.ParentId__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Event__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Record__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Record_Name__c.isCreateable()){
                insert histories;
            }
            return histories.size();
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}