/**
 * @description     Controller for the Reusable Lookup LWC
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public with sharing class ReusableLookupController {

    /**
     * @description     get records
     * @param input
     * @return List of ResultWrappers
     */
    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> fetchRecords(String input) {
        try {
            if(input != null){
                SearchWrapper inputWrapper = (SearchWrapper)JSON.deserialize(input, SearchWrapper.class);
                String fieldsToQuery = 'SELECT Id, ';
                if(string.isNotBlank(inputWrapper.fieldApiName)){
                    fieldsToQuery = fieldsToQuery + inputWrapper.fieldApiName;
                }
                if(string.isNotBlank(inputWrapper.otherFieldApiName)){
                    fieldsToQuery = fieldsToQuery + ', ' + inputWrapper.otherFieldApiName;
                }
                String query = fieldsToQuery + ' FROM '+ inputWrapper.objectApiName;
                String filterCriteria = inputWrapper.fieldApiName + ' LIKE ' + '\'' + String.escapeSingleQuotes(inputWrapper.searchString.trim()) + '%\' LIMIT 10';
                if(String.isNotBlank(inputWrapper.selectedRecordId)) {
                    query += ' WHERE Id = \''+ inputWrapper.selectedRecordId + '\'';
                }else if(String.isNotBlank(inputWrapper.parentFieldApiName) && String.isNotBlank(inputWrapper.parentRecordId)){
                    query += ' WHERE '+ inputWrapper.parentFieldApiName+ ' = \''+ inputWrapper.parentRecordId + '\'';
                    query += ' AND ' + filterCriteria;
                } 
                else {
                    query += ' WHERE '+ filterCriteria;
                }
                List<ResultWrapper> returnWrapperList = new List<ResultWrapper>();
                for(SObject s : Database.query(query)) {
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.mainField = (String)s.get(inputWrapper.fieldApiName);
                    wrap.subField = (String)s.get(inputWrapper.otherFieldApiName);
                    wrap.id = (String)s.get('id');
                    returnWrapperList.add(wrap);
                }
                return returnWrapperList;
            }
            return null;
        } catch (Exception err) {
            throw new AuraHandledException(err.getMessage());
        }
    }

    /**
     * @description Result Wrapper
     */
    public class ResultWrapper{
        /**
         * @description Result mainField
         */
        @AuraEnabled public String mainField{get;set;}
        /**
         * @description Result subField
         */
        @AuraEnabled public String subField{get;set;}
        /**
         * @description Result id
         */
        @AuraEnabled public String id{get;set;}
    }

    /**
     * @description Search Wrapper
     */
    public class SearchWrapper {
        /**
         * @description objectApiName
         */
        @AuraEnabled public String objectApiName{get;set;}
        /**
         * @description fieldApiName
         */
        @AuraEnabled public String fieldApiName{get;set;}
        /**
         * @description otherFieldApiName
         */
        @AuraEnabled public String otherFieldApiName{get;set;}
        /**
         * @description searchString
         */
        @AuraEnabled public String searchString{get;set;}
        /**
         * @description selectedRecordId
         */
        @AuraEnabled public String selectedRecordId{get;set;}
        /**
         * @description parentRecordId
         */
        @AuraEnabled public String parentRecordId{get;set;}
        /**
         * @description parentFieldApiName
         */
        @AuraEnabled public String parentFieldApiName{get;set;}
    }
}