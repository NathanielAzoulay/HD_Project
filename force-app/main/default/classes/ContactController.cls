public without sharing class ContactController {
   /**
    * @description          : The method getContacts get duplcates cntacts in org for certain emails, mobile, phone 
    * Author				: baybridge digital
    * @since				: 18/12/2023
    *
    * @method			    : getContacts
    * @param	string		: String email, string phone, string mobile
    * @return	list<Contact>: con
    * @public  @AuraEnabled
    */
    @AuraEnabled(cacheable=true)
    public static list<Contact> getDuplicateContacts(String email, string phone, string mobile){
        list<Contact> cons = [select Id, Name, Mailing_Address_Country__c, MobilePhone,  Email, Phone, Entity_Type__c, Contact_Record_Type_Name_R__c, MF_Name__c from Contact where Person_Contact__c = true and 
                            Contact_Record_Type_Name_R__c ='Franchisee' AND (MobilePhone=:mobile OR Phone=:phone OR Email=:email) limit 10];

        if(cons.size()>0){
            return cons; 
        }

        return null; 
        // String query = 'select Id, Name, Mailing_Address_Country__c, MobilePhone,  Email, Phone, Entity_Type__c, Contact_Record_Type_Name_R__c, MF_Name__c from Contact where Person_Contact__c = true and Contact_Record_Type_Name_R__c ='/+'Franchisee'+/'+ AND 
        // if(mobile != null){
        //     query +='AND (MobilePhone = mobile ';
        //     if(email != null){
        //         query +='OR Email = email ';
        //         if(phone != null){
        //             query +='OR Phone= phone)';
        //         }
        //     }
        // }
        // if(email != null){
        //     query +='OR Email=:email';
        // }
        // if(phone != null){
        //     query +='Phone=:phone';
        // }
        // (MobilePhone=:mobile OR Phone=:phone OR Email=:email) limit 10];
    }


      /**
    * @description          : The method getContactData for a contact id 
    * Author				: baybridge digital
    * @since				: 18/12/2023
    *
    * @method			    : getContactData
    * @param	string		: contactId
    * @return	Contact: con
    * @public  @AuraEnabled
    */

    @AuraEnabled(cacheable=true)
    public static Contact getContactData(String contactId){
        Contact con = [select email,Dedupe_Trigger__c,Dedupe_ContactID__c , Phone, MobilePhone from Contact where id=: contactId];

        return con;
    }

    @AuraEnabled
    public static Map<String, String> uniteContact(String dedupTrigger, String conId, string parentId){
        system.debug('dedup trigger '+ dedupTrigger);
        Map<String, String> statusMap = new Map<String, String>(); 
        Contact currentContact = getContactData(conId);
        currentContact.Dedupe_Trigger__c  = dedupTrigger;

        if(parentId != null){
            currentContact.Dedupe_ContactID__c  = parentId;
        }

        // update new list<Contact>{currentContact};
        Database.saveResult[] srList = Database.update(new list<Contact>{currentContact}, false);
       
        for (Integer i=0;i<srList.size();i++) {
            list<Database.Error> err = srList[i].getErrors();
            if(!srList[0].getErrors().isEmpty()){
                statusMap.put('Error' ,err[0].getMessage()+ err[0].getFields());
            }
            else{
                statusMap.put('Message', 'your changes have been saved successfully');
            }
        }

       if(statusMap.isEmpty()){
            statusMap.put('Message' ,'No changes have been performed');
       }

       system.debug('statusmap '+statusMap);
       
       return statusMap;
    }
}