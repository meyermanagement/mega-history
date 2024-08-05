public without sharing class HistoryTrackingService {
    
    
    public static void track(List<Sobject> newList, Map<Id, sObject> oldMap, System.TriggerOperation operationType){
        System.debug(operationType.toString());
        // Possible values of the System.TriggerOperation enum are: BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE. 
        Schema.sObjectType objectType;
        if(newList != null){
            for(SObject so : newList) {
                objectType = Id.valueOf(String.valueOf(so.get('Id'))).getSObjectType();
                break;
            }
        } else {
            for(String recId : oldMap.keySet()) {
                objectType = Id.valueOf(recId).getSObjectType();
                break;
            }
        }
        System.debug(objectType);
        Tracked_Object__mdt tobj = Tracked_Object__mdt.getInstance(objectType.getDescribe().getName());
        System.debug(tobj);
        
    }
}