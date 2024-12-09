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
                    fieldsToQuery = fieldsToQuery + String.escapeSingleQuotes(inputWrapper.fieldApiName);
                }
                if(string.isNotBlank(inputWrapper.otherFieldApiName)){
                    fieldsToQuery = fieldsToQuery + ', ' + String.escapeSingleQuotes(inputWrapper.otherFieldApiName);
                }
                String query = fieldsToQuery + ' FROM '+ String.escapeSingleQuotes(inputWrapper.objectApiName);
                String filterCriteria = String.escapeSingleQuotes(inputWrapper.fieldApiName) + ' LIKE ' + '\'' + String.escapeSingleQuotes(inputWrapper.searchString.trim()) + '%\' LIMIT 10';
                if(String.isNotBlank(inputWrapper.selectedRecordId)) {
                    query += ' WHERE Id = \''+ String.escapeSingleQuotes(inputWrapper.selectedRecordId) + '\'';
                }else if(String.isNotBlank(inputWrapper.parentFieldApiName) && String.isNotBlank(inputWrapper.parentRecordId)){
                    query += ' WHERE '+ String.escapeSingleQuotes(inputWrapper.parentFieldApiName)+ ' = \''+ String.escapeSingleQuotes(inputWrapper.parentRecordId) + '\'';
                    query += ' AND ' + filterCriteria;
                } 
                else {
                    query += ' WHERE '+ filterCriteria;
                }
                //query += '  WITH USER_MODE';
                List<ResultWrapper> returnWrapperList = new List<ResultWrapper>();
                Map<String, Object> binds = new Map<String, Object>{ };
                for(SObject s : Database.queryWithBinds(query, binds, AccessLevel.USER_MODE)) {
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
            System.debug(err.getMessage());
            return null;
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