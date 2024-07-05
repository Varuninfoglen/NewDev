@isTest
private class MeetingReminderBatchTest {
    
     @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Date meetingDate = Date.today().addDays(+1);
        Meetings__c meetings = new Meetings__c(
            Status__c = 'Scheduled',
            Date_of_Meeting__c = meetingDate,
            OwnerId = UserInfo.getUserId(),  
            Account__c = testAccount.Id  
        );
        insert meetings;
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new MeetingReminderBatch());
        Test.stopTest();
    }   
}