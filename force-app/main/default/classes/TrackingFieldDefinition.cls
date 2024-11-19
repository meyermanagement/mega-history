/**
 * @description     wrapper for Field Definitions
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class TrackingFieldDefinition {
    
    /**
     * @description fieldLabel
     */
    @AuraEnabled public String fieldLabel;
    /**
     * @description fieldAPIName
     */
    @AuraEnabled public String fieldAPIName;
    /**
     * @description standardTracked
     */
    @AuraEnabled public Boolean standardTracked = false;
    /**
     * @description customTracked
     */
    @AuraEnabled public Boolean customTracked = false;
    /**
     * @description operation
     */
    @AuraEnabled public String operation;
}