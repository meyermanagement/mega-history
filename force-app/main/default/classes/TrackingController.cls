/**
 * @description     Controller for the Tracking LWC
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class TrackingController {

    /**
     * @description  System relationship fields not to include in list of parent reference fields
     */
    static Set<String> systemRelationships = new Set<String>{'CampaignMemberRecordTypeId','RecordTypeId', 'CreatedById','LastModifiedById','OwnerId'};

    /**
     * @description  Custom Exception for this class
     */
    public class TrackingException extends Exception {}
    
    /**
     * @description     get all tracking records
     * @return List of TrackingWrapper
     */
    @AuraEnabled(cacheable=true)
    public static List<TrackingWrapper> getRecords() {
        try {
            Map<String, TrackingWrapper> wrapperMap = new Map<String, TrackingWrapper>();
            Map<String, List<Tracked_Field__mdt>> objectNameMap = new Map<String, List<Tracked_Field__mdt>>();
            List<Tracked_Object__mdt> trackedObjects = [SELECT Id, MasterLabel, DeveloperName, Additional_Field_1__c, Additional_Field_2__c, Parent_Reference_Field__c, Track_Create__c, Track_Delete__c, Track_Undelete__c FROM Tracked_Object__mdt WITH USER_MODE ORDER BY MasterLabel];
            for(Tracked_Object__mdt to : trackedObjects){
                objectNameMap.put(to.MasterLabel, new List<Tracked_Field__mdt>());
            }
            for(Tracked_Field__mdt tf : [SELECT Tracked_Object__r.MasterLabel, Tracked_Object__r.DeveloperName, DeveloperName, Field_API_Name__c FROM Tracked_Field__mdt WHERE Tracked_Object__r.MasterLabel IN :objectNameMap.keySet() WITH USER_MODE ORDER BY Field_API_Name__c]){
                objectNameMap.get(tf.Tracked_Object__r.MasterLabel).add(tf);
            }
            Map<String, Schema.DescribeSobjectResult> describeMap = new Map<String, Schema.DescribeSObjectResult>();
            for(Schema.DescribeSobjectResult res : Schema.describeSObjects(new List<String>(objectNameMap.keySet()))) {
                describeMap.put(res.getName(), res);
            }
            for(Tracked_Object__mdt to : trackedObjects){
                TrackingWrapper wrapper = new TrackingWrapper();
                wrapper.objectName = to.MasterLabel;
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
                for(Tracked_Field__mdt field: objectNameMap.get(to.MasterLabel)){
                    Schema.SObjectField sobjField = describeMap.get(to.MasterLabel).fields.getMap().get(field.Field_API_Name__c);
                    concatFields = concatFields += field.Field_API_Name__c+', ';
                    TrackingFieldDefinition fd = new TrackingFieldDefinition();
                    fd.fieldLabel = sobjField != null ? sobjField.getDescribe().getLabel() : 'DELETED-';
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
                wrapperMap.put(to.MasterLabel, wrapper);
            }
            for(ApexTrigger at : [SELECT Id, NamespacePrefix, name, Body, Status, TableEnumOrId FROM ApexTrigger WHERE Name LIKE 'mh%' AND Status = 'Active' WITH USER_MODE]){
                if(wrapperMap.get(at.TableEnumOrId) != null){
                    TrackingWrapper wrapper = wrapperMap.get(at.TableEnumOrId);
                    wrapper.trigStatusLabel = 'Deployed';
                    wrapper.trigStatusClass = 'slds-text-color_success slds-text-title_caps';
                    wrapperMap.put(at.TableEnumOrId, wrapper);
                } else {
                    TrackingWrapper wrapper = new TrackingWrapper();
                    wrapper.objectName = at.TableEnumOrId;
                    wrapper.trigStatusLabel = 'Deployed';
                    wrapper.trigStatusClass = 'slds-text-color_success slds-text-title_caps';
                    wrapper.mdtStatusLabel = 'Not Deployed';
                    wrapper.mdtStatusClass = 'slds-text-color_error slds-text-title_caps';
                    wrapperMap.put(at.TableEnumOrId, wrapper);
                }
            
            }
            return wrapperMap.values();
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     get available objects
     * @return List of TrackingWrapper
     */
    @AuraEnabled(cacheable=true)
    public static List<TrackingWrapper> getObjects(){
        Map<String, TrackingWrapper> wrapperMap = new Map<String, TrackingWrapper>();
        Map<String, List<Tracked_Field__mdt>> objectNameMap = new Map<String, List<Tracked_Field__mdt>>();
        List<Tracked_Object__mdt> trackedObjects = [SELECT Id, MasterLabel, DeveloperName, Additional_Field_1__c, Additional_Field_2__c, Parent_Reference_Field__c, Track_Create__c, Track_Delete__c, Track_Undelete__c FROM Tracked_Object__mdt WITH USER_MODE ORDER BY MasterLabel];
        for(Tracked_Object__mdt to : trackedObjects){
            objectNameMap.put(to.DeveloperName, new List<Tracked_Field__mdt>());
        }
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        for(Schema.SObjectType d : gd.values())
        {
            Schema.DescribeSObjectResult ds = d.getDescribe();
            if(!objectNameMap.keySet().contains(ds.getName())){
                try{
                    String sobjStruct = JSON.serialize(ds);
                    DescribeSobjectResultJSON sobjProps = (DescribeSobjectResultJSON)JSON.deserialize(sobjStruct, DescribeSobjectResultJSON.class);
                    if(sobjProps.triggerable){
                        Boolean updateableFields = false;
                        Map<String,Schema.SObjectField> mfields = ds.fields.getMap();
                        for(Schema.SObjectField soField : mfields.values()){
                            Schema.DescribeFieldResult fieldResult = soField.getDescribe();
                            if(fieldResult.isUpdateable() && !fieldResult.isDeprecatedAndHidden()){
                                updateableFields = true;
                            }
                        }
                        if(updateableFields){
                            TrackingWrapper wrapper = new TrackingWrapper();
                            wrapper.objectName = ds.getName();
                            wrapper.objectLabel = ds.getLabel();
                            wrapperMap.put(ds.getName(), wrapper);
                        }
                    }
                } catch(Exception e){
                    System.debug(LoggingLevel.DEBUG, e.getMessage());
                }
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

    /**
     * @description     wrapper class for finding triggerable objects
     */
    public class DescribeSobjectResultJSON { 
        /**
         * @description object name
         */
        public String name {get;set;}
        /**
         * @description is triggerable
         */
        public Boolean triggerable {get;set;}
    }

    /**
     * @description     get Tracking coniguration for given object
     * @param objectName
     * @return TrackingWrapper
     */
    @AuraEnabled(cacheable=true)
    public static TrackingWrapper getObjectSelectedDetails(String objectName){
        try {
            TrackingWrapper wrapper = new TrackingWrapper();
            wrapper.objectName = objectName;
            wrapper.mdtStatusLabel = 'Not Deployed';
            wrapper.mdtStatusClass = 'slds-text-color_error slds-text-title_caps';
            wrapper.trigStatusLabel = 'Not Deployed';
            wrapper.trigStatusClass = 'slds-text-color_error slds-text-title_caps';
            Schema.DescribeSobjectResult res = Schema.describeSObjects(new List<String>{objectName})[0];
            //List<Schema.ChildRelationship> childRels = res.getChildRelationships();
            Map<String,Schema.SObjectField> mfields = res.fields.getMap();
            Set<String> standardTrackedFields = new Set<String>();
            for(FieldDefinition fd : [SELECT Label, QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :objectName AND IsFieldHistoryTracked = true WITH USER_MODE ORDER BY QualifiedApiName]){
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
                }
                if(fieldResult.getRelationshipName() != null && !systemRelationships.contains(fieldResult.getName())){
                    wrapper.parentRefMap.put(fieldResult.getName(), fieldResult.getLabel());
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
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     get field coniguration for given tracking wrapper
     * @param wrapperString
     * @return TrackingWrapper
     */
    @AuraEnabled
    public static TrackingWrapper getObjectDetails(String wrapperString){
        try {
            TrackingWrapper wrapper = (TrackingWrapper)JSON.deserialize(wrapperString, TrackingWrapper.class);
            Schema.DescribeSobjectResult res = Schema.describeSObjects(new List<String>{wrapper.objectName})[0];
            //List<Schema.ChildRelationship> childRels = res.getChildRelationships();
            Map<String,Schema.SObjectField> mfields = res.fields.getMap();
            Set<String> standardTrackedFields = new Set<String>();
            for(FieldDefinition fd : [SELECT Label, QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :wrapper.objectName AND IsFieldHistoryTracked = true WITH USER_MODE ORDER BY QualifiedApiName]){
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
                }
                if(fieldResult.getRelationshipName() != null && !systemRelationships.contains(fieldResult.getName())){
                    wrapper.parentRefMap.put(fieldResult.getName(), fieldResult.getLabel());
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
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     create Tracking Wrapper from inputs
     * @param wrapperString
     * @param trackingData
     * @param fields
     * @return List of TrackingWrapper
     */
    @AuraEnabled
    public static List<TrackingWrapper> submitMetaData(String wrapperString, String trackingData, List<String> fields){
        try {
            TrackingWrapper wrapper = (TrackingWrapper)JSON.deserialize(wrapperString, TrackingWrapper.class);
            TrackingWrapper orignal = new TrackingWrapper(wrapper);
            List<Tracked_Object__mdt> toList = [SELECT Id, MasterLabel, DeveloperName, Additional_Field_1__c, Additional_Field_2__c, Parent_Reference_Field__c, Track_Create__c, Track_Delete__c, Track_Undelete__c FROM Tracked_Object__mdt WHERE DeveloperName = :wrapper.objectName WITH USER_MODE ORDER BY MasterLabel LIMIT 1];
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
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     compare Metadata Wrappers
     * @param wrapper
     * @param original
     * @return matches
     */
    private static Boolean compareWrapper(TrackingWrapper wrapper, TrackingWrapper original){
        if(wrapper.parentRef != original.parentRef) {
            return true;
        }
        if(wrapper.events != original.events) {
            return true;
        }
        if(wrapper.fields != original.fields) {
            return true;
        }
        if(wrapper.additionalField1 != original.additionalField1) {
            return true;
        }
        if(wrapper.additionalField2 != original.additionalField2) {
            return true;
        }
        if(wrapper.trackCreate != original.trackCreate) {
            return true;
        }
        if(wrapper.trackDelete != original.trackDelete) {
            return true;
        }
        if(wrapper.trackUndelete != original.trackUndelete) {
            return true;
        }
        return false;
    }

    /**
     * @description     create Metadata Wrappers from inputs
     * @param trackingData
     * @return List of Metadata Wrappers
     */
    @AuraEnabled
    public static List<MetadataWrapper> generateMetadata(String trackingData){
        try {
            List<MetadataWrapper> mdWrapperList = new List<MetadataWrapper>();
            List<TrackingWrapper> wrapperList = (List<TrackingWrapper>)JSON.deserialize(trackingData, List<TrackingWrapper>.class);
            for(TrackingWrapper wrapp : wrapperList){
                if(wrapp.mdtStatusLabel != 'Deployed'){
                    MetadataWrapper md = new MetadataWrapper();
                    md.mdName = wrapp.objectName;
                    md.mdType = 'Object';
                    md.mdObject = wrapp.objectName;
                    md.mdObjectWrapper = wrapp;
                    Tracked_Object__mdt to = Tracked_Object__mdt.getInstance(wrapp.objectName.replaceAll('_',''));
                    if(to != null){
                        TrackingWrapper orignal = new TrackingWrapper(wrapp);
                        orignal.parentRef = to.Parent_Reference_Field__c;
                        orignal.additionalField1 = to.Additional_Field_1__c;
                        orignal.additionalField2 = to.Additional_Field_2__c;
                        orignal.trackCreate = to.Track_Create__c;
                        orignal.trackDelete = to.Track_Delete__c;
                        orignal.trackUndelete = to.Track_Undelete__c;
                        if(compareWrapper(wrapp, orignal)) {
                            md.mdOperation = 'Change';
                            mdWrapperList.add(md);
                        } else if (wrapp.mdtStatusLabel == 'Pending Removal'){
                            md.mdOperation = 'Remove';
                            mdWrapperList.add(md);
                        }
                    } else if(wrapp.mdtStatusLabel != 'Pending Removal') {
                        md.mdOperation = 'Add';
                        mdWrapperList.add(md);
                    }
                    for(TrackingFieldDefinition tfd : wrapp.fieldList){
                        if(String.isNotBlank(tfd.operation)){
                            MetadataWrapper mdf = new MetadataWrapper();
                            mdf.mdName = tfd.fieldAPIName;
                            mdf.mdType = 'Field';
                            mdf.mdObject = wrapp.objectName;
                            mdf.mdOperation = tfd.operation;
                            mdWrapperList.add(mdf);
                        }
                    }
                }
                if(wrapp.trigStatusLabel != 'Deployed'){
                    MetadataWrapper md = new MetadataWrapper();
                    md.mdName = 'mh'+wrapp.objectName.replaceAll('_','')+'Trigger';
                    md.mdType = 'Trigger';
                    md.mdObject = wrapp.objectName;
                    md.mdOperation = wrapp.trigStatusLabel == 'Pending Removal' ? 'Remove' : 'Add';
                    mdWrapperList.add(md);
                }
            }
            return mdWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     deploy custom metadata records
     * @param wrappers
     * @return deployment id
     */
    @AuraEnabled
    public static String handleCustomMetadata(String wrappers){
        try {
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
            if(!metadataObjectsToDeploy.isEmpty()) {
                return CreateMetadata.updateAndDeployMetadata(metadataObjectsToDeploy);
            }
            if(!metadataFieldsToDeploy.isEmpty()) {
                return CreateMetadata.updateAndDeployMetadata(metadataFieldsToDeploy);
            }
            if(!metadataToDelete.isEmpty()) {
                return deleteMetadata(metadataToDelete);
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description     deploy custom metadata
     * @param wrappers
     * @return deployment response
     */
    @TestVisible
    private static String deleteMetadata(List<MetadataWrapper> wrappers){
        List<String> recordsToDelete = new List<String>();
        Set<String> objectNames = new Set<String>();
        for(MetadataWrapper wrapper : wrappers){
            String metadataTypeName;
            String metadataRecordName;
            if(wrapper.mdType == 'Object'){
                metadataTypeName = 'megatools__Tracked_Object__mdt';
                metadataRecordName =  wrapper.mdObject.replaceAll('_', '');
                objectNames.add(metadataRecordName);
            } else {
                metadataTypeName = 'megatools__Tracked_Field__mdt';
                metadataRecordName = wrapper.mdObject.replaceAll('_', '')+'_'+wrapper.mdName.replaceAll('_', '');
            }
            recordsToDelete.add(metadataTypeName+'.'+metadataRecordName);
        }
        if(!objectNames.isEmpty()){
            for(Tracked_Field__mdt tf : [SELECT Tracked_Object__r.DeveloperName, DeveloperName, Field_API_Name__c FROM Tracked_Field__mdt WHERE Tracked_Object__r.DeveloperName IN :objectNames WITH USER_MODE ORDER BY Field_API_Name__c]){
                String metadataTypeName = 'megatools__Tracked_Field__mdt';
                String metadataRecordName = tf.DeveloperName;
                recordsToDelete.add(metadataTypeName+'.'+metadataRecordName);
            }
        }
        recordsToDelete.sort();
        MetadataService.MetadataPort service = createService();
        MetadataService.DeleteResult[] results = Test.isRunningTest() ? new MetadataService.DeleteResult[]{} : service.deleteMetadata('CustomMetadata', recordsToDelete);
        for(MetadataService.DeleteResult res : results){
            if(!res.success){
                throw new TrackingException(res.errors[0].message);
            } else {
                return 'Success';
            }
        }
        return null;
    }

    /**
     * @description     generate the trigger files to be deployed
     * @param wrappers
     * @return map of file name to metadata
     */
    @AuraEnabled
    public static Map<String, String> generateTriggerFiles(String wrappers){
        try {
            Map<String, String> metaDataMap = new Map<String, String>();
            List<MetadataWrapper> wrapperList = (List<MetadataWrapper>)JSON.deserialize(wrappers, List<MetadataWrapper>.class);
            for(MetadataWrapper wrapper : wrapperList){
                if(wrapper.mdType == 'Trigger'){
                    String className = wrapper.mdName.removeEnd('Trigger');
                    className = className + '_Test';
                    if(wrapper.mdOperation == 'Remove') {
                        metaDataMap.put('destructiveChanges.xml', TriggerFiles.getDestructiveChangesXml(wrapper));
                        metaDataMap.put('package.xml', TriggerFiles.getPackageXml(wrapper, false));
                    } else {
                        metaDataMap.put('package.xml', TriggerFiles.getPackageXml(wrapper, true));
                        metaDataMap.put('classes/'+className+'.cls-meta.xml', TriggerFiles.getTriggerTestCodeMetadata());
                        metaDataMap.put('classes/'+className+'.cls', TriggerFiles.getTriggerTestCode(wrapper));
                        metaDataMap.put('triggers/'+wrapper.mdName+'.trigger-meta.xml', TriggerFiles.getTriggerCodeMetadata());
                        metaDataMap.put('triggers/'+wrapper.mdName+'.trigger', TriggerFiles.getTriggerCode(wrapper));
                    }
                    metaDataMap.put('testName', className+'');
                }
            }
            return metaDataMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     deploy trigger using zip file
     * @param zipFile
     * @param testName
     * @return deployment id
     */
    @AuraEnabled
    public static String deployTriggers(String zipFile, String testName){
        try {
            MetadataService.MetadataPort service = createService();
            MetadataService.DeployOptions deployOptions = new MetadataService.DeployOptions();
            deployOptions.testLevel = 'RunSpecifiedTests';
            deployOptions.runTests = new List<String>{ testName };
            deployOptions.allowMissingFiles = false;
            deployOptions.autoUpdatePackage = false;
            deployOptions.checkOnly = false;
            deployOptions.ignoreWarnings = false;
            deployOptions.performRetrieve = false;
            deployOptions.purgeOnDelete = false;
            deployOptions.rollbackOnError = true;
            deployOptions.singlePackage = true;
            MetadataService.AsyncResult result = Test.isRunningTest() ? new MetadataService.AsyncResult() : service.deploy(zipFile, DeployOptions);
            return result.id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description     check deployment status
     * @param asyncId
     * @return isComplete
     */
    @AuraEnabled
    public static Boolean checkAsyncRequest(String asyncId){
        try {
            MetadataService.MetadataPort service = createService();
            MetadataService.DeployResult deployResult = Test.isRunningTest() ? new MetadataService.DeployResult() : service.checkDeployStatus(asyncId, true);
            if (deployResult.details != null && deployResult.details.componentFailures != null){
                for (MetadataService.DeployMessage deployMessage : deployResult.details.componentFailures){
                    if (deployMessage.problem != null){
                        throw new TrackingException(deployMessage.fileName +
                        ' (Line: ' +
                        deployMessage.lineNumber +
                        ': Column:' +
                        deployMessage.columnNumber +
                        ') : ' +
                        deployMessage.problem);
                    }
                }
                MetadataService.RunTestsResult runTestResult = deployResult.details.runTestResult;
                if (runTestResult.numFailures > 0){
                    for (MetadataService.RunTestFailure testFailure : runTestResult.failures){
                        throw new TrackingException(
                            testFailure.name +
                            '.' +
                            testFailure.methodName +
                            ' ' +
                            testFailure.message +
                            ' ' +
                            testFailure.stackTrace
                        );
                    }
                }
                if (runTestResult.codeCoverageWarnings != null){
                    for (MetadataService.CodeCoverageWarning codeCoverageWarning : runTestResult.codeCoverageWarnings){
                        throw new TrackingException((codeCoverageWarning.namespace != null
                            ? codeCoverageWarning.namespace + '.'
                            : '') +
                            codeCoverageWarning.name +
                            ':' +
                            codeCoverageWarning.message
                        );
                    }
                }
            }
            return deployResult.done;
        } catch (Exception e) {
            if(!e.getMessage().contains('Apex type not found')) {
                throw new AuraHandledException(e.getMessage());
            } else {
                return true;
            }
        }
    }

    /**
     * @description     create the metadata service using the session id from vf page
     * @return metadataport
     */
    private static MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = SetupController.getSessionIdFromVFPage();
        return service;
      }
}