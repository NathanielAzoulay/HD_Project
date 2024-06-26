@isTest
public class Kangi_ws_test {


    @TestSetup
    static void createData(){
        
		insert new Kangi__c(Site_Token__c = '123',Name='Testing', Api_key__c='77777777', 
                            Additional_contact_fields__c =',No_Of_LogIns__c,No_of_Stream_logins__c, (select name,Base_Course__r.BC_Old_ID__c,Base_Course__r.Name from Teacher_Qualifications__r)',
                            query__c='select Status__c,Id ,Gender__c, FirstName , LastName , Kangi_Password__c , Generic_Kangi_Credentials__c, License__c,Date_of_Birth__c,MailingCountry,Kangi_Status__c,Account.Allow_Download__c,RecordType.Name,LastModifiedDate,Program_Type__c, Language_c__c'
                           ,LGS__c='select Name, Course_Name__c ,BC_Old_ID__c ,Student_Course_End_Date__c,Status_in_LG__c');
        Account Acc= ObjectCreator.getNewAccount();
        Acc.BillingCountry = 'France';
        Acc.Email__c = 'test@test.com';
        insert Acc;
        Id RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();
        Contact con = new Contact(Program_Type__c='HDE',FirstName = 'name', LastName = 'name', AccountId = acc.id, RecordTypeId = RecordTypeId,Kangi_User_Name__c='123456',Kangi_Password__c='123456', Kangi_Status__c='Active');
        //Contact con1 = new Contact(FirstName = 'name', LastName = 'name', AccountId = acc.id, RecordTypeId = RecordTypeId,Kangi_User_Name__c='Rashad',Kangi_Password__c='saeed');

        insert con ;
        con.Kangi_Password__c ='123456';
        con.Kangi_User_Name__c ='123456';
        Update con;
    }


    @isTest
    private static void test_login(){
        RestRequest testRestRequest = new RestRequest();
        RestResponse testRestResponse = new RestResponse();

        Kangi.readFieldSet('Base_Course__c').get('BCJsonRest');
        Test.startTest();

        testRestRequest.requestBody = blob.valueOf('{"username" : "123456","password" : "123456","appname" : "Kangi"}');
        testRestRequest.requestURI = '/services/apexrest/Kangi/';
        testRestRequest.httpMethod = 'POST';
        RestContext.request = testRestRequest;
        RestContext.response = testRestResponse;
      
        Kangi.doPost('123456', null, 'appname','login');
        Kangi.doPost(null,'123456', 'appname','login');
        Kangi.doPost('123456','123456', null,'login');
        Kangi.doPost('123456','123456', 'Kangi','');
        Kangi.doPost('123456','123456', 'Kangi','login');
        Kangi.doPost('123456','aaa', 'Kangi','login');
        Kangi.doPost('123456','123456', 'Stream','login');
        Kangi.doPost('123456','123456', 'Flashcards','login');
        Kangi.doPost('123456','123456', 'Donkey','login');
        Kangi.doPost('Fiona','Shrek', 'Kangi','login');

        
        /*Lead RLead1 = new Lead (FirstName='Rashad',LastName='Saeed',Email='saee.rashad@gmail.com',User_Name__c='Rashad',Company='HD');
        Lead RLead2 = new Lead (FirstName='Rasthadd',LastName='Saeetd',Email='saee.rashad2@gmail.com',Company='HD');
        Lead RLead3 = new Lead (FirstName='Test',LastName='tt',Email='saee.rashad3@gmail.com',Company='HD');
        List <Lead>Llist = new List <Lead>();
        Llist.add(RLead1);
        Llist.add(RLead2);
        Llist.add(RLead3);
		Insert Llist;
        Kangi.NotifyExtLogin ('');
        Kangi.NotifyExtLogin('Rashadd');*/
        
        //kangi.doPost('Rashad','Password', 'appname','NotifyExtLogin'); 
    /*
        RestContext.request = testRestRequest;
        RestContext.response = testRestResponse;
        //kangi.doget();
        kangi.doPost('123456','123456', null);
        testRestRequest.httpMethod = 'POST';
        RestContext.request = testRestRequest;
        RestContext.response = testRestResponse;
        //kangi.doget();
        kangi.doPost('123456', '123456', 'kangi');
        //kangi.doPost('1234564', '123456', 'appname');
        //kangi.doPost('123456', '1234564', 'appname');*/
        Test.stopTest();
    }

    @isTest
    private static void test_authorize(){
        RestRequest testRestRequest = new RestRequest();
        RestResponse testRestResponse = new RestResponse();

        testRestRequest.requestBody = blob.valueOf('{"username" : "123456","password" : "123456","appname" : "Kangi"}');
        testRestRequest.requestURI = '/services/apexrest/Kangi/';
        testRestRequest.httpMethod = 'POST';
        testRestRequest.headers.put('X-Api-Key','77777777');
        RestContext.request = testRestRequest;
        RestContext.response = testRestResponse;

        Kangi.doPost(null, null, null,'authorization');
        Kangi.doPost('123456', null, null,'authorization');
    }
}