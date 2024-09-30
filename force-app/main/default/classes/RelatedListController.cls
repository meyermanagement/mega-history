/**
 * @description     Controller for the Related List LWC
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class RelatedListController {

    /**
     * @description     Custom Exception for RelatedListController
     */
    public class RelatedListControllerException extends Exception {}

    /**
     * @description     Param for recordId
     */
    public static final String RECORD_ID_PARAM = 'recordId';
    /**
     * @description     Param for numberOfRecords
     */
    public static final String NUMBER_OF_RECORDS_PARAM = 'numberOfRecords';
    /**
     * @description     Param for sobjectApiName
     */
    public static final String SOBJECT_API_NAME_PARAM = 'sobjectApiName';
    /**
     * @description     Param for sobjectLabel
     */
    public static final String SOBJECT_LABEL_PARAM = 'sobjectLabel';
    /**
     * @description     Param for sobjectLabelPlural
     */
    public static final String SOBJECT_LABEL_PLURAL_PARAM = 'sobjectLabelPlural';
    /**
     * @description     Param for parentRelationshipApiName
     */
    public static final String PARENT_RELATIONSHIP_API_NAME_PARAM = 'parentRelationshipApiName';
    /**
     * @description     Param for relatedFieldApiName
     */
    public static final String RELATED_FIELD_API_NAME_PARAM = 'relatedFieldApiName';
    /**
     * @description     Param for sortedDirection
     */
    public static final String SORTED_DIRECTION_PARAM = 'sortedDirection';
    /**
     * @description     Param for sortedBy
     */
    public static final String SORTED_BY_PARAM = 'sortedBy';
    /**
     * @description     Param for childRecords
     */
    public static final String CHILD_RECORDS_PARAM = 'childRecords';
    /**
     * @description     Param for records
     */
    public static final String RECORDS_PARAM = 'records';
    /**
     * @description     Param for iconName
     */
    public static final String ICON_NAME_PARAM = 'iconName';
    /**
     * @description     Param for fullView
     */
    public static final String FULL_VIEW_PARAM = 'fullView';
    /**
     * @description     Param for superUser
     */
    public static final String SUPER_USER_PARAM = 'superUser';

    /**
     * @description     Get and process data for the Related List LWC
     * @param jsonData
     * @return responseMap
     */
    @AuraEnabled
    public static String initData(String jsonData){
        try{
            system.debug(jsonData);
            Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
            Map<String, Object> responseMap = new Map<String, Object>();
            
            String recordId = (String)requestMap.get(RECORD_ID_PARAM);
            Integer numberOfRecords = (Integer)requestMap.get(NUMBER_OF_RECORDS_PARAM);
            Schema.DescribeSObjectResult objectDescribe = Id.valueOf(recordId).getSObjectType().getDescribe();
            String sobjectApiName = objectDescribe.getName();
            List<HistoryWrapper> customRecords = getCustomHistory(recordId, numberOfRecords);
            List<HistoryWrapper> standardRecords = getStandardHistory(recordId, objectDescribe, numberOfRecords);
            List<HistoryWrapper> results = mergeLists(customRecords, standardRecords);
            results = scrubFields(results, objectDescribe);
            Map<String, List<HistoryWrapper>> resultsMap = splitLists(results);
            responseMap.put(CHILD_RECORDS_PARAM, resultsMap.get('Child'));
            responseMap.put(RECORDS_PARAM, resultsMap.get('Adult'));
            responseMap.put(ICON_NAME_PARAM, getIconName(sobjectApiName));
            responseMap.put(SOBJECT_LABEL_PARAM, objectDescribe.getLabel() + ' History');
            responseMap.put(SOBJECT_LABEL_PLURAL_PARAM, objectDescribe.getLabel() + ' History');
            Boolean isSuperUser = false;
            for(PermissionSetAssignment assignment : [SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Mega_History_Super_Admin' AND AssigneeId = :UserInfo.getUserId()]){
                isSuperUser = true;
            }
            responseMap.put(SUPER_USER_PARAM, String.valueOf(isSuperUser));
            Initialization__c initialization = Initialization__c.getOrgDefaults();
            if(!initialization.initialized__c){
                initialization.Name = 'Default Initialization';
                initialization.initialized__c = true;
                upsert as user initialization;
            }
            return JSON.serialize(responseMap);
        } catch (Exception e){
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description     Get custom History Records
     * @param recordId
     * @param numberOfRecords
     * @return List of History Wrappers
     */
    private static List<HistoryWrapper> getCustomHistory(String recordId, Integer numberOfRecords){
        List<HistoryWrapper> wrappers = new List<HistoryWrapper>();
        String query = 'SELECT Id, Name, Additional_Field_1__c, Additional_Field_2__c, CreatedById, Created_By_DL__c, Created_By_Formula__c, Created_Date_DL__c,'+
                        'Created_Date_Formula__c, Event__c, Field__c, New_Value__c, New_Value_Extended__c, Old_Value__c, Old_Value_Extended__c,'+
                        'ParentId__c, Record__c, Record_Name__c FROM Record_History__c WHERE Record__c = :recordId'+
                        ' OR ParentId__c = :recordId'+
                        ' ORDER BY Created_Date_Formula__c DESC'+
                        ' Limit '+numberOfRecords;
        for(Sobject sobj : Database.query(String.escapeSingleQuotes(query))){
            wrappers.add(createWrapper(sobj, true));
        }
        return wrappers;
	}

    /**
     * @description     Get standard History Records
     * @param recordId
     * @param objectDescribe
     * @param numberOfRecords
     * @return List of History Wrappers
     */
    private static List<HistoryWrapper> getStandardHistory(String recordId, Schema.DescribeSObjectResult objectDescribe, Integer numberOfRecords){
        List<HistoryWrapper> wrappers = new List<HistoryWrapper>();
        String objectHistoryFieldAPIName;
        String objectHistoryName;
        String apiName = objectDescribe.getName();
        if(objectDescribe.isCustom()) {
            apiName = apiName.removeEnd('__c');
            objectHistoryName = apiName+'__history';
            objectHistoryFieldAPIName = 'ParentId';
        } else {
            Set<String> fieldHistoryObjects = new Set<String>{'Opportunity', 'Activity'};
            if(fieldHistoryObjects.contains(apiName)) {
                objectHistoryName = apiName+'FieldHistory';
            }
            else objectHistoryName = apiName+'History';
            objectHistoryFieldAPIName = apiName+'Id';
        }
        String query = 'SELECT '+objectHistoryFieldAPIName+', Id, Field, NewValue, OldValue, CreatedDate, CreatedBy.Name, CreatedById FROM '+
                        objectHistoryName+' WHERE '+
                        objectHistoryFieldAPIName+' = :recordId'+
                        ' ORDER BY CreatedDate DESC'+
                        ' Limit '+numberOfRecords;
        for(Sobject sobj : Database.query(String.escapeSingleQuotes(query))){
            HistoryWrapper wrapp = createWrapper(sobj, false);
            wrapp.objectAPIName = apiName;
            wrapp.objectLabel = objectDescribe.getLabel();
            wrapp.recordId = String.valueOf(sobj.get(objectHistoryFieldAPIName));
            wrappers.add(wrapp);
        }
        return wrappers;
	}

    /**
     * @description     merge the 2 lists
     * @param customrecords
     * @param standardrecords
     * @return List of History Wrappers
     */
    private static List<HistoryWrapper> mergeLists(List<HistoryWrapper> customrecords, List<HistoryWrapper> standardrecords){
        List<HistoryWrapper> wrappers = new List<HistoryWrapper>();
        wrappers.addAll(customrecords);
        wrappers.addAll(standardrecords);
        return wrappers;
    }  

    /**
     * @description     adjust some of the wrapper fields depending on permissions and type of field
     * @param wrappers
     * @param objectDescribe
     * @return List of History Wrappers
     */
    private static List<HistoryWrapper> scrubFields(List<HistoryWrapper> wrappers, Schema.DescribeSObjectResult objectDescribe){
        Boolean canViewEncryptedText = ![SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.PermissionsViewEncryptedData = true].isEmpty();
        Map<String,Schema.SObjectField> mfields = objectDescribe.fields.getMap();
        for(HistoryWrapper wrapp : wrappers){
            if(wrapp.event == 'Updated' && wrapp.field != 'Created.'){
                if(wrapp.field != 'RecordType'){
                    Schema.DescribeFieldResult fieldResult = mfields.get(wrapp.field).getDescribe();
                    if(fieldResult.getType() == Schema.DisplayType.ENCRYPTEDSTRING && !canViewEncryptedText){
                        String mask ='*';
                        wrapp.oldValue = mask.repeat(wrapp.oldValue.length());
                        wrapp.oldValueFull = mask.repeat(wrapp.oldValueFull.length());
                        wrapp.newValue = mask.repeat(wrapp.newValue.length());
                        wrapp.newValueFull = mask.repeat(wrapp.newValueFull.length());
                    }
                    wrapp.fieldLabel = fieldResult.getLabel();
                } else {
                    wrapp.fieldLabel = 'Record Type';
                }
            }
        }
        return wrappers;
    }  

    /**
     * @description     separate the 2 lists based on if they are child record history or not
     * @param wrappers
     * @return Map of List of History Wrappers
     */
    private static Map<String, List<HistoryWrapper>> splitLists(List<HistoryWrapper> wrappers){
        Map<String, List<HistoryWrapper>> historyMap = new Map<String, List<HistoryWrapper>>{'Child'=>new List<HistoryWrapper>(), 'Adult'=>new List<HistoryWrapper>()};
        for(HistoryWrapper wrapp : wrappers){
            if(wrapp.event == 'Updated'){
                historyMap.get('Adult').add(wrapp);
            } else {
                historyMap.get('Child').add(wrapp);
            }
        }
        return historyMap;
    }
    
    /**
     * @description     Maps the HistoryWrapper instance depending on if it is a custom or standard record
     * @param record
     * @param customRecord
     * @return HistoryWrapper
     */
    @TestVisible
    private static HistoryWrapper createWrapper(SObject record, Boolean customRecord){
        HistoryWrapper wrapper = new HistoryWrapper();
        wrapper.historyId = String.valueOf(record.get('Id'));
        if(customRecord){
            Schema.DescribeSObjectResult objectDescribe = Id.valueOf(String.valueOf(record.get('Record__c'))).getSObjectType().getDescribe();
            wrapper.objectAPIName = objectDescribe.getName();
            wrapper.objectLabel = objectDescribe.getLabel();
            wrapper.recordId = String.valueOf(record.get('Record__c'));
            wrapper.recordName = String.valueOf(record.get('Record_Name__c'));
            wrapper.parentId = String.valueOf(record.get('ParentId__c'));
            wrapper.event = String.valueOf(record.get('Event__c'));
            wrapper.field = String.valueOf(record.get('Field__c'));
            wrapper.oldValue = String.valueOf(record.get('Old_Value__c'));
            wrapper.oldValueFull = String.valueOf(record.get('Old_Value_Extended__c'));
            wrapper.newValue = String.valueOf(record.get('New_Value__c'));
            wrapper.newValueFull = String.valueOf(record.get('New_Value_Extended__c'));
            wrapper.additionalField1 = String.valueOf(record.get('Additional_Field_1__c'));
            wrapper.additionalField2 = String.valueOf(record.get('Additional_Field_2__c'));
            wrapper.createdDate = DateTime.valueOf(record.get('Created_Date_Formula__c'));
            wrapper.createdByName = String.valueOf(record.get('Created_By_Formula__c'));
            wrapper.createdByURL = '/one/one.app?#/sObject/'+String.valueOf(record.get('CreatedById'))+'/view';
            wrapper.isCustom = true;
        } else {
            wrapper.event = 'Updated';
            if(!Test.isRunningTest()) {
                if(String.valueOf(record.get('Field')) == 'created'){
                    wrapper.field = 'Created.';
                    wrapper.fieldLabel = 'Created.';
                } else {
                    wrapper.field = String.valueOf(record.get('Field'));
                }
                wrapper.oldValue = String.valueOf(record.get('OldValue'));
                wrapper.oldValueFull = String.valueOf(record.get('OldValue'));
                wrapper.newValue = String.valueOf(record.get('NewValue'));
                wrapper.newValueFull = String.valueOf(record.get('NewValue'));
                wrapper.createdByName = String.valueOf(record.getSobject('CreatedBy').get('Name'));
                wrapper.createdByURL = '/one/one.app?#/sObject/'+String.valueOf(record.get('CreatedById'))+'/view';
            }
            wrapper.createdDate = DateTime.valueOf(record.get('CreatedDate'));
            wrapper.createdById = String.valueOf(record.get('CreatedById'));
        }
        return wrapper;
    }  
        
    /**
     * @description     Determine the name of the parent relationship
     * @param recordId
     * @param childSobjectApiName
     * @param relatedFieldApiName
     * @return name 
     */
    @TestVisible
    private static String getParentRelationshipName(Id recordId, String childSobjectApiName, String relatedFieldApiName){
        Schema.DescribeSObjectResult descrRes = recordId.getSObjectType().getDescribe();
        String name;
        for (Schema.ChildRelationship cr: descrRes.getChildRelationships()){ 
            if(cr.getChildSObject().getDescribe().getName() == childSobjectApiName
            && cr.getField().getDescribe().getName() == relatedFieldApiName){
          	 	name = cr.getRelationshipName();
                break;
            }
        }     
        return name;
    }      
    
    /**
     * @description     gets the name of the icon depending on the object
     * @param sobjectApiName
     * @return iconName 
     */
    @AuraEnabled
    public static String getIconName(String sobjectApiName){
        String iconName;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.DescribeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { 
            tabDesc.addAll(tsr.getTabs()); 
        }

        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sobjectApiName == tr.getSobjectName() ) {
                if( tr.isCustom() ) {
                    iconDesc.addAll(tr.getIcons());
                } else {
                    iconName = 'standard:' + sobjectApiName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                iconName = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
        return iconName;
    } 
    
    /**
     * @description     gets the history record to edit
     * @param recordId
     * @param historyId
     * @param isRelated
     * @return history record 
     */
    @AuraEnabled
    public static Record_History__c getHistoryRecord(String recordId, String historyId, Boolean isRelated){
        try {
            List<Record_History__c> histList = [SELECT Id, Name, Additional_Field_1__c, Additional_Field_2__c, CreatedById, Created_By_DL__c, Created_By_Formula__c, Created_Date_DL__c,Created_Date_Formula__c, Event__c, Field__c, New_Value__c, New_Value_Extended__c, Old_Value__c, Old_Value_Extended__c,ParentId__c, Record__c, Record_Name__c FROM Record_History__c WHERE Id = :historyId];
            Record_History__c histRec;
            if(!histList.isEmpty()){
                histRec = histList[0];
            } else {
                histRec = new Record_History__c();
                if(isRelated){
                    histRec.ParentId__c = recordId;
                    histRec.Event__c = 'Created';
                    histRec.Created_By_DL__c = UserInfo.getUserId();
                    histRec.Created_Date_DL__c = System.now();
                } else {
                    histRec.Record__c = recordId;
                    histRec.Event__c = 'Updated';
                    histRec.Created_By_DL__c = UserInfo.getUserId();
                    histRec.Created_Date_DL__c = System.now();
                }
            }  
            return histRec;
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     saves the history record on edit or create
     * @param historyString
     */
    @AuraEnabled
    public static void saveHistory(String historyString){
        try {
            Record_History__c rh = (Record_History__c)JSON.deserialize(historyString, Record_History__c.class);
            if(String.isBlank(rh.Created_By_DL__c)){
                rh.Created_By_DL__c = null;
            }
            if(rh.Created_Date_DL__c == null){
                rh.Created_Date_DL__c = null;
            }
            Id recordId = rh.Record__c != null ? Id.valueOf(rh.Record__c) : null;
            if(rh.Event__c != 'Updated' && String.isBlank(rh.Record_Name__c)) {
                throw new RelatedListControllerException('Record Name is required');
            }
            upsert as user rh;
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     gets fields for a given object based on the recordid
     * @param recordId
     * @return fieldMap
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getFields(String recordId){
        try {
            Map<String, String> fieldMap = new Map<String, String>();
            Schema.DescribeSObjectResult objectDescribe = Id.valueOf(recordId).getSObjectType().getDescribe();
            Map<String,Schema.SObjectField> mfields = objectDescribe.fields.getMap();
            for(Schema.SObjectField soField : mfields.values()){
                Schema.DescribeFieldResult fieldResult = soField.getDescribe();
                if(fieldResult.isUpdateable() && !fieldResult.isDeprecatedAndHidden()){
                    fieldMap.put(fieldResult.getName(), fieldResult.getLabel());
                }
            }
            return fieldMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}