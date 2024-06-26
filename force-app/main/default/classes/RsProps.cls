/**************************************************************
Name              : Props
Description       : Restfor Props login.
Created/Modified by   Created/Modified Date                       
-------------------------------------------------------------
1. Rashad Saeed        10/5/2017                 
*************************************************************/
@RestResource(urlMapping='/RsProps/*')
global without sharing class RsProps {
    global class service{
        Integer answer =0; 
        String Error = '';
        Public service (Integer Res)
        {
            this.answer = Res;
        }
        Public service(String Error,Integer Res){
            this.Error = Error;
            this.answer = Res;
        }
    }
    @HttpPost 
    global static service doPost(String username,String password, String appname) {
        /*
        0 – name or / and password id NOT VALID or NOT EXIST user
        1 – name and password is VALID
        2 – other error
 		services/apexrest/RsProps
       
        {"username" : "UserName","password" : "password","appname" : "Props"}

        */
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json'); 
        service sr = new service('',3);
      if (username==null)
            return new service('username missing',0); 
            else
                if (password==null)
                  return new service('password missing',0); 
                   else
                       if (appname==null)
                           return new service('appname missing',2);    
     Id StudentRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();
     Id ParentRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Parent').getRecordTypeId();
     Boolean VALID = false;
     
     String Query = 'select Status__c,Kangi_Status__c,Kangi_Password__c,id , RecordTypeId from  contact where Kangi_User_Name__c='  + +'\''+username+'\'';
     List<Contact> conlist = database.query(query); 
        
        if (conlist.size()==0)
            sr = new service('Username does not match',0);
        else 
            if (conlist.size()!=1)
            sr = new service('there is more than username in SF system !! ',2);           
        else 
            if (conlist[0].Kangi_Password__c != password)
            sr = new service('password does not match ',0);
        else
             if (conlist[0].RecordTypeId== StudentRecordType || conlist[0].RecordTypeId==ParentRecordType||conlist[0].Status__c<>'Active'||conlist[0].Kangi_Status__c<>'Active')
             	sr = new service('user not allowed',2); 
        else {
            sr = new service('',1);
            conlist[0].Last_Login_Date__c = system.now();
            update conlist[0];
        }
        
     return sr;   
    }
}