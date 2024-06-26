/******************************************************************************* 
    Name              : Batch_applyVAT2LGPayments
    Description       : 
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G.Fernandez            18/04/2016              Yaara Nadir           SW-18017
    *******************************************************************************/

global class Batch_applyVAT2LGPayments implements Database.Batchable<sObject> {
    public String query;
    public Set<Id> franchiseeAccIds;

    global Batch_applyVAT2LGPayments() {
        franchiseeAccIds = new Set<Id>();
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM LG_Payment__c WHERE LG__r.Franchisee__c IN :franchiseeAccIds OR LG__r.Franchisee__r.ParentId IN :franchiseeAccIds OR LG_Student__r.LG__r.Franchisee__r.ParentId IN :franchiseeAccIds';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Sobject> scope) {
        
        Set<Id> payments = (new Map<Id,SObject>(scope)).keySet();
        System.debug(System.LoggingLevel.ERROR,'payments ---> ' + payments);
        System.debug(System.LoggingLevel.ERROR,'franchiseeAccIds ---> ' + franchiseeAccIds);
        
        LGHelperMethods.applyVAT2LGPayments(franchiseeAccIds, payments);
    }

    global void finish(Database.BatchableContext BC) {

    }
}