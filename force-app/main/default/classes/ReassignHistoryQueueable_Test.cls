/**
 * @description     test for 
 * @author          Mark Meyer
 * @date            09/27/2024
 */
@isTest
public class ReassignHistoryQueueable_Test {

    /**
     * @description     test queueable
     */
    @isTest public static void testSmallUpdate(){
        Account acc = new Account(Name = 'test');
        insert acc;
        Account acc1 = new Account(Name = 'test2');
        insert acc1;
        Contact cnt = new Contact(LastName = 'test', AccountId = acc.Id);
        insert cnt;
        Record_History__c rh = new Record_History__c();
        rh.Record__c = cnt.Id;
        rh.Record_Name__c = cnt.LastName;
        rh.ParentId__c = acc.Id;
        rh.Event__c = 'Updated';
        insert rh;
        
        Map<String, Map<String, String>> recordIdToParentRefMap = new Map<String, Map<String, String>>();
        recordIdToParentRefMap.put(cnt.Id, new Map<String, String>{acc.Id=>acc1.Id});
        Test.startTest();
        System.enqueueJob(new ReassignHistoryQueueable(recordIdToParentRefMap));
        Test.stopTest();
        List<Record_History__c> result = [SELECT Id, ParentId__c FROM Record_History__c WHERE Id = :rh.Id];
        System.assertEquals(1, result.size(), 'Result size not as expected');
        System.assertEquals(acc1.Id, result[0].ParentId__c, 'Result size not as expected');
    }

    /**
     * @description     test queueable
     */
    @isTest public static void testLargeUpdate(){
        Account acc = new Account(Name = 'test');
        insert acc;
        Account acc1 = new Account(Name = 'test2');
        insert acc1;
        Contact cnt = new Contact(LastName = 'test', AccountId = acc.Id);
        insert cnt;
        Contact cnt2 = new Contact(LastName = 'test2', AccountId = acc1.Id);
        insert cnt2;
        Task t = new Task(WhatId=acc.Id, WhoId=cnt.Id, Subject='Test');
        insert t;

        List<Record_History__c> histories = new List<Record_History__c>();
        for(Integer i = 0; i < 10; i++){
            Record_History__c rh = new Record_History__c();
            rh.Record__c = cnt.Id;
            rh.Record_Name__c = cnt.LastName;
            rh.ParentId__c = acc.Id;
            rh.Event__c = 'Updated';
            histories.add(rh);
        }
        for(Integer i = 0; i < 10; i++){
            Record_History__c rh = new Record_History__c();
            rh.Record__c = t.Id;
            rh.Record_Name__c = t.Subject;
            rh.ParentId__c = acc.Id;
            rh.Event__c = 'Updated';
            histories.add(rh);
        }
        for(Integer i = 0; i < 10; i++){
            Record_History__c rh = new Record_History__c();
            rh.Record__c = t.Id;
            rh.Record_Name__c = t.Subject;
            rh.ParentId__c = cnt.Id;
            rh.Event__c = 'Updated';
            histories.add(rh);
        }
        insert histories;
        
        Map<String, Map<String, String>> recordIdToParentRefMap = new Map<String, Map<String, String>>();
        recordIdToParentRefMap.put(cnt.Id, new Map<String, String>{acc.Id=>acc1.Id});
        recordIdToParentRefMap.put(t.Id, new Map<String, String>{acc.Id=>acc1.Id, cnt.Id=>cnt2.Id});
        Test.startTest();
        System.enqueueJob(new ReassignHistoryQueueable(recordIdToParentRefMap));
        Test.stopTest();
        List<Record_History__c> result = [SELECT Id, ParentId__c FROM Record_History__c WHERE ParentId__c = :acc1.Id];
        System.assertEquals(20, result.size(), 'Result size not as expected');
        result = [SELECT Id, ParentId__c FROM Record_History__c WHERE ParentId__c = :cnt2.Id];
        System.assertEquals(10, result.size(), 'Result size not as expected');
    }
}