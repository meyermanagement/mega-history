/**
 * @description     wrapper for metadata records
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class MetadataWrapper {
    
    @AuraEnabled public String mdName;
    @AuraEnabled public String mdType;
    @AuraEnabled public String mdObject;
    @AuraEnabled public String mdOperation;
    @AuraEnabled public TrackingWrapper mdObjectWrapper;
    
}