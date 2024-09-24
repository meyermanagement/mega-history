global with sharing class HistoryWrapper {
    
    @AuraEnabled global String historyId;
    @AuraEnabled global String objectAPIName;
    @AuraEnabled global String objectLabel;
    @AuraEnabled global String recordId;
    @AuraEnabled global String recordName;
    @AuraEnabled global String parentId;
    @AuraEnabled global String event;
    @AuraEnabled global String fieldLabel;
    @AuraEnabled global String field;
    @AuraEnabled global String oldValue;
    @AuraEnabled global String oldValueFull;
    @AuraEnabled global String newValue;
    @AuraEnabled global String newValueFull;
    @AuraEnabled global String additionalField1;
    @AuraEnabled global String additionalField2;
    @AuraEnabled global DateTime createdDate;
    @AuraEnabled global String createdByName;
    @AuraEnabled global String createdById;
    @AuraEnabled global String createdByURL;
    @AuraEnabled global Boolean isCustom = false;

}
