@isTest(seeAllData=false) 
public class HelperClassWithoutSharingTest {
	@testSetup static void setupData() {
        
        ObjectCreator.initializeCustomSetting();
        ObjectCreator.TestEnviroment oc = new ObjectCreator.TestEnviroment();
        
        Account acc1 = [SELECT Id FROM Account LIMIT 1][0];
        acc1.Partner_Account_User__c = userinfo.getUserId();
        acc1.Partner_Account_Manager__c = userinfo.getUserId();
        acc1.Partner_Account_NC__c = userinfo.getUserId();
        update acc1;
        
        Account acc2 = ObjectCreator.getNewAccount();
        acc2.ParentId = acc1.Id;
        insert acc2;
        
        Account acc3 = ObjectCreator.getNewAccount();
        acc3.ParentId = acc2.Id;
        insert acc3;
        
        Account acc4 = ObjectCreator.getNewAccount();
        acc4.ParentId = acc3.Id;
        insert acc4;
        
        Account acc5 = ObjectCreator.getNewAccount();
        acc5.ParentId = acc4.Id;
        insert acc5;
        
    }
    
    @isTest(seeAllData=false) 
    public static void getFranchiseeHierarchyUsers_Test01(){
        Account acc1 = [SELECT Id, RecordTypeId FROM Account LIMIT 1][0];
        
        HelperClassWithoutSharing.getFranchiseeHierarchyUsers( new Set<Id>{acc1.Id}, true, true, true);
    }
    
    @isTest(seeAllData=false) 
    public static void getHerarchyIdByType_Test01(){
        Account acc1 = [SELECT Id, RecordTypeId FROM Account LIMIT 1][0];
        
        HelperClassWithoutSharing.getHerarchyIdByType( new Set<Id>{acc1.Id}, new Set<Id>{ acc1.RecordTypeId });
    }
    
    @isTest(seeAllData=false) 
    public static void getSubFranchisees_Test01(){
        Account acc1 = [SELECT Id FROM Account LIMIT 1][0];
        HelperClassWithoutSharing.getSubFranchisees( new Set<Id>{acc1.Id}, 1);
    }
    
    @isTest(seeAllData=false) 
    public static void getSubFranchiseeUsers_Test01(){
        Account acc1 = [SELECT Id FROM Account LIMIT 1][0];
        HelperClassWithoutSharing.getSubFranchiseeUsers( new Set<Id>{acc1.Id});
    }
    
    @isTest(seeAllData=false) 
    public static void logResults_Test01(){
        Account acc1 = ObjectCreator.getNewAccount();//[SELECT Id FROM Account LIMIT 1][0];
        insert acc1;
        
        try{
        HelperClassWithoutSharing.logResults( database.update(new List<Account>{ acc1 } ),'test');
        }catch(Exception e){}
        
        try{
        HelperClassWithoutSharing.logResults( database.delete(new List<Account>{ acc1 } ),'test');
        }catch(Exception e){}
    }
}