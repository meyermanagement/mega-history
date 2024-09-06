global with sharing class MetadataWrapper {
    
    @AuraEnabled global String mdName;
    @AuraEnabled global String mdType;
    @AuraEnabled global String mdObject;
    @AuraEnabled global String mdOperation;
    @AuraEnabled global TrackingWrapper mdObjectWrapper;
    
}