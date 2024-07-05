@isTest
private class LastDayMeetingNotificationBatchTest {
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Date meetingDate1 = Date.today().addDays(-1);
        Meetings__c meeting1 = new Meetings__c(
            Status__c = 'Scheduled',
            Date_of_Meeting__c = meetingDate1,
            OwnerId = UserInfo.getUserId(),
            Account__c = testAccount.Id
        );
        insert meeting1;

        Date meetingDate2 = Date.today().addDays(-2);
        Meetings__c meeting2 = new Meetings__c(
            Status__c = 'Scheduled',
            Date_of_Meeting__c = meetingDate2,
            OwnerId = UserInfo.getUserId(),
            Account__c = testAccount.Id
        );
        insert meeting2;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new LastDayMeetingNotificationBatch());
        Test.stopTest();
    }
}