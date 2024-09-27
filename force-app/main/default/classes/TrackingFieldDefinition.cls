/**
 * @description     wrapper for Field Definitions
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class TrackingFieldDefinition {
    
    @AuraEnabled public String fieldLabel;
    @AuraEnabled public String fieldAPIName;
    @AuraEnabled public Boolean standardTracked = false;
    @AuraEnabled public Boolean customTracked = false;
    @AuraEnabled public String operation;
}