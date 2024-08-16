global with sharing class TrackingFieldDefinition {
    
    @AuraEnabled global String fieldLabel;
    @AuraEnabled global String fieldAPIName;
    @AuraEnabled global Boolean standardTracked = false;
    @AuraEnabled global Boolean customTracked = false;
}