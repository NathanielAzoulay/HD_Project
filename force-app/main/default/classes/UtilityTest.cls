@isTest 
Private class UtilityTest {
    public static testMethod void test() {
        //Creating Account
        Account acc = new Account(Name = 'TestAccount', BillingStreet ='1600 Amphitheatre Pkwy',BillingCity ='Mountain View' ,BillingState ='Alava', BillingCountry='Spain');
        insert acc;
        system.assert(acc.Id != null);
        
        String objName = 'Account';
        String body = '<ul><li>{!account.name}{!account.billingaddress}{!account.phone}</li><li>{!$account.name}- {!$User.Country} - {!$System.Now} - {!account.owner.Name}-{!account.name}</li><li><div style="display:{!IF(Account.IsCustomerPortal,"block","none")}"> Place your content here. </div></li><li><div><div style="display: none;">{"relatedList": { "ObjectName": "Contact", "tableSchema": { "columns": [ { "name": "FirstName" } ,{ "name": "LastName" } ,{ "name": "Email" } ,{ "name": "MailingAddress" } ] }, "sortorder": "", "filter": "" } }</div><table border="1" cellpadding="0" cellspacing="0"><tbody><tr><th colspan="1" rowspan="1">FirstName</th><th colspan="1" rowspan="1">LastName</th><th colspan="1" rowspan="1">Email</th><th colspan="1" rowspan="1">MailingAddress</th></tr></tbody></table><p> </p><div></li></ul><p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p>';
        
        //Verifying that Body Contains the pattern '{!$'+ObjName+'.'
        //System.assert(body.containsIgnoreCase('{!$'+ObjName+'.'));
        
        Id recId = acc.Id;
        List<SelectOption> selectedList = new List<SelectOption>();
        selectedList.add(new SelectOption('Name',acc.Name));
        
        //Start test
        test.startTest();
        
        //Calling Utility Methods
        Utility.PopulateMergeFields(body,recId,objName);
        Utility.ParseRelatedList(body,acc.ID,'Account');
        Utility.populateGlobalMergeFields(body,recId,objName);
        Utility.executeConditionalLogic(body,recId,objName);
        Utility.getSortedList(selectedList);
        Utility.getAddress(acc,'BillingAddress');
        Utility.TemplateWrapper tw = new Utility.TemplateWrapper();
        Utility.TableWrapper tbW = new Utility.TableWrapper();
        Utility.relatedListWrapper rlW = new Utility.relatedListWrapper('Account');
        
        //Stop Test
        test.stopTest();
    }
    public static testMethod void test2() {
        //Creating Account
        Account acc = new Account(Name = 'TestAccount', BillingStreet ='1600 Amphitheatre Pkwy',BillingCity ='Mountain View' ,BillingState ='Asturias', BillingCountry='Spain');
        insert acc;
        system.assert(acc.Id != null);
        
        Opportunity op = new Opportunity(AccountId=acc.Id, name = 'test opp', StageName='prospecting', closeDate = system.today());
        Insert op;
        system.assert(op.Id != null);
        
        String objName = 'Opportunity';
        String body = '<ul><li>{!Opportunity.name} - {!Opportunity.closeDate} - {!Opportunity.Isdeleted} - {!opportunity.Amount} - {!Opportunity.probability}</li><li> {!$User.Country} - {!$System.Now} </li><li><div style="display:{!IF(Opportunity.IsDeleted,&#39;block&#39;,&#39;none&#39;)}"> Place your content here. </div></li><li></li></ul><p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p>';
        
        //Verifying that Body Contains the pattern '{!$'+ObjName+'.'
        //System.assert(body.containsIgnoreCase('{!$'+ObjName+'.'));
        
        Id recId = acc.Id;
        List<SelectOption> selectedList = new List<SelectOption>();
        selectedList.add(new SelectOption('Name',acc.Name));
        
        //Start test
        test.startTest();
        
        //Calling Utility Methods
        Utility.populateGlobalMergeFields(body,recId,objName);
        Utility.executeConditionalLogic(body,recId,objName);
        Utility.ParseRelatedList(body,acc.ID,'Account');
        Utility.getSortedList(selectedList);
        Utility.getAddress(acc,'BillingAddress');
        Utility.TemplateWrapper tw = new Utility.TemplateWrapper();
        Utility.TableWrapper tbW = new Utility.TableWrapper();
        Utility.relatedListWrapper rlW = new Utility.relatedListWrapper('Account');
        Sobject sb = (Sobject)op;
        Utility.getCurrencySymbol(sb);
        //Stop Test
        test.stopTest();
    }
}