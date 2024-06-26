public with sharing class DeduplicateContact {
    
    public List<Contact> duplicateContacts {get; private set;}
    public Boolean showNoContacts {get; private set;}
    public String selectedContactId { get; set; }
    public String selectedButtonValue { get; set; }
    public String contactId { get; set; }
    public Boolean showMsg {get; set;}
    public String statusMsg { get; set; }
    public String updatedStatusMsg { get; set; }
    public DeduplicateContact(ApexPages.StandardController Controller) {
        string contactId = ApexPages.currentPage().getParameters().get('id');
        system.debug('con id '+contactId);
        this.contactId = contactId;
        list<Contact> duplicateContacts = new list <Contact>();
        Contact con = getContactData(contactId);
        string email = string.ValueOf(con.email);
        string Phone = string.ValueOf(con.Phone);
        string MobilePhone = string.ValueOf(con.MobilePhone);
        this.duplicateContacts = getDuplicateContacts(this.contactId, email, Phone, MobilePhone);
        if(this.duplicateContacts.size() == 0){
            this.showNoContacts = true;
        }else this.showNoContacts = false;

        this.statusMsg = '';
        this.showMsg = false;
    }

    public PageReference uniteContact(){
        
        string parentId = this.selectedContactId;
        Map<String, String> statusMap = new Map<String, String>(); 
        Boolean updateContact;
        Contact currentContact = getContactData(this.contactId );
       
        if(selectedButtonValue == 'NO'){
            currentContact.Dedupe_Trigger__c  = '1';
            updateContact = true;
        }else if (selectedButtonValue == 'YES' && parentId != null)
        {
            currentContact.Dedupe_ContactID__c  = parentId;
            currentContact.Dedupe_Trigger__c  = '2';
            updateContact = true;
        }
      
        if(updateContact == true){
            Database.saveResult[] srList = Database.update(new list<Contact>{currentContact}, false);
       
            for (Integer i=0;i<srList.size();i++) {
                this.showMsg = true;
                list<Database.Error> err = srList[i].getErrors();
                if(!srList[0].getErrors().isEmpty()){
                    statusMap.put('Error' ,err[0].getMessage()+ err[0].getFields());
                    this.updatedStatusMsg =err[0].getMessage()+ err[0].getFields();
                    
                }
                else{
                    this.showMsg = false;
                    statusMap.put('Message', 'your changes have been saved successfully');
                    this.updatedStatusMsg = 'Your changes have been saved successfully';
                }
            }
        }

       if(statusMap.isEmpty()){
            this.showMsg = true;
            this.updatedStatusMsg =  'No changes have been performed';
       }
              
        return null;
    }

    public static Contact getContactData(String contactId){
        list<Contact> con = [select email,Dedupe_Trigger__c,Dedupe_ContactID__c , Phone, MobilePhone from Contact where id=: contactId];

        if(con.size()>0){
            return con[0];
        }
        return null;
    }

    public static list<Contact> getDuplicateContacts(String contactId, String email, string phone, string mobile){
        String baseQuery = 'SELECT Id, Name, Mailing_Address_Country__c, MobilePhone, Email, Phone, Entity_Type__c, Contact_Record_Type_Name_R__c, MF_Name__c FROM Contact WHERE Id <>: contactId  AND Person_Contact__c = true AND Contact_Record_Type_Name_R__c = \'Franchisee\'';
        String conditionClause = '';

        if (mobile != null || phone != null || email != null) {
            conditionClause += ' AND (';

            if (mobile != null) {
                conditionClause += 'MobilePhone = :mobile';
            }

            if (phone != null) {
                if (mobile != null) {
                    conditionClause += ' OR ';
                }
                conditionClause += 'Phone = :phone';
            }

            if (email != null) {
                if (mobile != null || phone != null) {
                    conditionClause += ' OR ';
                }
                conditionClause += 'Email = :email';
            }

            conditionClause += ')';
        }

        String finalQuery = baseQuery + conditionClause ;//+ ' LIMIT 10';
        system.debug('finalquery = ' + finalQuery);

        return Database.query(finalQuery);
    }
}