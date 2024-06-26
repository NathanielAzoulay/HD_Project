/******************************************************************************* 
Name              : CustomLookupController
Description       : Class for Custom Lookup for all the MF/Admin Users.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Aparna             11/01/2017                Gidi          
*******************************************************************************/
public with sharing class CustomLookupController {
    public Boolean render1 {
        get;
        set;
    }
    set<Id> requestedLgsUserIds = new set<Id>();
    List < User > records       = new List < User > ();
    public String searchvalue {
        get;
        set;
    }
    public CustomLookupController() {
        try {
            searchvalue        = ApexPages.currentPage().getParameters().get('parentname');
            String id          = ApexPages.currentPage().getParameters().get('parentid');
            String selectedIds = ApexPages.currentPage().getParameters().get('SelectedIds');
            List<String> sids  = selectedIds.split(',');
        
            for(LG_Discount__c lgD: [Select Id, CreatedById FROM LG_Discount__c WHERE Id IN: sids AND Discount_Status__c = 'Requested']){
                requestedLgsUserIds.add(lgD.CreatedById); 
            }
            
            if (String.IsNotBlank(searchvalue)) {
                render1 = true;
                records = [SELECT Id, Name, Title, Phone, Username, Profile.Name 
                           FROM User 
                           WHERE Id IN: requestedLgsUserIds 
                           AND Name like: +searchvalue + '%'
                           ORDER BY Name ASC
                ];
            }else {
                render1 = true;
                records = [SELECT Id, Name, Title, Phone, Username, Profile.Name 
                           FROM User 
                           WHERE Id IN: requestedLgsUserIds 
                           order by Name asc];
            }
        } catch (Exception e) {}
    }
    public List < User > getRecords() {
        if (records.size() != 0) {
            return records;
        } else {
            return null;
        }
    }
    public PageReference onkeyupAction() {
        searchAction();
        return null;
    }
    public PageReference searchAction() {
        render1 = true;
        records = [SELECT Id, Name, Title, Phone, Username, Profile.Name 
                   FROM User 
                   WHERE Id IN :requestedLgsUserIds 
                   AND Name like: +searchvalue + '%'
                   ORDER BY Name ASC
        ];
        if (records.isEmpty()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error, 'No Records Found'));
        }
        return null;
    }
    
    
}