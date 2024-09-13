public with sharing class RelatedListController {
    public static final String RECORD_ID_PARAM = 'recordId';
    public static final String NUMBER_OF_RECORDS_PARAM = 'numberOfRecords';
    public static final String SOBJECT_API_NAME_PARAM = 'sobjectApiName';
    public static final String SOBJECT_LABEL_PARAM = 'sobjectLabel';
    public static final String SOBJECT_LABEL_PLURAL_PARAM = 'sobjectLabelPlural';
    public static final String PARENT_RELATIONSHIP_API_NAME_PARAM = 'parentRelationshipApiName';
    public static final String RELATED_FIELD_API_NAME_PARAM = 'relatedFieldApiName';
    public static final String SORTED_DIRECTION_PARAM = 'sortedDirection';
    public static final String SORTED_BY_PARAM = 'sortedBy';
    public static final String RECORDS_PARAM = 'records';
    public static final String ICON_NAME_PARAM = 'iconName';
    public static final String FULL_VIEW_PARAM = 'fullView';
    public static final String SUPER_USER_PARAM = 'superUser';

    @AuraEnabled
    public static String initData(String jsonData){
        try{
            system.debug(jsonData);
            Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
            Map<String, Object> responseMap = new Map<String, Object>();
            
            String recordId = (String)requestMap.get(RECORD_ID_PARAM);
            Schema.DescribeSObjectResult objectDescribe = Id.valueOf(recordId).getSObjectType().getDescribe();
            String sobjectApiName = objectDescribe.getName();
            List<HistoryWrapper> customRecords = getCustomHistory(recordId);
            List<HistoryWrapper> standardRecords = getStandardHistory(recordId, objectDescribe);
            List<HistoryWrapper> results = mergeLists(customRecords, standardRecords);
            System.debug(results);
            responseMap.put(RECORDS_PARAM, results);
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
                upsert initialization;
            }
            return JSON.serialize(responseMap);
        } catch (Exception e){
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static List<HistoryWrapper> getCustomHistory(String recordId){
        System.debug(recordId);
        List<HistoryWrapper> wrappers = new List<HistoryWrapper>();
        String query = 'SELECT Id, Name, Additional_Field_1__c, Additional_Field_2__c, CreatedById, Created_By_DL__c, Created_By_Formula__c, Created_Date_DL__c,'+
                        'Created_Date_Formula__c, Event__c, Field__c, New_Value__c, New_Value_Extended__c, Old_Value__c, Old_Value_Extended__c,'+
                        'ParentId__c, Record__c, Record_Name__c FROM Record_History__c WHERE Record__c = :recordId'+
                        ' OR ParentId__c = :recordId'+
                        ' ORDER BY Created_Date_Formula__c DESC'+
                        ' Limit 5000';
        for(Sobject sobj : Database.query(String.escapeSingleQuotes(query))){
            wrappers.add(createWrapper(sobj, true));
        }
        return wrappers;
	}

    private static List<HistoryWrapper> getStandardHistory(String recordId, Schema.DescribeSObjectResult objectDescribe){
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
            if(fieldHistoryObjects.contains(apiName)) objectHistoryName = apiName+'FieldHistory';
            else objectHistoryName = apiName+'History';
            objectHistoryFieldAPIName = apiName+'Id';
        }
        String query = 'SELECT '+objectHistoryFieldAPIName+', Id, Field, NewValue, OldValue, CreatedDate, CreatedBy.Name, CreatedById FROM '+
                        objectHistoryName+' WHERE '+
                        objectHistoryFieldAPIName+' = :recordId'+
                        ' ORDER BY CreatedDate DESC'+
                        ' Limit 5000';
        for(Sobject sobj : Database.query(String.escapeSingleQuotes(query))){
            HistoryWrapper wrapp = createWrapper(sobj, false);
            wrapp.objectAPIName = apiName;
            wrapp.objectLabel = objectDescribe.getLabel();
            wrapp.recordId = String.valueOf(sobj.get(objectHistoryFieldAPIName));
            wrappers.add(wrapp);
        }
        return wrappers;
	}

    private static List<HistoryWrapper> mergeLists(List<HistoryWrapper> customrecords, List<HistoryWrapper> standardrecords){
        List<HistoryWrapper> wrappers = new List<HistoryWrapper>();
        wrappers.addAll(customrecords);
        wrappers.addAll(standardrecords);
        for(HistoryWrapper wrapp : customrecords){

        }
        return wrappers;
    }  
    
    @TestVisible
    private static HistoryWrapper createWrapper(SObject record, Boolean customRecord){
        HistoryWrapper wrapper = new HistoryWrapper();
        wrapper.historyId = String.valueOf(record.get('Id'));
        System.debug(record);
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
            wrapper.additionalField1 = String.valueOf(record.get('ParentId__c'));
            wrapper.additionalField2 = String.valueOf(record.get('ParentId__c'));
            wrapper.createdDate = DateTime.valueOf(record.get('Created_Date_Formula__c'));
            wrapper.createdByName = String.valueOf(record.get('Created_By_Formula__c'));
            wrapper.isCustom = true;
            //wrapper.createdById = record.get('CreatedById');
        } else {
            wrapper.event = 'Updated';
            if(!Test.isRunningTest()) {
                wrapper.field = String.valueOf(record.get('Field'));
                wrapper.oldValue = String.valueOf(record.get('OldValue'));
                wrapper.oldValueFull = String.valueOf(record.get('OldValue'));
                wrapper.newValue = String.valueOf(record.get('NewValue'));
                wrapper.newValueFull = String.valueOf(record.get('NewValue'));
                wrapper.createdByName = String.valueOf(record.getSobject('CreatedBy').get('Name'));
            }
            wrapper.createdDate = DateTime.valueOf(record.get('CreatedDate'));
            wrapper.createdById = String.valueOf(record.get('CreatedById'));
        }
        return wrapper;
    }  
        
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
    
}