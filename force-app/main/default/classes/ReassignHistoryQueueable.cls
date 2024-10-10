/**
 * @description     Queueable Class to Reassign History records
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public class ReassignHistoryQueueable implements Queueable {

    /**
     * @description map of records to parent ids to replace
     */
    private Map<String, Map<String, String>> recordIdToParentRefMap;

    /**
     * @description constructor of queueable class
     * @param recordIdToParentRefMap
     */
    public ReassignHistoryQueueable(Map<String, Map<String, String>> inputMap){
        recordIdToParentRefMap = inputMap;
    }

    /**
     * @description execute method of queueable class
     * @param context
     */
    public void execute(QueueableContext context) {
        Boolean reachedLimit = false;
        System.debug(recordIdToParentRefMap);
        for(String recordId : recordIdToParentRefMap.keySet()){
            System.debug(reachedLimit);
            if(reachedLimit) break;
            System.debug(recordId);
            Map<String, String> oldToNewValuesMap = recordIdToParentRefMap.get(recordId);
            for(String oldId : oldToNewValuesMap.keySet()){
                System.debug(oldId);
                String queryRef = '%'+oldId+'%';
                Integer recordCountLimit = Limits.getLimitDMLRows() - Limits.getDMLRows();
                Integer queryCountLimit = Limits.getLimitQueries() - Limits.getQueries();
                Integer dmlCountLimit = Limits.getLimitDMLStatements() - Limits.getDMLStatements();
                System.debug(recordCountLimit);
                System.debug(queryCountLimit);
                System.debug(dmlCountLimit);
                if(queryCountLimit > 0 && dmlCountLimit > 0){
                    List<Record_History__c> histories = [SELECT Id, ParentId__c FROM Record_History__c WHERE Record__c = :recordId AND ParentId__c LIKE :queryRef LIMIT :recordCountLimit];
                    for(Record_History__c rh : histories){
                        rh.ParentId__c = rh.ParentId__c.replace(oldId, oldToNewValuesMap.get(oldId));
                    }
                    update histories;
                    recordCountLimit = Limits.getLimitDMLRows() - Limits.getDMLRows();
                    System.debug(recordCountLimit);
                    if(recordCountLimit > 0){
                        oldToNewValuesMap.remove(oldId);
                    }
                } else {
                    reachedLimit = true;
                    break;
                }
            }
            if(oldToNewValuesMap.isEmpty()){
                recordIdToParentRefMap.remove(recordId);
            }
        }
        if(!recordIdToParentRefMap.isEmpty()){
            System.enqueueJob(new ReassingHistoryQueueable(recordIdToParentRefMap));
        }
    }
}