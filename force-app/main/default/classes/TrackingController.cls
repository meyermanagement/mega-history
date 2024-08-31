global with sharing class TrackingController {
    
    @AuraEnabled(cacheable=true)
    global static List<TrackingWrapper> getRecords() {
        try {
            Map<String, TrackingWrapper> wrapperMap = new Map<String, TrackingWrapper>();
            Map<String, List<Tracked_Field__mdt>> objectNameMap = new Map<String, List<Tracked_Field__mdt>>();
            List<Tracked_Object__mdt> trackedObjects = [SELECT Id, MasterLabel, DeveloperName, Additional_Field_1__c, Additional_Field_2__c, Parent_Reference_Field__c, Track_Create__c, Track_Delete__c, Track_Undelete__c FROM Tracked_Object__mdt ORDER BY MasterLabel];
            for(Tracked_Object__mdt to : trackedObjects){
                objectNameMap.put(to.DeveloperName, new List<Tracked_Field__mdt>());
            }
            for(Tracked_Field__mdt tf : [SELECT Tracked_Object__r.DeveloperName, DeveloperName, Field_API_Name__c FROM Tracked_Field__mdt ORDER BY Field_API_Name__c]){
                objectNameMap.get(tf.Tracked_Object__r.DeveloperName).add(tf);
            }
            Map<String, Schema.DescribeSobjectResult> describeMap = new Map<String, Schema.DescribeSObjectResult>();
            for(Schema.DescribeSobjectResult res : Schema.describeSObjects(new List<String>(objectNameMap.keySet()))) {
                System.debug(res.getLabel());
                describeMap.put(res.getLabel(), res);
            }
            for(Tracked_Object__mdt to : trackedObjects){
                System.debug(to);
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
                for(Tracked_Field__mdt field: objectNameMap.get(to.DeveloperName)){
                    System.debug(field);
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
            List<Tracked_Object__mdt> toList = [SELECT Id, MasterLabel, DeveloperName, Additional_Field_1__c, Additional_Field_2__c, Parent_Reference_Field__c, Track_Create__c, Track_Delete__c, Track_Undelete__c FROM Tracked_Object__mdt WHERE DeveloperName = :wrapper.objectName ORDER BY MasterLabel LIMIT 1];
            if(!toList.isEmpty()){
                Tracked_Object__mdt to = toList[0];
                orignal.parentRef = to.Parent_Reference_Field__c;
                orignal.additionalField1 = to.Additional_Field_1__c;
                orignal.additionalField2 = to.Additional_Field_2__c;
                orignal.trackCreate = to.Track_Create__c;
                orignal.trackDelete = to.Track_Delete__c;
                orignal.trackUndelete = to.Track_Undelete__c;
            }
            for(TrackingFieldDefinition tfd : wrapper.fieldList){
                if(tfd.customTracked && !fields.contains(tfd.fieldAPIName)) {
                    tfd.customTracked = false;
                    tfd.operation = 'Remove';
                }
                for(String f : fields){
                    if(tfd.fieldAPIName == f && !tfd.standardTracked && !tfd.customTracked){
                        tfd.customTracked = true;
                        tfd.operation = 'Add';
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
        if(wrapper.trackCreate != original.trackCreate) return true;
        if(wrapper.trackDelete != original.trackDelete) return true;
        if(wrapper.trackUndelete != original.trackUndelete) return true;
        return false;
    }

    @AuraEnabled
    global static List<MetadataWrapper> generateMetadata(String trackingData){
        try {
            System.debug(trackingData);
            List<MetadataWrapper> mdWrapperList = new List<MetadataWrapper>();
            List<TrackingWrapper> wrapperList = (List<TrackingWrapper>)JSON.deserialize(trackingData, List<TrackingWrapper>.class);
            for(TrackingWrapper wrapp : wrapperList){
                System.debug(wrapp.objectName);
                System.debug(wrapp.mdtStatusLabel);
                if(wrapp.mdtStatusLabel != 'Deployed'){
                    MetadataWrapper md = new MetadataWrapper();
                    md.mdName = wrapp.objectName;
                    md.mdType = 'Object';
                    md.mdObject = wrapp.objectName;
                    md.mdObjectWrapper = wrapp;
                    Tracked_Object__mdt to = Tracked_Object__mdt.getInstance(wrapp.objectName);
                    System.debug(to);
                    if(to != null){
                        TrackingWrapper orignal = new TrackingWrapper(wrapp);
                        orignal.parentRef = to.Parent_Reference_Field__c;
                        orignal.additionalField1 = to.Additional_Field_1__c;
                        orignal.additionalField2 = to.Additional_Field_2__c;
                        orignal.trackCreate = to.Track_Create__c;
                        orignal.trackDelete = to.Track_Delete__c;
                        orignal.trackUndelete = to.Track_Undelete__c;
                        System.debug(compareWrapper(wrapp, orignal));
                        if(compareWrapper(wrapp, orignal)) {
                            md.mdOperation = 'Change';
                            System.debug(md);
                            mdWrapperList.add(md);
                        } else if (wrapp.mdtStatusLabel == 'Pending Removal'){
                            md.mdOperation = 'Remove';
                            System.debug(md);
                            mdWrapperList.add(md);
                        }
                    } else {
                        md.mdOperation = 'Add';
                        System.debug(md);
                        mdWrapperList.add(md);
                    }
                    for(TrackingFieldDefinition tfd : wrapp.fieldList){
                        if(String.isNotBlank(tfd.operation)){
                            MetadataWrapper mdf = new MetadataWrapper();
                            mdf.mdName = tfd.fieldAPIName;
                            mdf.mdType = 'Field';
                            mdf.mdObject = wrapp.objectName;
                            mdf.mdOperation = tfd.operation;
                            System.debug(mdf);
                            mdWrapperList.add(mdf);
                        }
                    }
                }
                if(wrapp.trigStatusLabel != 'Deployed'){
                    MetadataWrapper md = new MetadataWrapper();
                    md.mdName = 'megahistory'+wrapp.objectName+'Trigger';
                    md.mdType = 'Trigger';
                    md.mdObject = wrapp.objectName;
                    md.mdOperation = wrapp.trigStatusLabel == 'Pending Removal' ? 'Remove' : 'Add';
                    System.debug(md);
                    mdWrapperList.add(md);
                }
            }
            System.debug(mdWrapperList);
            return mdWrapperList;
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    global static void handleCustomMetadata(String wrappers){
        try {
            System.debug(wrappers);
            Map<String, String> metaDataMap = new Map<String, String>();
            List<MetadataWrapper> wrapperList = (List<MetadataWrapper>)JSON.deserialize(wrappers, List<MetadataWrapper>.class);
            List<MetadataWrapper> metadataToDelete = new List<MetadataWrapper>();
            List<MetadataWrapper> metadataFieldsToDeploy = new List<MetadataWrapper>();
            List<MetadataWrapper> metadataObjectsToDeploy = new List<MetadataWrapper>();
            for(MetadataWrapper wrapper : wrapperList){
                if(wrapper.mdType != 'Trigger'){
                    if(wrapper.mdOperation != 'Remove'){
                        if(wrapper.mdType == 'Object'){
                            metadataObjectsToDeploy.add(wrapper);
                        } else {
                            metadataFieldsToDeploy.add(wrapper);
                        }
                    } else {
                        metadataToDelete.add(wrapper);
                    }
                }
            }
            System.debug(metadataToDelete);
            if(!metadataObjectsToDeploy.isEmpty()) CreateMetadata.updateAndDeployMetadata(metadataObjectsToDeploy);
            if(!metadataFieldsToDeploy.isEmpty()) CreateMetadata.updateAndDeployMetadata(metadataFieldsToDeploy);
            if(!metadataToDelete.isEmpty()) deleteMetadata(metadataToDelete);
            
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static void deleteMetadata(List<MetadataWrapper> wrappers){
        List<String> recordsToDelete = new List<String>();
        for(MetadataWrapper wrapper : wrappers){
            String metadataTypeName = wrapper.mdType == 'Object' ? 'megahistory__Tracked_Object__mdt' : 'megahistory__Tracked_Field__mdt';
            String metadataRecordName = wrapper.mdType == 'Object' ? wrapper.mdObject : wrapper.mdObject+'_'+wrapper.mdName.replaceAll('_', '');
            recordsToDelete.add(metadataTypeName+'.'+metadataRecordName);
        }
        System.debug(recordsToDelete);
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = SetupController.getSessionIdFromVFPage();
        service.deleteMetadata('CustomMetadata', recordsToDelete);
    }

    @AuraEnabled
    global static Map<String, String> generateTriggerFiles(String wrappers){
        try {
            System.debug(wrappers);
            Map<String, String> metaDataMap = new Map<String, String>();
            List<MetadataWrapper> wrapperList = (List<MetadataWrapper>)JSON.deserialize(wrappers, List<MetadataWrapper>.class);
            for(MetadataWrapper wrapper : wrapperList){
                if(wrapper.mdType == 'Trigger'){
                    metaDataMap.put('PackageXML', TriggerFiles.getPackageXml(wrapper));
                    metaDataMap.put('DestructiveChangesXML', TriggerFiles.getDestructiveChangesXml(wrapper));
                    metaDataMap.put('TriggerTestMetadata', TriggerFiles.getTriggerTestCodeMetadata());
                    metaDataMap.put('TriggerTest', TriggerFiles.getTriggerTestCode(wrapper));
                    metaDataMap.put('TriggerMetadata', TriggerFiles.getTriggerCodeMetadata());
                    metaDataMap.put('Trigger', TriggerFiles.getTriggerCode(wrapper));
                }
            }
            return metaDataMap;
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    global static void deployTriggers(String zipFile){
        try {
            System.debug(zipFile);
            
            
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}