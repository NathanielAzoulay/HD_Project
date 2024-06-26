public class Schedular_MassEmail implements Schedulable{
    /**
     * Execute Method of scheduler
     */
    public void execute(SchedulableContext sc) {
        list<User> users = [select Id,Mass_Email_Limit_in_Counter_period__c, Counter_period__c,Last_Reset_Time__c,
                                Mass_Email_Limit__c, Counter__c from User where Id = :UserInfo.getUserId() limit 9999];
        for(User u : users){
            u.Counter__c = 0;
            u.Last_Reset_Time__c = system.now();
        }
        update users;
    }
}