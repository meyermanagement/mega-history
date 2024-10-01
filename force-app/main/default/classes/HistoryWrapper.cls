/**
 * @description     wrapper for history records
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class HistoryWrapper {
    
    /**
     * @description historyId
     */
    @AuraEnabled public String historyId;
    /**
     * @description objectAPIName
     */
    @AuraEnabled public String objectAPIName;
    /**
     * @description objectLabel
     */
    @AuraEnabled public String objectLabel;
    /**
     * @description recordId
     */
    @AuraEnabled public String recordId;
    /**
     * @description recordName
     */
    @AuraEnabled public String recordName;
    /**
     * @description parentId
     */
    @AuraEnabled public String parentId;
    /**
     * @description event
     */
    @AuraEnabled public String event;
    /**
     * @description fieldLabel
     */
    @AuraEnabled public String fieldLabel;
    /**
     * @description field
     */
    @AuraEnabled public String field;
    /**
     * @description oldValue
     */
    @AuraEnabled public String oldValue;
    /**
     * @description oldValueFull
     */
    @AuraEnabled public String oldValueFull;
    /**
     * @description newValue
     */
    @AuraEnabled public String newValue;
    /**
     * @description newValueFull
     */
    @AuraEnabled public String newValueFull;
    /**
     * @description additionalField1
     */
    @AuraEnabled public String additionalField1;
    /**
     * @description additionalField2
     */
    @AuraEnabled public String additionalField2;
    /**
     * @description createdDate
     */
    @AuraEnabled public DateTime createdDate;
    /**
     * @description createdByName
     */
    @AuraEnabled public String createdByName;
    /**
     * @description createdById
     */
    @AuraEnabled public String createdById;
    /**
     * @description createdByURL
     */
    @AuraEnabled public String createdByURL;
    /**
     * @description isCustom
     */
    @AuraEnabled public Boolean isCustom = false;

}
