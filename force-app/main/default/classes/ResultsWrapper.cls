/**
 * @description     wrapper for query result records
 * @author          Mark Meyer
 * @date            01/22/2025
 */
public class ResultsWrapper{
    /**
     * @description Result mainField
     */
    @AuraEnabled public String mainField{get;set;}
    /**
     * @description Result subField
     */
    @AuraEnabled public String subField{get;set;}
    /**
     * @description Result parentIds
     */
    @AuraEnabled public String parentIds{get;set;}
    /**
     * @description Result id
     */
    @AuraEnabled public String id{get;set;}
}