public without sharing class CreateMetadata {

    public static String updateAndDeployMetadata(List<MetadataWrapper> wrappers) {
        MetadataWrapper wrapper = wrappers[0];
        System.debug(wrapper);
        
        Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        if(wrapper.mdType == 'Object'){
            TrackingWrapper tw = wrapper.mdObjectWrapper;
            customMetadata.fullName = 'megahistory__Tracked_Object__mdt.'+wrapper.mdObject;
            customMetadata.label = wrapper.mdObject;
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = 'megahistory__Additional_Field_1__c';
            customField.value = tw.additionalField1;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = 'megahistory__Additional_Field_2__c';
            customField.value = tw.additionalField2;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = 'megahistory__Parent_Reference_Field__c';
            customField.value = tw.parentRef;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = 'megahistory__Track_Create__c';
            customField.value = tw.trackCreate;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = 'megahistory__Track_Delete__c';
            customField.value = tw.trackDelete;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = 'megahistory__Track_Undelete__c';
            customField.value = tw.trackUndelete;
            customMetadata.values.add(customField);
        } else {
            String metadataRecordName = wrapper.mdObject+'_'+wrapper.mdName.replaceAll('_', '');
            customMetadata.fullName = 'megahistory__Tracked_Field__mdt.'+metadataRecordName;
            customMetadata.label = wrapper.mdObject+'_'+wrapper.mdName;
            System.debug(String.valueOf(Tracked_Object__mdt.getInstance(wrapper.mdObject).Id));
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = 'megahistory__Field_API_Name__c';
            customField.value = wrapper.mdName;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = 'megahistory__Tracked_Object__c';
            customField.value = String.valueOf(Tracked_Object__mdt.getInstance(wrapper.mdObject).DeveloperName);
            customMetadata.values.add(customField);
        }
    
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
    
        MyDeployCallback callback = new MyDeployCallback();
        Id jobId = Test.isRunningTest() ? null : Metadata.Operations.enqueueDeployment(mdContainer, callback);
        System.debug(jobId);
        return jobId;
        // Setup custom metadata to be created in the subscriber org.
    } 
}