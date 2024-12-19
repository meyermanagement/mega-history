/**
 * @description     Controller for the Related List LWC
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class RelatedListController {

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
     * @description     Param for disabledRecords
     */
    public static final String DISABLED_RECORDS_PARAM = 'disabledRecords';
    /**
     * @description     Set of Activity History Objects
     */
    public static Set<String> activityHistoryObjects = new Set<String>{'Task', 'Event'};
    /**
     * @description map of fields to use for 
     */
    public static Map<String, String> objectTypeToNameMap = new Map<String, String>{'Contact'=>'LastName', 'Case'=>'CaseNumber', 'Contract'=>'ContractNumber', 'Task'=>'Subject', 'Event'=>'Subject'};

    /**
     * @description     Custom Exception for RelatedListController
     */
    public class RelatedListControllerException extends Exception {}

    /**
     * @description     Get and process data for the Related List LWC
     * @param jsonData
     * @param isCustomOnly
     * @return responseMap
     */
    @AuraEnabled
    public static String initData(String jsonData, String isCustomOnly){
        try{
            Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
            Map<String, Object> responseMap = new Map<String, Object>();
            
            String recordId = (String)requestMap.get(RECORD_ID_PARAM);
            Integer numberOfRecords = (Integer)requestMap.get(NUMBER_OF_RECORDS_PARAM);
            Schema.DescribeSObjectResult objectDescribe = Id.valueOf(recordId).getSObjectType().getDescribe();
            String sobjectApiName = objectDescribe.getName();
            Map<String, Tracked_Object__mdt> tobjMap = new Map<String, Tracked_Object__mdt>();
            for(Tracked_Object__mdt to : Tracked_Object__mdt.getAll().values()){
                tobjMap.put(to.MasterLabel, to);
            }
            List<HistoryWrapper> customRecords = getCustomHistory(recordId, numberOfRecords);
            List<HistoryWrapper> standardRecords = new List<HistoryWrapper>();
            List<HistoryWrapper> disabledRecords = new List<HistoryWrapper>();
            for(HistoryWrapper st : getStandardHistory(recordId, objectDescribe, numberOfRecords, tobjMap)){
                if(st.historyId != null && st.historyId == 'NOTALLOWED'){
                    disabledRecords.add(st);
                } else {
                    standardRecords.add(st);
                }
            }
            responseMap.put(DISABLED_RECORDS_PARAM, disabledRecords);
            List<HistoryWrapper> results = mergeLists(customRecords, isCustomOnly == 'true' ? new List<HistoryWrapper>() : standardRecords);
            Map<String, Schema.DescribeSObjectResult> objectDescribeMap = getObjectDescribes(results);
            results = scrubFields(results, objectDescribeMap);
            Map<String, List<HistoryWrapper>> resultsMap = splitLists(recordId, results);
            responseMap.put(CHILD_RECORDS_PARAM, resultsMap.get('Child'));
            responseMap.put(RECORDS_PARAM, resultsMap.get('Adult'));
            responseMap.put(ICON_NAME_PARAM, getIconName(sobjectApiName));
            responseMap.put(SOBJECT_LABEL_PARAM, objectDescribe.getLabel() + ' History');
            responseMap.put(SOBJECT_LABEL_PLURAL_PARAM, objectDescribe.getLabel() + ' History');
            Boolean isSuperUser = false;
            for(PermissionSetAssignment assignment : [SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Mega_History_Super_Admin' AND AssigneeId = :UserInfo.getUserId() WITH USER_MODE]){
                isSuperUser = true;
            }
            responseMap.put(SUPER_USER_PARAM, String.valueOf(isSuperUser));
            Initialization__c initialization = Initialization__c.getOrgDefaults();
            if(!initialization.initialized__c){
                initialization.Name = 'Default Initialization';
                initialization.initialized__c = true;
                if(Initialization__c.SObjectType.getDescribe().isCreateable() && Initialization__c.SObjectType.getDescribe().isUpdateable() && 
                    Schema.SObjectType.Initialization__c.fields.Name.isCreateable() && Schema.SObjectType.Initialization__c.fields.initialized__c.isCreateable() && 
                    Schema.SObjectType.Initialization__c.fields.Name.isUpdateable() && Schema.SObjectType.Initialization__c.fields.initialized__c.isUpdateable()) {
                    upsert initialization;
                }
                
            }
            return JSON.serialize(responseMap);
        } catch (Exception e){
            System.debug(LoggingLevel.DEBUG, e.getMessage());
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
                        ' OR ParentId__c LIKE ' + '\'%' + String.escapeSingleQuotes(recordId) + '%\''+
                        ' ORDER BY Created_Date_Formula__c DESC';
        Map<String, Object> binds = new Map<String, Object>{'recordId' => recordId };
        try{
            for(SObject sobj : Database.queryWithBinds(query, binds, AccessLevel.USER_MODE)) {
                wrappers.add(createWrapper(sobj, 'Record_History__c'));
            }
        } catch(Exception e){
            System.debug(e.getMessage());
        }
        return wrappers;
	}

    /**
     * @description     Get standard History Records
     * @param recordId
     * @param objectDescribe
     * @param numberOfRecords
     * @param tobjMap
     * @return List of History Wrappers
     */
    private static List<HistoryWrapper> getStandardHistory(String recordId, Schema.DescribeSObjectResult objectDescribe, Integer numberOfRecords, Map<String, Tracked_Object__mdt> tobjMap){
        List<HistoryWrapper> wrappers = new List<HistoryWrapper>();        
        List<Schema.ChildRelationship> children = objectDescribe.getChildRelationships();
        for(Schema.ChildRelationship child : children){
            Schema.DescribeSObjectResult childObjectDescribe = child.getChildSObject().getDescribe();
            String childApiName = childObjectDescribe.getName();
            String childReferenceField = String.valueOf(child.getField());
            if(tobjMap.get(childApiName) != null && tobjMap.get(childApiName).Parent_Reference_Field__c != null && tobjMap.get(childApiName).Parent_Reference_Field__c.contains(childReferenceField)){
                if(!activityHistoryObjects.contains(childApiName)){
                    String childQuery = createQuery(null, childObjectDescribe, tobjMap.get(childApiName), recordId, childReferenceField, true);
                    try{
                        Map<String, Object> binds = new Map<String, Object>{'recordId' => recordId };
                        for(SObject sobj : Database.queryWithBinds(String.escapeSingleQuotes(childQuery), binds, AccessLevel.USER_MODE)) {
                            for(Sobject hist : sobj.getSobjects('Histories')){
                                HistoryWrapper wrapp = createWrapper(hist, 'Histories');
                                wrapp.objectAPIName = childApiName;
                                wrapp.objectLabel = childObjectDescribe.getLabel();
                                String nameField = getRecordNameField(childApiName);
                                wrapp.recordName = childApiName == 'Contact' ? String.valueOf(sobj.get(nameField))+', '+String.valueOf(sobj.get('FirstName')) : String.valueOf(sobj.get(nameField));
                                wrapp.recordId = String.valueOf(sobj.get('Id'));
                                wrapp.recordURL = '/one/one.app?#/sObject/'+wrapp.recordId+'/view';
                                wrappers.add(wrapp);
                            }
                        }
                    } catch(QueryException e){
                        System.debug(LoggingLevel.DEBUG, e.getMessage());
                        HistoryWrapper wrapp = new HistoryWrapper();
                        wrapp.historyId='NOTALLOWED';
                        wrapp.parentId = 'NOTALLOWED';
                        wrapp.objectAPIName=childApiName;
                        wrapp.objectLabel=childObjectDescribe.getLabel();
                        wrappers.add(wrapp);
                    }
                } else {
                    HistoryWrapper wrapp = new HistoryWrapper();
                    wrapp.historyId='NOTALLOWED';
                    wrapp.parentId = 'NOTALLOWED';
                    wrapp.objectAPIName=childApiName;
                    wrapp.objectLabel=childObjectDescribe.getLabel();
                    wrappers.add(wrapp);
                }
            }
        }
        
        String query = createQuery(recordId, objectDescribe, tobjMap.get(objectDescribe.getName()), null, null, true);
        
        try{
            Map<String, Object> binds = new Map<String, Object>{'recordId' => recordId };
            for(SObject sobj : Database.queryWithBinds(query, binds, AccessLevel.USER_MODE)) {
                for(Sobject hist : sobj.getSobjects('Histories')){
                    HistoryWrapper wrapp = createWrapper(hist, 'Histories');
                    wrapp.objectAPIName = objectDescribe.getName();
                    wrapp.objectLabel = objectDescribe.getLabel();
                    wrapp.recordId = String.valueOf(sobj.get('Id'));
                    wrappers.add(wrapp);
                }
            }
        } catch(Exception e){
            System.debug(LoggingLevel.DEBUG, e.getMessage());
            HistoryWrapper wrapp = new HistoryWrapper();
            wrapp.historyId='NOTALLOWED';
            wrapp.objectAPIName=objectDescribe.getName();
            wrapp.objectLabel=objectDescribe.getLabel();
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
     * @description     getSobjectDesbribes for each object
     * @param resultRecords
     * @return Map of objectApiName to DescribeSobjectResult
     */
    private static Map<String, Schema.DescribeSObjectResult> getObjectDescribes(List<HistoryWrapper> resultRecords){
        Map<String, Schema.DescribeSObjectResult> objectDescribeMap = new Map<String, Schema.DescribeSObjectResult>();
        Set<String> objectAPINames = new Set<String>();
        for(HistoryWrapper wrapper : resultRecords){
            if(String.isNotBlank(wrapper.objectAPIName)) {
                objectAPINames.add(wrapper.objectAPIName);
            }
        }
        for(Schema.DescribeSObjectResult result : Schema.describeSObjects(new List<String>(objectAPINames))){
            objectDescribeMap.put(result.getName(), result);
        }
        return objectDescribeMap;
    }  

    /**
     * @description     adjust some of the wrapper fields depending on permissions and type of field
     * @param wrappers
     * @param objectDescribeMap
     * @return List of History Wrappers
     */
    private static List<HistoryWrapper> scrubFields(List<HistoryWrapper> wrappers, Map<String, Schema.DescribeSObjectResult> objectDescribeMap){
        Boolean canViewEncryptedText = ![SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.PermissionsViewEncryptedData = true].isEmpty();
        List<HistoryWrapper> results = new List<HistoryWrapper>();
        for(HistoryWrapper wrapp : wrappers){
            if(wrapp.event == 'Updated' && wrapp.field != 'Created.'){
                if(wrapp.field != 'RecordType' && wrapp.field != 'RecordTypeId'){
                    Schema.SObjectField sobjField = objectDescribeMap.get(wrapp.objectAPIName).fields.getMap().get(wrapp.field);
                    if(sobjField != null){
                        Schema.DescribeFieldResult fieldResult = sobjField.getDescribe();
                        if(fieldResult.isAccessible()){
                            if(fieldResult.getType() == Schema.DisplayType.ENCRYPTEDSTRING && !canViewEncryptedText){
                                String mask ='*';
                                wrapp.oldValue = wrapp.oldValue == null ? null : mask.repeat(wrapp.oldValue.length());
                                wrapp.oldValueFull = wrapp.oldValueFull == null ? null : mask.repeat(wrapp.oldValueFull.length());
                                wrapp.newValue = wrapp.newValue == null ? null : mask.repeat(wrapp.newValue.length());
                                wrapp.newValueFull = wrapp.newValueFull == null ? null : mask.repeat(wrapp.newValueFull.length());
                            }
                            wrapp.fieldLabel = fieldResult.getLabel();
                            results.add(wrapp);
                        }
                    }
                } else {
                    wrapp.fieldLabel = 'Record Type';
                }
            } else {
                results.add(wrapp);
            }
            
        }
        return results;
    }  

    /**
     * @description     separate the 2 lists based on if they are child record history or not
     * @param recordId
     * @param wrappers
     * @return Map of List of History Wrappers
     */
    private static Map<String, List<HistoryWrapper>> splitLists(String recordId, List<HistoryWrapper> wrappers){
        Set<String> duplicateCreateRecords = new Set<String>();
        Map<String, List<HistoryWrapper>> historyMap = new Map<String, List<HistoryWrapper>>{'Child'=>new List<HistoryWrapper>(), 'Adult'=>new List<HistoryWrapper>()};
        for(HistoryWrapper wrapp : wrappers){
            if(wrapp.recordId == recordId){
                if(wrapp.event == 'Created'){
                    if(!duplicateCreateRecords.contains(wrapp.recordId)){
                        historyMap.get('Adult').add(wrapp);
                        duplicateCreateRecords.add(wrapp.recordId);
                    }
                } else {
                    historyMap.get('Adult').add(wrapp);
                }
            } else if(wrapp.recordId != recordId) {
                if(wrapp.event == 'Created'){
                    if(!duplicateCreateRecords.contains(wrapp.recordId)){
                        historyMap.get('Child').add(wrapp);
                        duplicateCreateRecords.add(wrapp.recordId);
                    }
                } else {
                    historyMap.get('Child').add(wrapp);
                }
                
            }
        }
        return historyMap;
    }
    
    /**
     * @description     Maps the HistoryWrapper instance depending on if it is a custom or standard record
     * @param record
     * @param objectName
     * @return HistoryWrapper
     */
    @TestVisible
    private static HistoryWrapper createWrapper(SObject record, String objectName){
        HistoryWrapper wrapper = new HistoryWrapper();
        wrapper.historyId = String.valueOf(record.get('Id'));
        if(objectName == 'Record_History__c'){
            if(record.get('Record__c') != null){
                Schema.DescribeSObjectResult objectDescribe = Id.valueOf(String.valueOf(record.get('Record__c'))).getSObjectType().getDescribe();
                wrapper.objectAPIName = objectDescribe.getName();
                wrapper.objectLabel = objectDescribe.getLabel();
            }
            wrapper.recordId = String.valueOf(record.get('Record__c'));
            wrapper.recordName = String.valueOf(record.get('Record_Name__c'));
            wrapper.recordURL = '/one/one.app?#/sObject/'+wrapper.recordId+'/view';
            wrapper.parentId = String.valueOf(record.get('ParentId__c'));
            wrapper.event = String.valueOf(record.get('Event__c'));
            wrapper.field = wrapper.event != 'Updated' ? wrapper.event : String.valueOf(record.get('Field__c'));
            wrapper.fieldLabel = wrapper.field;
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
                    wrapper.event = 'Created';
                } else if(String.valueOf(record.get('Field')) == 'Owner') {
                    wrapper.field = 'OwnerId';
                } else if(String.valueOf(record.get('Field')) == 'Account') {
                    wrapper.field = 'AccountId';
                } else if(String.valueOf(record.get('Field')) == 'Contact') {
                    wrapper.field = 'ContactId';
                } else if(String.valueOf(record.get('Field')) == 'RecordType') {
                    wrapper.field = 'RecordTypeId';
                } else if(String.valueOf(record.get('Field')) == 'TextName') {
                    wrapper.field = 'Name';
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
     * @description     dynamically creates queries based on inputs
     * @param objectName
     * @return query
     */
    @TestVisible
    private static String getNameField(String objectName){
        String nameField = 'Name';
        if(objectTypeToNameMap.get(objectName) != null) {
            nameField = objectTypeToNameMap.get(objectName);
        }
        return nameField;
    }

    /**
     * @description     dynamically creates queries based on inputs
     * @param objectDescribe
     * @return query
     */
    private static String getObjectHistorySubQuery(Schema.DescribeSObjectResult objectDescribe){
        String subQuery = '(SELECT ';
        if(activityHistoryObjects.contains(objectDescribe.getName())){
            subQuery += 'FieldName, NewValueText, OldValueText, CreatedDate, CreatedBy.Name, CreatedById FROM ActivityFieldHistories';
        } else {
            subQuery += 'Field, NewValue, OldValue, CreatedDate, CreatedBy.Name, CreatedById FROM Histories';
        }
        subQuery += ')';
        return subQuery;
    }
    
    /**
     * @description     dynamically creates queries based on inputs
     * @param recordId
     * @param objectDescribe
     * @param tobj
     * @param parentId
     * @param childReferenceField
     * @param checkPermission
     * @return query
     */
    private static String createQuery(String recordId, Schema.DescribeSObjectResult objectDescribe, Tracked_Object__mdt tobj, String parentId, String childReferenceField, Boolean checkPermission){
        Map<String,Schema.SObjectField> mfields = objectDescribe.fields.getMap();
        String objectName = objectDescribe.getName();
        String objectHistoryName = 'Histories';
        if(!objectDescribe.isCustom() && activityHistoryObjects.contains(objectName)) {
            objectHistoryName = 'ActivityFieldHistories';
        }
        String query = 'SELECT Id,';
        String recordNameField = getRecordNameField(objectName);
        if(objectName == 'Contact'){
            query += recordNameField+',FirstName,';
        } else if(recordNameField != 'Id') {
            query += recordNameField+',';
        }
        List<String> parentRefs = new List<String>();
        if(tobj != null && String.isNotBlank(tobj.Parent_Reference_Field__c)){
            parentRefs = tobj.Parent_Reference_Field__c.split(',');
            for(String parentRef : parentRefs){
                System.debug(parentRef);
                Schema.SObjectField sobjField = mfields.get(parentRef);
                if(sobjField != null){
                    System.debug(sobjField);
                    Schema.DescribeFieldResult fieldResult = sobjField.getDescribe();
                    if(!checkPermission || fieldResult.isAccessible()){
                        query+= parentRef+',';
                    }
                }
            }
        }
        query += getObjectHistorySubQuery(objectDescribe);
        query = query.removeEnd(',');
        query += ' FROM ';
        query += objectName;
        if(recordId != null || parentId != null) {
            query +=' WHERE ';
            if(recordId != null && parentId != null){
                System.debug(childReferenceField);
                query +='Id = :recordId AND '+childReferenceField+' = :recordId';
            } else if(recordId != null) {
                query += 'Id = :recordId';
            } else {
                query += childReferenceField+' = :recordId';
            }
        }
        return query;
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
        if(sobjectApiName == 'Task'){
            iconName = 'standard:' + sobjectApiName.toLowerCase();
        }
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
        if(iconName == null){
            iconName = 'standard:entity';
        }
        if(iconName == ('standard:product2')){
            iconName = 'standard:product';
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
            List<Record_History__c> histList = new List<Record_History__c>();
            try{
                histList = [SELECT Id, Name, Additional_Field_1__c, Additional_Field_2__c, CreatedById, Created_By_DL__c, Created_By_DL__r.Name, Created_By_Formula__c, Created_Date_DL__c,Created_Date_Formula__c, Event__c, Field__c, New_Value__c, New_Value_Extended__c, Old_Value__c, Old_Value_Extended__c,ParentId__c, Record__c, Record_Name__c FROM Record_History__c WHERE Id = :historyId WITH USER_MODE];
            } catch (Exception e){
                System.debug(e.getMessage());
            }
            Record_History__c histRec;
            if(!histList.isEmpty()){
                Boolean canViewEncryptedText = ![SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.PermissionsViewEncryptedData = true].isEmpty();
                histRec = histList[0];
                if(histRec.Event__c == 'Updated' && histRec.Field__c != 'Created.' && histRec.Field__c != 'RecordType' && histRec.Field__c != 'RecordTypeId'){
                    Schema.sObjectType objectType = Id.valueOf(histRec.Record__c).getSObjectType();
                    Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                    Map<String,Schema.SObjectField> mfields = objectDescribe.fields.getMap();
                    Schema.SObjectField sobjField = mfields.get(histRec.Field__c);
                    if(sobjField != null){
                        Schema.DescribeFieldResult fieldResult = sobjField.getDescribe();
                        if(fieldResult.getType() == Schema.DisplayType.ENCRYPTEDSTRING && !canViewEncryptedText){
                            String mask ='*';
                            histRec.Old_Value__c = histRec.Old_Value__c == null ? null : mask.repeat(histRec.Old_Value__c.length());
                            histRec.Old_Value_Extended__c = histRec.Old_Value_Extended__c == null ? null : mask.repeat(histRec.Old_Value_Extended__c.length());
                            histRec.New_Value__c = histRec.New_Value__c == null ? null : mask.repeat(histRec.New_Value__c.length());
                            histRec.New_Value_Extended__c = histRec.New_Value_Extended__c == null ? null : mask.repeat(histRec.New_Value_Extended__c.length());
                        }
                    }
                }
            } else {
                histRec = new Record_History__c();
                if(isRelated){
                    histRec.ParentId__c = recordId;
                    histRec.Event__c = 'Created';
                    histRec.Created_By_DL__c = UserInfo.getUserId();
                    histRec.Created_Date_DL__c = System.now();
                } else {
                    Schema.sObjectType objectType = Id.valueOf(recordId).getSObjectType();
                    Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                    Map<String,Schema.SObjectField> mfields = objectDescribe.fields.getMap();
                    String objectName = objectDescribe.getName();
                    String nameField = getRecordNameField(objectName);
                    Tracked_Object__mdt tobj = Tracked_Object__mdt.getInstance(objectName.replaceAll('_',''));
                    Map<String, Object> binds = new Map<String, Object>{'recordId' => recordId };
                    Sobject sobj = Database.queryWithBinds(createQuery(recordId, objectDescribe, tobj, null, null, false), binds, AccessLevel.SYSTEM_MODE)[0];
                    System.debug(sobj);
                    if(tobj != null && String.isNotBlank(tobj.Parent_Reference_Field__c)){
                        String concatParents = '';
                        for(String parentRef : tobj.Parent_Reference_Field__c.split(',')) {
                            System.debug(parentRef);
                            try{
                                Schema.SObjectField sobjField = mfields.get(parentRef);
                                String fieldValue = HistoryTrackingService.getFieldFromSobject(sobj, parentRef);
                                if(sobjField != null && String.isNotBlank(fieldValue)){
                                    concatParents = concatParents+fieldValue +',';
                                }
                            } catch (Exception e) {
                                System.debug(e.getMessage());
                            }
                        }
                        concatParents = concatParents.removeEnd(',');
                        histRec.ParentId__c = concatParents;
                    }
                    histRec.Record__c = recordId;
                    System.debug(sobj.get(nameField));
                    histRec.Record_Name__c = objectName == 'Contact' ? String.valueOf(sobj.get(nameField))+', '+String.valueOf(sobj.get('FirstName')) : String.valueOf(sobj.get(nameField));
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
            if(rh.Event__c != 'Updated' && String.isBlank(rh.Record_Name__c)) {
                throw new RelatedListControllerException('Record Name is required');
            }
            if(Record_History__c.SObjectType.getDescribe().isCreateable() && Record_History__c.SObjectType.getDescribe().isUpdateable() && 
                Schema.SObjectType.Record_History__c.fields.Created_By_DL__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Created_Date_DL__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Old_Value__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Old_Value_Extended__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.New_Value__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.New_Value_Extended__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.ParentId__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Event__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Record__c.isCreateable() && 
                Schema.SObjectType.Record_History__c.fields.Record_Name__c.isCreateable() &&
                Schema.SObjectType.Record_History__c.fields.Created_By_DL__c.isUpdateable() && 
                Schema.SObjectType.Record_History__c.fields.Created_Date_DL__c.isUpdateable() && 
                Schema.SObjectType.Record_History__c.fields.Old_Value__c.isUpdateable() && 
                Schema.SObjectType.Record_History__c.fields.Old_Value_Extended__c.isUpdateable() && 
                Schema.SObjectType.Record_History__c.fields.New_Value__c.isUpdateable() && 
                Schema.SObjectType.Record_History__c.fields.New_Value_Extended__c.isUpdateable() && 
                Schema.SObjectType.Record_History__c.fields.ParentId__c.isUpdateable() && 
                Schema.SObjectType.Record_History__c.fields.Event__c.isUpdateable() && 
                Schema.SObjectType.Record_History__c.fields.Record__c.isUpdateable() && 
                Schema.SObjectType.Record_History__c.fields.Record_Name__c.isUpdateable()) {
                upsert rh;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     gets fields for a given object based on the recordid
     * @param recordId
     * @return fieldMap
     */
    @AuraEnabled
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
}