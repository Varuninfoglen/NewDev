public class LastDayMeetingNotificationBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    Date meetingDate = Date.today().addDays(-1);
    String subject = 'Daily Meeting Notification';
    String emailOpeningLine = 'I hope this message finds you well!';
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Start method');
        String query = 'SELECT Id, Owner.Name, Owner.Email, Subject__c, OwnerId, Name, Lead__r.Name, Opportunity__r.Name, Account__r.Name, Status__c, Date_of_Meeting__c, Meeting_Link__c ' +
            'FROM Meetings__c ' +
            'WHERE DAY_ONLY(Date_of_Meeting__c) = :meetingDate AND Status__c = \'Scheduled\'';
        try{
            return Database.getQueryLocator(query);}
        catch (Exception e) {
            HandleCustomException.LogException(e, 'General Exception');
            throw e;
        }
    }
    
    public void execute(Database.BatchableContext bc, List<Meetings__c> meetinglist) {
        System.debug('Execute method start -> ' + meetinglist.size() + ' records');
        
        try {
            Map<Id, List<Meetings__c>> userIdToMeetingList = new Map<Id, List<Meetings__c>>();
            for (Meetings__c meeting : meetinglist) {
                if (!userIdToMeetingList.containsKey(meeting.OwnerId)) {
                    userIdToMeetingList.put(meeting.OwnerId, new List<Meetings__c>());
                }
                userIdToMeetingList.get(meeting.OwnerId).add(meeting);
            }
            
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Email FROM User WHERE Id IN :userIdToMeetingList.keySet()]);
            OrgWideEmailAddress[] owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'taskmanager@infoglen.com'];
            
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            for (Id userId : userIdToMeetingList.keySet()) {
                User userRecord = userMap.get(userId);
                if (userRecord != null) {
                    Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
                    // singleEmail.setToAddresses(new List<String>{userRecord.Email});
                    singleEmail.setCcAddresses(new List<String>{'varunkovuri5@gmail.com'});  
                    singleEmail.setSubject(this.subject);
                    singleEmail.setHtmlBody(getEmailHtmlBody(userRecord.Name, userIdToMeetingList.get(userId)));
                    if (!owea.isEmpty()) {
                        singleEmail.setOrgWideEmailAddressId(owea[0].Id);
                    }
                    emailsToSend.add(singleEmail);
                }
            }
            
            if (!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
            }
        } catch (Exception e) {
            HandleCustomException.LogException(e, 'General Exception');
            throw e;
        }
    }
    
    public void finish(Database.BatchableContext bc) {
       system.debug('LastDayMeetingNotificationBatch completed at Finish Method');
    }
    
    public void execute(SchedulableContext SC) {
        try {
            LastDayMeetingNotificationBatch lb = new LastDayMeetingNotificationBatch();
            Database.executeBatch(lb);
        } catch (Exception e) {
            HandleCustomException.LogException(e, 'Schedulable Execution');
            throw e; 
        }
    }
    
    public String getEmailHtmlBody(String ownerName, List<Meetings__c> meetingList) {
         String body = 'Hello ' + ownerName + ',<br><br>';
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        body += emailOpeningLine;
        body += '<br><br>';
        body += 'We are reaching out to remind you about updating the meeting records in Salesforce. We have identified some meetings that are currently recorded with past dates. To ensure our records are accurate, please take the following actions:<br><br>';
        body += '<strong>If a meeting has been rescheduled:</strong> Update the meeting date to the new future date.<br>';
        body += '<strong>If a meeting has already occurred:</strong> Change the meeting status to "Held."<br><br>';
        body += '<table border="1" style="border-collapse: collapse; width: 100%">';
        body += '<tr>';
        body += '<th style="padding: 8px; text-align: center;">Meeting ID</th>';
        body += '<th style="padding: 8px; text-align: center;">Account</th>';
        body += '<th style="padding: 8px; text-align: center;">Lead</th>';    
        body += '<th style="padding: 8px; text-align: center;">Opportunity</th>';
        body += '<th style="padding: 8px; text-align: center;">Status</th>';
        body += '<th style="padding: 8px; text-align: center;">Date and Time</th>';
        body += '<th style="padding: 8px; text-align: center;">Subject</th>';
        body += '</tr>';
        for (Meetings__c meeting : meetingList) {
            body += '<tr>';
            body += '<td style="padding: 8px; text-align: center;"><a href="' + baseUrl + '/' + meeting.Id + '">' + meeting.Name + '</a></td>';
            body += '<td style="padding: 8px; text-align: center;">' + (meeting.Account__r != null ? meeting.Account__r.Name : '') + '</td>';
            body += '<td style="padding: 8px; text-align: center;">' + (meeting.Lead__c != null ? meeting.Lead__r.Name : '') + '</td>';
            body += '<td style="padding: 8px; text-align: center;">' + (meeting.Opportunity__c != null ? meeting.Opportunity__r.Name : '') + '</td>'; 
            body += '<td style="padding: 8px; text-align: center;">' + meeting.Status__c + '</td>';
            body += '<td style="padding: 8px; text-align: center;">' + meeting.Date_of_Meeting__c + '</td>';
            body += '<td style="padding: 8px; text-align: center;">' + (meeting.Subject__c != null ? meeting.Subject__c : '') + '</td>';
            body += '</tr>';
        }
        body += '</table><br><br>';
        body += 'Thank you for your prompt attention to this matter.<br>';
        body += 'Best regards,<br>';
        body += 'Company Team';
        return body;

    }
}