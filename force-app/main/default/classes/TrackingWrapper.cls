/**
 * @description     wrapper for tracking records
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class TrackingWrapper {
    
    /**
     * @description objectName
     */
    @AuraEnabled public String objectName;
    /**
     * @description objectLabel
     */
    @AuraEnabled public String objectLabel;
    /**
     * @description parentRef
     */
    @AuraEnabled public String parentRef;
    /**
     * @description events
     */
    @AuraEnabled public String events;
    /**
     * @description trackCreate
     */
    @AuraEnabled public Boolean trackCreate = false;
    /**
     * @description trackDelete
     */
    @AuraEnabled public Boolean trackDelete = false;
    /**
     * @description trackUndelete
     */
    @AuraEnabled public Boolean trackUndelete = false;
    /**
     * @description fields
     */
    @AuraEnabled public String fields;
    /**
     * @description additionalField1
     */
    @AuraEnabled public String additionalField1;
    /**
     * @description additionalField2
     */
    @AuraEnabled public String additionalField2;
    /**
     * @description mdtStatusClass
     */
    @AuraEnabled public String mdtStatusClass;
    /**
     * @description mdtStatusLabel
     */
    @AuraEnabled public String mdtStatusLabel;
    /**
     * @description trigStatusClass
     */
    @AuraEnabled public String trigStatusClass;
    /**
     * @description trigStatusLabel
     */
    @AuraEnabled public String trigStatusLabel;
    /**
     * @description fieldList
     */
    @AuraEnabled public List<TrackingFieldDefinition> fieldList;
    /**
     * @description parentRefMap
     */
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
     * @param original
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