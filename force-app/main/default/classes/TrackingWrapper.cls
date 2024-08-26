global with sharing class TrackingWrapper {
    
    @AuraEnabled global String objectName;
    @AuraEnabled global String objectLabel;
    @AuraEnabled global String parentRef;
    @AuraEnabled global String events;
    @AuraEnabled global Boolean trackCreate = false;
    @AuraEnabled global Boolean trackDelete = false;
    @AuraEnabled global Boolean trackUndelete = false;
    @AuraEnabled global String fields;
    @AuraEnabled global String additionalField1;
    @AuraEnabled global String additionalField2;
    @AuraEnabled global String mdtStatusClass;
    @AuraEnabled global String mdtStatusLabel;
    @AuraEnabled global String trigStatusClass;
    @AuraEnabled global String trigStatusLabel;
    @AuraEnabled global List<TrackingFieldDefinition> fieldList;
    @AuraEnabled global Map<String, String> parentRefMap;

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

    public TrackingWrapper(TrackingWrapper original){
        this.objectName = original.objectName;
        this.objectLabel = original.objectLabel;
        this.parentRef = original.parentRef;
        this.events = original.events;
        this.fields = original.fields;
        this.additionalField1 = original.additionalField1;
        this.additionalField2 = original.additionalField2;
    }
}