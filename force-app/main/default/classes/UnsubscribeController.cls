public without sharing class UnsubscribeController {
    
    public string conId {
        get;
        set;
    }
    
    public string modeName{
        get;
        set;
    }

    public boolean unsubscribeMarketing {
        get;
        set;
    }
    public boolean unsubscribeLG {
        get;
        set;
    }
    public Boolean isShowAllMarkettingUnsbcribe {
        get;
        set;
    }
    public Boolean isShowAllLGUnsbcribe {
        get;
        set;
    }

    public UnsubscribeController() {
        conId = ApexPages.currentPage().getParameters().get('Id');
        modeName = ApexPages.currentPage().getParameters().get('mode');
        unsubscribeLG = false;
        unsubscribeMarketing = false;
        isShowAllMarkettingUnsbcribe = true;
        isShowAllLGUnsbcribe = true;

        //adding a condition if Id is not equals to null.
        if (conId != null && conId != '') {
        
            if (ConId.substring(0, 3) == '003') {
            
                for (Contact c: [select id, LGS_opt_out__c, Marketing_opt_out__c from Contact where Id =: conId]) {
                    if (c.Marketing_opt_out__c) {
                        isShowAllMarkettingUnsbcribe = false;
                    }
                    if (c.LGS_opt_out__c || modeName != 'Lg') {
                        isShowAllLGUnsbcribe = false;
                    }
                }
            } else {
                for (Lead c: [select id, LGS_opt_out__c, Marketing_opt_out__c from Lead where Id =: conId]) {
                    if (c.Marketing_opt_out__c) {
                        isShowAllMarkettingUnsbcribe = false;
                    }
                    else{
                        isShowAllMarkettingUnsbcribe = true;
                    }
                    if (c.LGS_opt_out__c || modeName != 'Lg') {
                        isShowAllLGUnsbcribe = false;
                    }
                    else{
                        isShowAllLGUnsbcribe = true;
                    }
                }
            }
            if (!isShowAllMarkettingUnsbcribe && !isShowAllLGUnsbcribe) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No available options to unsubscribe.'));
            }

        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No record selected to unsubscribe.'));
        }
    }
    
    public PageReference unsubscribeContact() {
        try {
            Contact camp  = [select id, Marketing_opt_out__c, LGS_opt_out__c from Contact where Id =: ConId Limit 1];

            if(unsubscribeMarketing){
                unsubscribeMarketing = false;
                camp.Marketing_opt_out__c = true;
            }
            
            if(unsubscribeLG){
                unsubscribeLG = false;
                camp.LGS_opt_out__c = true;
            }
            if(camp.Id != null){
            update camp;
            }
        } catch (Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()+ ' - unsubscribeContact: '+ e.getLineNumber());
            //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getLineNumber());
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    public PageReference unsubscribeLead() {
        try {
            Lead lgs = [select id, Marketing_opt_out__c, LGS_opt_out__c from Lead where Id =: ConId Limit 1];
            
            /*for (Lead c: [select id, Marketing_opt_out__c, LGS_opt_out__c from Lead where Id =: ConId]) {
                lgs = c;
            }*/
            
            if(unsubscribeMarketing){
                unsubscribeMarketing = false;
                lgs.Marketing_opt_out__c = true;
            }
            
            if(unsubscribeLG){
                unsubscribeLG = false;
                lgs.LGS_opt_out__c = true;
            }
            if(lgs.Id != null){
            update lgs;
            }
        } catch (Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()+ ' - unsubscribeLead: '+ e.getLineNumber());
            //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getLineNumber());
            ApexPages.addMessage(myMsg);
        }
        return null;
    }

    public PageReference submit() {
        try {
            
            // for both
            System.debug(unsubscribeMarketing+'===unsubscribeLG====='+unsubscribeLG );
            if (unsubscribeLG && unsubscribeMarketing && conId != null && conId != '') {
                 System.debug('=====(conId.substring(0, 3) ==003==='+(conId.substring(0, 3) == '003'));
                if (conId.substring(0, 3) == '003') {
                    unsubscribeContact();
                }
                else{
                    unsubscribeLead();
                }
                isShowAllLGUnsbcribe = false;
                isShowAllMarkettingUnsbcribe = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'You have been unsubscribed from all Marketting and all learning group emails as well.'));
                return null;
            }

            // unsubscribe marketing condition
            if (unsubscribeMarketing && conId != null && conId != '') {
                System.debug('=====(conId.substring(0, 3) ==003=== in unsubscribeMarketing=='+(conId.substring(0, 3) == '003'));
                if (conId.substring(0, 3) == '003') {
                    unsubscribeContact();
                }
                else{
                    unsubscribeLead();
                }
                isShowAllMarkettingUnsbcribe = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'You have been unsubscribed from all Marketting emails.'));
                return null;
            }

            // Unsubscribe all emails
            if (unsubscribeLG && conId != null && conId != '') {
                System.debug('=====(conId.substring(0, 3) ==003=== in unsubscribeLG=='+(conId.substring(0, 3) == '003'));
                if (conId.substring(0, 3) == '003') {
                    unsubscribeContact();
                }
                else{
                    unsubscribeLead();
                }
                isShowAllLGUnsbcribe = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'You have been unsubscribed from all learning group emails.'));
                return null;
            }
            return null;
        } catch (Exception e) {
            System.assert(false,e.getLineNumber()+'====='+e.getStackTraceString());
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()+ ' - submit: '+ e.getLineNumber());
            //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getLineNumber());
            ApexPages.addMessage(myMsg);
            return null;
        }
    }
}