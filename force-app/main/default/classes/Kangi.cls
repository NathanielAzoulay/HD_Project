/**************************************************************
Name              : Kangi
Description       : WS for kangi login.
Created/Modified by   Created/Modified Date                       
-------------------------------------------------------------
1. Rashad Saeed        18/08/2016                 
*************************************************************/
@RestResource(urlMapping='/Kangi/*')
global without sharing class Kangi {
    /*
@HttpGet
global static service doGet() {
service sr = new service('');
RestRequest req = RestContext.request;
RestResponse res = RestContext.response;
res.addHeader('Content-Type', 'application/json'); 
if (!req.params.containsKey('KToken')) {
sr = new service('KToken parameter missing'); 
res.statusCode = 400 ;
res.responseBody = Blob.valueOf('KToken parameter missing.');
return sr;
}

else 
if  ((Kangi__c.getAll().values().Site_Token__c).trim() != req.params.get('KToken')) {
sr = new service('Token does not match ');
res.statusCode = 400 ;
res.responseBody = Blob.valueOf('KToken parameter missing.');
}
else
if (!req.params.containsKey('username') )
//sr = new service([select Date_of_Birth__c , FirstName , LastName from contact where Kangi_User_Name__c =: req.params.get('username') limit 1]);
sr = new service('UserName parameter missing.');
else
if (!req.params.containsKey('password'))
sr = new service('Password parameter missing.');
else
{

String query = ((Kangi__c.getAll().values().query__c).trim());
query += ' from contact where Kangi_User_Name__c='+'\''+req.params.get('username')+'\'';
List <contact> conlist =  database.query(query);

[select Id ,Gender__c, FirstName , LastName , Kangi_Password__c ,
(select Name, Course_Name__c from LG_Students__r  )
from contact where Kangi_User_Name__c =: req.params.get('username') limit 10
];


if (conlist.size()==0)
sr = new service('Username does not match');
else 
if (conlist.size()!=1)
sr = new service('there is more than username in SF system !! ');

else 
if (conlist[0].Kangi_Password__c != req.params.get('password'))
sr = new service('password does not match ');
else
sr = new service(conlist[0]); 
}

return sr;

}*/

    @HttpPost
    global static service doPost(String username, String password, String appname, String action) {
        System.debug('username: '+username+' password: '+password+' appname: '+appname+'action: '+ action);   
        RestRequest req = RestContext.request;
        
        string key = req.headers.get('X-Api-Key');
        
        /*if (action=='NotifyExtLogin'){
            return NotifyExtLogin(username);*/
        if (action =='login'){ 
            return KangiLogin (username, password, appname);
        }                                    
        if (action == 'authorization'){
            return Authorize(username, key);
        }

        RestResponse res = Restcontext.response;
        res.statuscode=400; //BAD_REQUEST (if params are missing)
        return null;

        //String token = string.valueOf(system.today().day()); 
        //token+=(Kangi__c.getAll().values().Site_Token__c).trim()+string.valueOf(system.today().month());    
    }

    /*public static service NotifyExtLogin(String username){
        service sr = new service('');
        
        sr.request = 'NotifyExtLogin';
        sr.music_centre = null;
        List <Lead> rLead = [select Name, Id,Total_Number_Of_Login__c,Accept_marketing__c  from Lead where User_Name__c=:username];
        if (rLead.isEmpty()){
            sr.rResult= new Result('0','User Name not found ',false,'');
            //('User Name not found ',false,'');
        }
        
        else 
            if (rLead.Size()>1)
            sr.rResult= new Result('0','duplicate username ',false,'');
            
        else 
            if (rLead.Size()==1){
                if(  rLead[0].Total_Number_Of_Login__c ==0){
                    rLead[0].HasOptedOutOfEmail =!rLead[0].Accept_marketing__c;   
                    if (rLead[0].Status <>'1' )
                        rLead[0].Status ='1';
                }                                                    
                rLead[0].Last_Login__c = System.now();
                rLead[0].Total_Number_Of_Login__c +=1;
                Database.SaveResult[] srList = Database.Update(rLead, false);
                for (Database.SaveResult sr1 : srList) {
                    if (sr1.isSuccess())
                    sr.rResult= new Result('1','',true,sr1.getId());  
                    else
                    sr.rResult= new Result(String.ValueOf (sr1.getErrors()[0].getMessage()),'Error Update Lead',false,(String)sr1.getId());   
                } 
            }
        return Sr;
    }*/

    public static service KangiLogin(String username, String password, String appname){

        RestResponse res = Restcontext.response;
        res.statuscode=400; //BAD_REQUEST (if params are missing)
        service sr = new service('');

        if (username==null)
            return new service('username missing'); 
        else if (password==null)
            return new service('password missing'); 
        else if (appname==null)
            return new service('appname missing'); 

        String query = ((Kangi__c.getAll().values().query__c).trim());
        query += ((Kangi__c.getAll().values().Additional_contact_fields__c).trim());
        query += ' from contact where Kangi_User_Name__c='+'\''+username+'\'';
        List <Contact> conlist =  database.query(query); 
        
        res.statuscode=401; //Unauthorized (if login data is not ok)

        if (conlist.size()==0)
            sr = new service('Username does not match');
        else if (conlist.size()!=1)
            sr = new service('there is more than one username in SF system !! ');
        else if (conlist[0].Kangi_Password__c != password)
            sr = new service('password does not match');
        else{
            res.statuscode=200; //OK
            
            if(conlist[0].Kangi_Status__c == 'Active'){
                if (appname == 'Kangi') {  
                    conlist[0].Last_Login_Date__c = system.now();
                    conlist[0].No_Of_LogIns__c = conlist[0].No_Of_LogIns__c != null ? conlist[0].No_Of_LogIns__c + 1 : 1;
                    update conlist[0]; 
                }else if(appname == 'Stream'){
                    conlist[0].Last_Stream_login_date__c = system.now();
                    conlist[0].No_of_Stream_logins__c = conlist[0].No_of_Stream_logins__c != null ? conlist[0].No_of_Stream_logins__c + 1 : 1;
                    update conlist[0]; 
                }else if(appname == 'Flashcards'){
                    conlist[0].Last_Flashcards_Login__c = system.now();
                    conlist[0].No_of_Flashcards_logins__c = conlist[0].No_of_Flashcards_logins__c != null ? conlist[0].No_of_Flashcards_logins__c + 1 : 1;
                    update conlist[0]; 
                }else{
                    sr = new service('appname does not match');
                    res.statuscode=401;
                }
            }
        }
        return sr;
    }
    
    public static service Authorize(String username, String key){
        RestResponse res = Restcontext.response;
        res.statuscode=400; //BAD_REQUEST (if params are missing)
        service sr = new service('');

        if (username==null)
            return new service('username is missing'); 
            
        if (key==null)
            return new service('Api key is missing'); 
        
        res.statuscode=401; //Unauthorized (if login data is not ok)

        String apiKey = ((Kangi__c.getAll().values().Api_key__c).trim());
        if(apiKey != key){
            return new service('key does not match'); 
        }

        String query = ((Kangi__c.getAll().values().query__c).trim());
        query += ((Kangi__c.getAll().values().Additional_contact_fields__c).trim());
        query += ' from contact where Kangi_User_Name__c='+'\''+username+'\'';
        List <Contact> conlist =  database.query(query); 

        if (conlist.size()==0)
            sr = new service('Username does not match');
        else if (conlist.size()!=1)
            sr = new service('there is more than one username in SF system !! ');
        else{
            res.statuscode=200; //OK
            sr = new service(conlist[0]);
        }

        sr.request = 'authorization';
        return sr;
    }

    global class service{
        Sobject SFContact;  
        String request = 'login';  
        String Error = '';
        String music_centre ='yes';
        String entity_type ='';
        String downloads = '';
        List <Sobject> SFsets;
        List <Sobject> SFBaseCourse;
        Result rResult;

        Public service(Contact con ){
            this.SFContact= con;
            entity_type = con.recordtype.name;
            //SFsets = [select Name, Course_Name__c ,BC_Old_ID__c ,Student_Course_End_Date__c from LG_Student__c where Student__c =:con.id];
            SFsets =  database.query(((Kangi__c.getAll().values().LGS__c).trim())+' from LG_Student__c where Student__c = '+'\''+con.id+'\'');
            if (con.account.Allow_Download__c == true)
                downloads='yes';
            else
                downloads='no';
            //SFsets = [select Id , Name , firstName , lastName from contact limit 15];
            if (con.Program_Type__c != null){
                List <String> includesList  = con.Program_Type__c.split(';');
                
                List<Schema.FieldSetMember> lsBCFieldSet= readFieldSet('Base_Course__c').get('BCJsonRest');
                String query = 'SELECT ';
                for(Schema.FieldSetMember f : lsBCFieldSet) {
                    query += f.getFieldPath() + ', ';
                }
                
                query = query.substring(0,query.lastIndexOf(','));
                query += ' FROM Base_Course__c where Program_Type__c includes(';
                for(String includeValue :includesList)
                    query += '\''+includeValue+'\''+',';
                query = query.removeEnd(',') +')';
                query+=' And Status__c ='+'\'Active\'';
                SFBaseCourse=database.query(query);
            }
        }

        Public service(String Error){
            this.Error = Error;
        }

        Public service(Result rResult){
          this.rResult = rResult;
        }
    }

    global class Result {
        String result='';
        String Error='';
        Boolean isSuccess = false;
        String RecordId ='';

        Public Result (){
            
        }

        Public Result (  String result, String Error,Boolean isSuccess,String RecordId ){
           this.result=result;
           this.Error=Error;
           this.isSuccess= isSuccess;
           this.RecordId = RecordId;
        }
    }

    public static Map<String,List<Schema.FieldSetMember>> readFieldSet(String ObjectName){
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Map<String,List<Schema.FieldSetMember>> mapFieldsOfFieldSet = new Map<String,List<Schema.FieldSetMember>>();
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        for(String fSetName : DescribeSObjectResultObj.FieldSets.getMap().KeySet()){
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fSetName);
            mapFieldsOfFieldSet.put(DescribeSObjectResultObj.FieldSets.getMap().get(fSetName).getLabel(),fieldSetObj.getFields());
        }
        return mapFieldsOfFieldSet; 
    }
    
}