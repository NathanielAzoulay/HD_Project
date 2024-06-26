@isTest
public class CaseComment_Test {

    @isTest(seeAllData=false)
    static void NewCaseCommentOnResolvedCase_Test(){
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Account partnerAcc = ObjectCreator.getNewAccount();
        partnerAcc.Account_Type__c = 'MF';
        insert partnerAcc;
        
        Case c = new Case();
        c.AccountId = partnerAcc.id;
        insert c;
        
        CaseComment cc = new CaseComment();
        cc.IsPublished = true;
        cc.CommentBody = 'test';
        cc.ParentId = c.Id;
        insert cc;
        
        c.Status = 'Resolved';        
        update c;        
        
        CaseComment newChild = cc.clone(false, false);
        newChild.ParentId = c.Id;
        list<CaseComment> newCaseComment_list = new list<CaseComment>();        
        newCaseComment_list.add(newChild);
        try{
        	insert newCaseComment_list;
        }
        catch(Exception ex){
            Boolean expectedExceptionThrown =  ex.getMessage().contains(Label.VR_message_Task_000001922) ? true : false;
            System.assertEquals(true,expectedExceptionThrown,Label.VR_message_Task_000001922);
        }
        List<Id> idsToPurge = new List<Id>();
        idsToPurge.add(cc.Id); 
        delete cc;
        Database.emptyRecycleBin(idsToPurge);
        CaseComment_Handler handler = new CaseComment_Handler();
        handler.OnBeforeInsert(null);
        System.assertEquals(true, ApexPages.hasMessages(),Label.VR_message_Task_000001922);
    }
    
}