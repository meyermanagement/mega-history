/**
 * @description     wrapper for history records
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class HistoryWrapper {
    
    @AuraEnabled public String historyId;
    @AuraEnabled public String objectAPIName;
    @AuraEnabled public String objectLabel;
    @AuraEnabled public String recordId;
    @AuraEnabled public String recordName;
    @AuraEnabled public String parentId;
    @AuraEnabled public String event;
    @AuraEnabled public String fieldLabel;
    @AuraEnabled public String field;
    @AuraEnabled public String oldValue;
    @AuraEnabled public String oldValueFull;
    @AuraEnabled public String newValue;
    @AuraEnabled public String newValueFull;
    @AuraEnabled public String additionalField1;
    @AuraEnabled public String additionalField2;
    @AuraEnabled public DateTime createdDate;
    @AuraEnabled public String createdByName;
    @AuraEnabled public String createdById;
    @AuraEnabled public String createdByURL;
    @AuraEnabled public Boolean isCustom = false;

}
