/**
 * @description     wrapper for object details
 * @author          Mark Meyer
 * @date            01/15/2025
 */
public with sharing class ObjectDetailsWrapper {
    
    /**
     * @description objectApiName
     */
    @AuraEnabled public String objectApiName;
    /**
     * @description objectLabel
     */
    @AuraEnabled public String objectLabel;
    /**
     * @description objectNameField
     */
    @AuraEnabled public String objectNameField;
    /**
     * @description objectSecondaryField
     */
    @AuraEnabled public String objectSecondaryField;
    /**
     * @description objectIcon
     */
    @AuraEnabled public String objectIcon;
}