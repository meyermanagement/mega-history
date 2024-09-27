/**
 * @description     wrapper for tracking records
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class TrackingWrapper {
    
    @AuraEnabled public String objectName;
    @AuraEnabled public String objectLabel;
    @AuraEnabled public String parentRef;
    @AuraEnabled public String events;
    @AuraEnabled public Boolean trackCreate = false;
    @AuraEnabled public Boolean trackDelete = false;
    @AuraEnabled public Boolean trackUndelete = false;
    @AuraEnabled public String fields;
    @AuraEnabled public String additionalField1;
    @AuraEnabled public String additionalField2;
    @AuraEnabled public String mdtStatusClass;
    @AuraEnabled public String mdtStatusLabel;
    @AuraEnabled public String trigStatusClass;
    @AuraEnabled public String trigStatusLabel;
    @AuraEnabled public List<TrackingFieldDefinition> fieldList;
    @AuraEnabled public Map<String, String> parentRefMap;

    /**
     * @description     constructor for new wrapper
     */
    public TrackingWrapper(){
        this.objectName = '';
        this.objectLabel = '';
        this.parentRef = '';
        this.events = '';
        this.trackCreate = false;
        this.trackDelete = false;
        this.trackUndelete = false;
        this.fields = '';
        this.additionalField1 = '';
        this.additionalField2 = '';
        this.mdtStatusClass = '';
        this.mdtStatusLabel = '';
        this.trigStatusClass = '';
        this.trigStatusLabel = '';
        this.fieldList = new List<TrackingFieldDefinition>();
        this.parentRefMap = new Map<String, String>();
    }

    /**
     * @description     constructor for an existing record for comparison
     */
    public TrackingWrapper(TrackingWrapper original){
        this.objectName = original.objectName;
        this.objectLabel = original.objectLabel;
        this.parentRef = original.parentRef;
        this.events = original.events;
        this.fields = original.fields;
        this.additionalField1 = original.additionalField1;
        this.additionalField2 = original.additionalField2;
        this.trackCreate = original.trackCreate;
        this.trackDelete = original.trackDelete;
        this.trackUndelete = original.trackUndelete;
    }
}