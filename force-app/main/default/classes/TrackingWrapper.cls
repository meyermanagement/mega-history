global with sharing class TrackingWrapper {
    
    @AuraEnabled global String objectName;
    @AuraEnabled global String parentRef;
    @AuraEnabled global String events;
    @AuraEnabled global Boolean trackCreate = false;
    @AuraEnabled global Boolean trackDelete = false;
    @AuraEnabled global Boolean trackUndelete = false;
    @AuraEnabled global String fields;
    @AuraEnabled global String additionalField1;
    @AuraEnabled global String additionalField2;
    @AuraEnabled global String statusClass;
    @AuraEnabled global String statusLabel;
    @AuraEnabled global List<TrackingFieldDefinition> fieldList;
}