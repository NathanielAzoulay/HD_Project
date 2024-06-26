/**************************************************************
Description : This class supports the following 
operations, related to  Document upload to AWS s3:
1. Policy generate for AWS .
2. Generate The HMAC-SHA256 hash of the security policy. 
Created/Modified by   Created/Modified Date                       
-------------------------------------------------------------
1. Rashad Saeed        28/11/2016                 
*************************************************************/
public with sharing class AWS_Upload {
   public  Document__c newDocument{get;set;}
   Public  static AWS_Keys__c awsKeySet{get;set;}
   public string ForRedirect{get;set;}
   public string rfolder{get;set;}
   //public string rName{get;set;}   
   public static Id appParentId{get;set;}
   public string Content_Type {get;set;}  
   Public String acessType{get;set;}
   Public boolean IsStandard {get;set;}
   public AWS_Upload(){
       IsStandard = true;
       user uObj = [Select id,Profile.UserLicense.Name from User where Id=: UserInfo.getUserId()];
       if (uObj.Profile.UserLicense.Name != 'Salesforce')
          IsStandard = false; 
       newDocument = new Document__c();
       awsKeySet= AWS_Keys__c.getInstance();
        appParentId = ApexPages.currentPage().getParameters().get('parentIdForRedirect');
       if(IsStandard)
           {
             ForRedirect = URL.getSalesforceBaseUrl().toExternalForm()+'/'+'apex/AWS_SucessRedirectPage?parentIdForRedirect='+appParentId;  
           }
       else
            ForRedirect = URL.getSalesforceBaseUrl().toExternalForm()+'/HDC/'+'apex/AWS_SucessRedirectPage?parentIdForRedirect='+appParentId;
       Content_Type ='multipart/form-data';
       acessType ='public-read-write';
       rfolder  = String.valueOf (appParentId.getSObjectType());
       rfolder +='/'+appParentId+'-'+ApexPages.currentPage().getParameters().get('Name')+'/';
       
       system.debug('awsKeySet'+awsKeySet); 
        system.debug('policy'+policy);
   }
       
       
       Datetime expire = system.now().addDays(1);
       String formattedexpire = expire.formatGmt('yyyy-MM-dd')+'T'+ expire.formatGmt('HH:mm:ss')+'.'+expire.formatGMT('SSS')+'Z';           
          
      string policy { get {return 
        '{ "expiration": "'+formattedexpire+'","conditions": [ {"bucket": "'+
         awsKeySet.Name__c +'" } ,{ "acl": "'+acessType+'" },'+
        '{"content-type":"'+Content_Type+'"},'+
        '{"success_action_redirect": "'+ForRedirect+'"},' +
        '["starts-with", "$key", ""] ]}';   } } 
    
    public String getPolicy() {
        return EncodingUtil.base64Encode(Blob.valueOf(policy));
    }
    
    public String getSignedPolicy() {    
        return make_sig(EncodingUtil.base64Encode(Blob.valueOf(policy)));        
    }
    
    
    //method that will sign
    private String make_sig(string canonicalBuffer) {        
        String macUrl ;
        Blob mac = Crypto.generateMac('HMacSHA1', blob.valueof(canonicalBuffer),blob.valueof(awsKeySet.AWS_Secret_Key__c)); 
        macUrl = EncodingUtil.base64Encode(mac);                
        return macUrl;
    }
       
     @RemoteAction
    public static Document__c createNewDocument(String appID, String uploadedFilename,string bucketName){
         //stem.debug('ApexPages.currentPage().getParameters() '+ApexPages.currentPage().getParameters().get('parentIdForRedirect')); 
        Document__c newDocument = new Document__c();
           newDocument.Application__c = appID;
            newDocument.Document_Name__c = uploadedFilename.substringAfterLast('/');
           newDocument.Document_URL__c =  'https://s3.amazonaws.com/'+bucketName+'/'+uploadedFilename;
            newDocument.Status__c ='Uploaded';
            
         insert  newDocument;
         
         return newDocument;  
    
    }
    
}