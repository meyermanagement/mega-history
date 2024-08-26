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
                wrapper.trigStatusLabel = 'Not Deployed';
                wrapper.trigStatusClass = 'slds-text-color_error slds-text-title_caps';
                wrapper.mdtStatusLabel = 'Deployed';
                wrapper.mdtStatusClass = 'slds-text-color_success slds-text-title_caps';
                wrapperMap.put(to.DeveloperName, wrapper);
            }
            for(ApexTrigger at : [SELECT Id, NamespacePrefix, name, Body, Status, TableEnumOrId FROM ApexTrigger WHERE TableEnumOrId IN :wrapperMap.keySet() AND Name LIKE 'megahistory%' AND Status = 'Active']){
                TrackingWrapper wrapper = wrapperMap.get(at.TableEnumOrId);
                wrapper.trigStatusLabel = 'Deployed';
                wrapper.trigStatusClass = 'slds-text-color_success slds-text-title_caps';
                wrapperMap.put(at.TableEnumOrId, wrapper);
            }
            return wrapperMap.values();
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    global static List<TrackingWrapper> getObjects(){
        Map<String, TrackingWrapper> wrapperMap = new Map<String, TrackingWrapper>();
        Set<String> existingTracking = new Set<String>();
        List<Tracked_Object__mdt> trackedObjects = [SELECT Id, MasterLabel, DeveloperName, Additional_Field_1__c, Additional_Field_2__c, Parent_Reference_Field__c, Track_Create__c, Track_Delete__c, Track_Undelete__c, (SELECT DeveloperName, Field_API_Name__c FROM Tracked_Fields__r ORDER BY Field_API_Name__c) FROM Tracked_Object__mdt ORDER BY MasterLabel];
        for(Tracked_Object__mdt to : trackedObjects){
            existingTracking.add(to.DeveloperName);
        }
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        for(Schema.SObjectType d : gd.values())
        {
            Schema.DescribeSObjectResult ds = d.getDescribe();
            System.debug(ds.getName());
            System.debug(ds.isCreateable());
            if(!ds.isCreateable() || existingTracking.contains(ds.getName()) || ds.isCustomSetting() || !ds.isQueryable()) continue;
            else {
                TrackingWrapper wrapper = new TrackingWrapper();
                wrapper.objectName = ds.getName();
                wrapper.objectLabel = ds.getLabel();
                wrapperMap.put(ds.getName(), wrapper);
            }
        }
        List<String> orderedList = new List<String>(wrapperMap.keySet());
        orderedList.sort();
        List<TrackingWrapper> results = new List<TrackingWrapper>();
        for(String s : orderedList){
            results.add(wrapperMap.get(s));
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    global static TrackingWrapper getObjectSelectedDetails(String objectName){
        try {
            TrackingWrapper wrapper = new TrackingWrapper();
            wrapper.objectName = objectName;
            wrapper.mdtStatusLabel = 'Not Deployed';
            wrapper.mdtStatusClass = 'slds-text-color_error slds-text-title_caps';
            wrapper.trigStatusLabel = 'Not Deployed';
            wrapper.trigStatusClass = 'slds-text-color_error slds-text-title_caps';
            System.debug(objectName);
            Schema.DescribeSobjectResult res = Schema.describeSObjects(new List<String>{objectName})[0];
            //List<Schema.ChildRelationship> childRels = res.getChildRelationships();
            Map<String,Schema.SObjectField> mfields = res.fields.getMap();
            Set<String> standardTrackedFields = new Set<String>();
            for(FieldDefinition fd : [SELECT Label, QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :objectName AND IsFieldHistoryTracked = true ORDER BY QualifiedApiName]){
                standardTrackedFields.add(fd.QualifiedApiName);
            }
            Map<String, TrackingFieldDefinition> resultDefinitions = new Map<String, TrackingFieldDefinition>();
            for(Schema.SObjectField soField : mfields.values()){
                Schema.DescribeFieldResult fieldResult = soField.getDescribe();
                if(fieldResult.isUpdateable() && !fieldResult.isDeprecatedAndHidden()){
                    if(!resultDefinitions.containsKey(fieldResult.getName())){
                        TrackingFieldDefinition tfd = new TrackingFieldDefinition();
                        tfd.fieldLabel = fieldResult.getLabel();
                        tfd.fieldAPIName = fieldResult.getName();
                        tfd.standardTracked = standardTrackedFields.contains(tfd.fieldAPIName);
                        resultDefinitions.put(tfd.fieldAPIName, tfd);
                    }
                    if(fieldResult.getRelationshipName() != null){
                        wrapper.parentRefMap.put(fieldResult.getName(), fieldResult.getLabel());
                    }
                }
            }
            List<String> orderedList = new List<String>(resultDefinitions.keySet());
            orderedList.sort();
            List<TrackingFieldDefinition> results = new List<TrackingFieldDefinition>();
            for(String s : orderedList){
                results.add(resultDefinitions.get(s));
            }
            wrapper.fieldList = results;
            return wrapper;
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    global static TrackingWrapper getObjectDetails(String wrapperString){
        try {
            System.debug(wrapperString);
            TrackingWrapper wrapper = (TrackingWrapper)JSON.deserialize(wrapperString, TrackingWrapper.class);
            Schema.DescribeSobjectResult res = Schema.describeSObjects(new List<String>{wrapper.objectName})[0];
            //List<Schema.ChildRelationship> childRels = res.getChildRelationships();
            Map<String,Schema.SObjectField> mfields = res.fields.getMap();
            Set<String> standardTrackedFields = new Set<String>();
            for(FieldDefinition fd : [SELECT Label, QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :wrapper.objectName AND IsFieldHistoryTracked = true ORDER BY QualifiedApiName]){
                standardTrackedFields.add(fd.QualifiedApiName);
            }
            Map<String, TrackingFieldDefinition> resultDefinitions = new Map<String, TrackingFieldDefinition>();
            for(TrackingFieldDefinition tfd : wrapper.fieldList){
                tfd.standardTracked = standardTrackedFields.contains(tfd.fieldAPIName);
                resultDefinitions.put(tfd.fieldAPIName, tfd);
            }
            for(Schema.SObjectField soField : mfields.values()){
                Schema.DescribeFieldResult fieldResult = soField.getDescribe();
                if(fieldResult.isUpdateable() && !fieldResult.isDeprecatedAndHidden()){
                    if(!resultDefinitions.containsKey(fieldResult.getName())){
                        TrackingFieldDefinition tfd = new TrackingFieldDefinition();
                        tfd.fieldLabel = fieldResult.getLabel();
                        tfd.fieldAPIName = fieldResult.getName();
                        tfd.standardTracked = standardTrackedFields.contains(tfd.fieldAPIName);
                        resultDefinitions.put(tfd.fieldAPIName, tfd);
                    }
                    if(fieldResult.getRelationshipName() != null){
                        wrapper.parentRefMap.put(fieldResult.getName(), fieldResult.getLabel());
                    }
                }
            }
            List<String> orderedList = new List<String>(resultDefinitions.keySet());
            orderedList.sort();
            List<TrackingFieldDefinition> results = new List<TrackingFieldDefinition>();
            for(String s : orderedList){
                results.add(resultDefinitions.get(s));
            }
            wrapper.fieldList = results;
            return wrapper;
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    global static List<TrackingWrapper> submitMetaData(String wrapperString, String trackingData, List<String> fields){
        try {
            System.debug(wrapperString);
            System.debug(trackingData);
            System.debug(fields);
            TrackingWrapper wrapper = (TrackingWrapper)JSON.deserialize(wrapperString, TrackingWrapper.class);
            TrackingWrapper orignal = new TrackingWrapper(wrapper);
            for(TrackingFieldDefinition tfd : wrapper.fieldList){
                for(String f : fields){
                    if(tfd.fieldAPIName == f && !tfd.standardTracked){
                        tfd.customTracked = true;
                    }
                }
            }
            System.debug(wrapper);
            String concatEvents = '';
            if(wrapper.trackCreate) {
                concatEvents = concatEvents += 'Create, ';
            }
            if(wrapper.trackDelete) {
                concatEvents = concatEvents += 'Delete, ';
            }
            if(wrapper.trackUndelete) {
                concatEvents = concatEvents += 'Undelete, ';
            }
            concatEvents = concatEvents.removeEnd(', ');
            wrapper.events = concatEvents;
            String concatFields = '';
            for(TrackingFieldDefinition field: wrapper.fieldList){
                if(field.customTracked){
                    concatFields = concatFields += field.fieldAPIName+', ';
                }
            }
            concatFields = concatFields.removeEnd(', ');
            wrapper.fields = concatFields;

            System.debug(compareWrapper(wrapper, orignal));
            if(compareWrapper(wrapper, orignal)){
                wrapper.mdtStatusLabel = 'Not Deployed';
                wrapper.mdtStatusClass = 'slds-text-color_error slds-text-title_caps';
            }

            List<TrackingWrapper> wrapperList = (List<TrackingWrapper>)JSON.deserialize(trackingData, List<TrackingWrapper>.class);
            Map<String, TrackingWrapper> wrapperMap = new Map<String, TrackingWrapper>();
            for(TrackingWrapper tw : wrapperList){
                wrapperMap.put(tw.objectName, tw);
            }
            wrapperMap.put(wrapper.objectName, wrapper);
            List<String> orderedList = new List<String>(wrapperMap.keySet());
            orderedList.sort();
            List<TrackingWrapper> results = new List<TrackingWrapper>();
            for(String s : orderedList){
                results.add(wrapperMap.get(s));
            }
            return results;
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Boolean compareWrapper(TrackingWrapper wrapper, TrackingWrapper original){
        System.debug(wrapper);
        System.debug(original);
        if(wrapper.parentRef != original.parentRef) return true;
        if(wrapper.events != original.events) return true;
        if(wrapper.fields != original.fields) return true;
        if(wrapper.additionalField1 != original.additionalField1) return true;
        if(wrapper.additionalField2 != original.additionalField2) return true;
        return false;
    }

    
}