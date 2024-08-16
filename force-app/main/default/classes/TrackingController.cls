global with sharing class TrackingController {
    
    @AuraEnabled(cacheable=true)
    global static List<TrackingWrapper> getRecords() {
        try {
            Map<String, TrackingWrapper> wrapperMap = new Map<String, TrackingWrapper>();
            List<String> objectNames = new List<String>();
            List<Tracked_Object__mdt> trackedObjects = [SELECT Id, MasterLabel, DeveloperName, Additional_Field_1__c, Additional_Field_2__c, Parent_Reference_Field__c, Track_Create__c, Track_Delete__c, Track_Undelete__c, (SELECT DeveloperName, Field_API_Name__c FROM Tracked_Fields__r ORDER BY Field_API_Name__c) FROM Tracked_Object__mdt ORDER BY MasterLabel];
            for(Tracked_Object__mdt to : trackedObjects){
                objectNames.add(to.DeveloperName);
            }
            Map<String, Schema.DescribeSobjectResult> describeMap = new Map<String, Schema.DescribeSObjectResult>();
            for(Schema.DescribeSobjectResult res : Schema.describeSObjects(objectNames)) {
                System.debug(res.getLabel());
                describeMap.put(res.getLabel(), res);
            }
            for(Tracked_Object__mdt to : trackedObjects){
                TrackingWrapper wrapper = new TrackingWrapper();
                wrapper.objectName = to.DeveloperName;
                wrapper.parentRef = to.Parent_Reference_Field__c;
                wrapper.additionalField1 = to.Additional_Field_1__c;
                wrapper.additionalField2 = to.Additional_Field_2__c;
                String concatEvents = '';
                if(to.Track_Create__c) {
                    concatEvents = concatEvents += 'Create, ';
                    wrapper.trackCreate = true;
                }
                if(to.Track_Delete__c) {
                    concatEvents = concatEvents += 'Delete, ';
                    wrapper.trackDelete = true;
                }
                if(to.Track_Undelete__c) {
                    concatEvents = concatEvents += 'Undelete, ';
                    wrapper.trackUndelete = true;
                }
                concatEvents = concatEvents.removeEnd(', ');
                wrapper.events = concatEvents;
                String concatFields = '';
                wrapper.fieldList = new List<TrackingFieldDefinition>();
                for(Tracked_Field__mdt field: to.Tracked_Fields__r){
                    concatFields = concatFields += field.Field_API_Name__c+', ';
                    TrackingFieldDefinition fd = new TrackingFieldDefinition();
                    fd.fieldLabel = describeMap.get(to.DeveloperName).fields.getMap().get(field.Field_API_Name__c).getDescribe().getLabel();
                    fd.fieldAPIName = field.Field_API_Name__c;
                    fd.customTracked = true;
                    wrapper.fieldList.add(fd);
                }
                concatFields = concatFields.removeEnd(', ');
                wrapper.fields = concatFields;
                wrapper.statusLabel = 'Not Deployed';
                wrapper.statusClass = 'slds-text-color_error slds-text-title_caps';
                wrapperMap.put(to.DeveloperName, wrapper);
            }
            for(ApexTrigger at : [SELECT Id, NamespacePrefix, name, Body, Status, TableEnumOrId FROM ApexTrigger WHERE TableEnumOrId IN :wrapperMap.keySet() AND NamespacePrefix = 'megahistory' AND Status = 'Active']){
                TrackingWrapper wrapper = wrapperMap.get(at.TableEnumOrId);
                wrapper.statusLabel = 'Deployed';
                wrapper.statusClass = 'slds-text-color_success slds-text-title_caps';
                wrapperMap.put(at.TableEnumOrId, wrapper);
            }
            return wrapperMap.values();
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    global static List<TrackingFieldDefinition> getObjectDetails(String wrapperString){
        try {
            System.debug(wrapperString);
            TrackingWrapper wrapper = (TrackingWrapper)JSON.deserialize(wrapperString, TrackingWrapper.class);
            Schema.DescribeSobjectResult res = Schema.describeSObjects(new List<String>{wrapper.objectName})[0];
            //List<Schema.ChildRelationship> childRels = res.getChildRelationships();
            Map<String,Schema.SObjectField> mfields = res.fields.getMap();
            Set<String> standardTrackedFields = new Set<String>();
            for(FieldDefinition fd : [SELECT Label, QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :wrapper.objectName AND IsFieldHistoryTracked = true]){
                standardTrackedFields.add(fd.QualifiedApiName);
            }
            Map<String, TrackingFieldDefinition> resultDefinitions = new Map<String, TrackingFieldDefinition>();
            for(TrackingFieldDefinition tfd : wrapper.fieldList){
                tfd.standardTracked = standardTrackedFields.contains(tfd.fieldAPIName);
                resultDefinitions.put(tfd.fieldAPIName, tfd);
            }
            for(Schema.SObjectField soField : mfields.values()){
                Schema.DescribeFieldResult fieldResult = soField.getDescribe();
                if(!fieldResult.isCalculated() && !fieldResult.isDeprecatedAndHidden() && !resultDefinitions.containsKey(fieldResult.getName())){
                    TrackingFieldDefinition tfd = new TrackingFieldDefinition();
                    tfd.fieldLabel = fieldResult.getLabel();
                    tfd.fieldAPIName = fieldResult.getName();
                    tfd.standardTracked = standardTrackedFields.contains(tfd.fieldAPIName);
                    resultDefinitions.put(tfd.fieldAPIName, tfd);
                }
            }
            return resultDefinitions.values();
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}