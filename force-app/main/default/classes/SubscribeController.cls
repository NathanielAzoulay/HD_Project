public without sharing class SubscribeController {
    
    public string conId {
        get;
        set;
    }
    
    public string modeName{
        get;
        set;
    }

    public boolean subscribeMarketing {
        get;
        set;
    }
    public boolean subscribeLG {
        get;
        set;
    }
    public Boolean isShowMarketing {
        get;
        set;
    }
    public Boolean isShowLG {
        get;
        set;
    }

    public SubscribeController() {
        conId = ApexPages.currentPage().getParameters().get('Id');
        //modeName = ApexPages.currentPage().getParameters().get('mode');
        subscribeLG = false;
        subscribeMarketing = false;
        isShowMarketing = false;
        isShowLG = false;

        //adding a condition if Id is not equals to null.
        if (conId != null && conId != '') {
        
            if (ConId.substring(0, 3) == '003') {
            
                for (Contact c: [select id, LGS_opt_out__c, Marketing_opt_out__c from Contact where Id =: conId]) {
                    if (c.Marketing_opt_out__c) {
                        isShowMarketing = true;
                    }
                    if (c.LGS_opt_out__c) {
                        isShowLG = true;
                    }
                }
            } /*else {
                for (Lead c: [select id, LGS_opt_out__c, Marketing_opt_out__c from Lead where Id =: conId]) {
                    if (c.Marketing_opt_out__c) {
                        isShowAllMarkettingUnsbcribe = false;
                    }
                    if (c.LGS_opt_out__c || modeName != 'Lg') {
                        isShowAllLGUnsbcribe = false;
                    }
                }
            }*/
            if (!isShowMarketing && !isShowLG) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No available options to subscribe.'));
            }

        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No record selected to subscribe.'));
        }
    }
    
    public PageReference subscribeContact() {
        try {
            Contact camp = new Contact();

            for (Contact c: [select id, Marketing_opt_out__c, LGS_opt_out__c from Contact where Id =: ConId]) {
                camp = c;
            }
            
            if(subscribeMarketing){
                //subscribeMarketing = false;                
                isShowMarketing = false;
                //isShowLG = false;
                camp.Marketing_opt_out__c = false;
            }
            
            if(subscribeLG){
                //subscribeLG = false;
                isShowLG = false;
                //isShowMarketing = false;
                camp.LGS_opt_out__c = false;
            }
            update camp;
        } catch (Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    /*public PageReference unsubscribeLead() {
        try {
            Lead lgs = new Lead();
            
            for (Lead c: [select id, Marketing_opt_out__c, LGS_opt_out__c from Lead where Id =: ConId]) {
                lgs = c;
            }
            
            if(unsubscribeMarketing){
                unsubscribeMarketing = false;
                lgs.Marketing_opt_out__c = true;
            }
            
            if(unsubscribeLG){
                unsubscribeLG = false;
                lgs.LGS_opt_out__c = true;
            }
            update lgs;
        } catch (Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
        }
        return null;
    }*/

    public PageReference submit() {
        try {            
            // for both
            if (subscribeLG && subscribeMarketing) {
                
                if (conId.substring(0, 3) == '003') {
                    subscribeContact();
                }
                /*else{
                    unsubscribeLead();
                }*/
                //isShowLG = false;
                //isShowMarketing = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'You have been subscribed for all Marketting and all learning group emails as well.'));
                return null;
            }

            // unsubscribe marketing condition
            if (subscribeMarketing) {                
                if (conId.substring(0, 3) == '003') {
                    subscribeContact();
                }
                /*else{
                    unsubscribeLead();
                }*/
                //isShowMarketing = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'You have been subscribed for all Marketting emails.'));
                return null;
            }

            // Unsubscribe all emails
            if (subscribeLG) {                
                if (conId.substring(0, 3) == '003') {
                    subscribeContact();
                }
                /*else{
                    unsubscribeLead();
                }*/
                //isShowLG = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'You have been subscribed for all learning group emails.'));
                return null;
            }
            return null;
        } catch (Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
    }
}