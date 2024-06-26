/**************************************************************************************
Name              : LG_Agreement_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez              07/04/2016 
2. Shivram Saini            27/06/2018          Gidi Abramovich      [Task-000001439]  
***************************************************************************************
*/

public class LG_Agreement_TriggerHandler {

   public static void executeTriggerHandler(){
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        
        /*if (Trigger.isBefore && Trigger.isInsert) // Before Update
        {
            
        }
        
        else if (Trigger.isBefore && Trigger.isUpdate) // Before Insert
        {
            
        }
        
        else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
        {
        }
        */
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        
         
        if (Trigger.isAfter && Trigger.isInsert) // After Insert
        {
            AgreementCreateSharingRules();
            PriceListTitleSharingRules();
            CreateAgreementParameters();
        }
        
        else if (Trigger.isAfter && Trigger.isUpdate) // After Update
        {
            AgreementCreateSharingRules();
            PriceListTitleSharingRules();
            CreateAgreementParameters();
        }
        /*else if (Trigger.isAfter && Trigger.isDelete) // After Delete
        {
            
        }
        else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
        {
            
        }
        
        */      
    }

    /******************************************************************************* 
    Name              : PriceListTitleSharingRules
    Description       : Handler the sharing record of Price List Title in the Agreement object
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/16/2016          Yaara Nadir               [SW-19960]
    *******************************************************************************/
    
    public static void PriceListTitleSharingRules(){
        if( HD_TriggerSettings.IsTriggerActive('PriceListTitleSharingRules') ){
            
            List<Agreement__c> agrees = new List<Agreement__c>();
            for(Integer i=0; i < trigger.size; i++ ){
                Agreement__c agre = (Agreement__c)trigger.new[i];
                Boolean cond = trigger.isInsert || ((Agreement__c) trigger.old[i]).Price_List_Title__c <> agre.Price_List_Title__c;
                if(agre.Price_List_Title__c != null && cond){
                    agrees.add(agre);
                }
            }

            if(!agrees.isEmpty()){
                HD_SharingMethods.PriceListAgreement_CreateSharingRules(agrees);
            }
        }
    }

    /******************************************************************************* 
    Name              : AgreementCreateSharingRules
    Description       : Handler the sharing record Agreement
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             07/25/2016          Yaara Nadir               [SW-20540]
    *******************************************************************************/
    
    public static void AgreementCreateSharingRules(){
        if( HD_TriggerSettings.IsTriggerActive('AgreementCreateSharingRules') ){
            
            List<Agreement__c> agrees = new List<Agreement__c>();
            for(Integer i=0; i < trigger.size; i++ ){
                Agreement__c agree = (Agreement__c)trigger.new[i];
                Boolean cond = trigger.isInsert || ((Agreement__c) trigger.old[i]).OwnerId <> agree.OwnerId;
                cond = cond || ((Agreement__c) trigger.old[i]).Direct_Franchisee__c <> agree.Direct_Franchisee__c;
                if(cond){
                    agrees.add(agree);
                }
            }

            if(!agrees.isEmpty()){
                HD_SharingMethods.Agreement_CreateSharingRules(agrees);
            }
        }
    }  

    /******************************************************************************* 
    Name              : CreateAgreementParameters
    Description       : create the Agreement Parameters to Agreement, automatically accoding to Agreement details and Agreement Meta Data definitions.
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             11/30/2016          Yaara Nadir               [SW-22527]
    2. Shivram Saini            27/06/2018          Gidi Abramovich      [Task-000001439]
    *******************************************************************************/
    
    public static void CreateAgreementParameters(){

        if( HD_TriggerSettings.IsTriggerActive('CreateAgreementParameters') ){
            //collect search values
            Set<Id> agreeIds = new Set<Id>();
            Set<String> rTypes = new Set<String>();
            Set<String> ffTypes = new Set<String>();
            //Set<String> pTypes = new Set<String>();
            //Set<String> countries = new Set<String>();
            for(Integer i=0; i < trigger.size; i++ ){
                Agreement__c agreeNew = (Agreement__c) trigger.new[i];
                
                Boolean cond = trigger.isInsert;
                
                if( trigger.isUpdate ){
                    Agreement__c agreeOld = (Agreement__c) trigger.old[i];
                    cond = agreeNew.Direct_Franchisee__c != agreeOld.Direct_Franchisee__c;
                }
                
                cond &= agreeNew.Direct_Franchisee__c != null;

                cond &= agreeNew.DBAmp_Date__c == null;
                
                if( cond ){
                    rTypes.add(agreeNew.Royalty_Type__c);
                    ffTypes.add(agreeNew.From_Franchisee_Type__c);
                    //pTypes.add(agree.Program_Type__c);
                    //countries.add(agree.Country_Name__c);
                    agreeIds.add(agreeNew.Id);
                }
            }
            
            if(!agreeIds.isEmpty()){

                //query for metadata
                List<Agreement_Meta_Data__c> agmds = [SELECT Id, Royalty_Percent__c, To_Franchise_Type__c, Student_Count_Revenue__c, Source_Account_Type__c, From_Franchise_Type__c, Program_Type__c, Country__c, Royalty_Type__c 
                                                        FROM Agreement_Meta_Data__c 
                                                        WHERE Royalty_Type__c IN :rTypes AND From_Franchise_Type__c IN :ffTypes];

                
                List<Agreement_Parameter__c> ap4Ins = new List<Agreement_Parameter__c>();
                
                //looking for matching data and create related parameter
                
                for (Agreement__c agree : [SELECT Id, Direct_Franchisee__c, Direct_Franchisee_Type__c, Country_Name__c, Program_Type__c, Royalty_Type__c, From_Franchisee_Type__c, Direct_Franchisee__r.Account_Type__c, Agreement_type__c, (SELECT Id, Source_Agreement_Meta_Data__c FROM Agreement_Parameters__r) FROM Agreement__c WHERE Id IN :agreeIds ]) {
                
                    Set<Id> existingMetaData = new Set<Id>();
                    for( Agreement_Parameter__c ap : agree.Agreement_Parameters__r ){
                        existingMetaData.add(ap.Source_Agreement_Meta_Data__c);
                    }
                    boolean matchingCountryFound = false;
                    
                    for (Agreement_Meta_Data__c agmd : agmds) {
                        if( existingMetaData.contains(agmd.Id)){
                            //Agreement Parameter already was created for the Meta Data
                            continue;
                        }
                        Boolean cond1 = string.isNotBlank(agree.Country_Name__c) && string.isNotBlank(agmd.Country__c) && agree.Country_Name__c == agmd.Country__c;
                        //If country of Agreement matches with AMD, check other parameters also
                        Boolean cond2 = agree.Program_Type__c == agmd.Program_Type__c && agree.Royalty_Type__c == agmd.Royalty_Type__c && agree.Agreement_type__c == agmd.From_Franchise_Type__c && agree.Direct_Franchisee_Type__c == agmd.To_Franchise_Type__c;
                        
                        //Perfect Match
                        if(cond1 && cond2){
                            Agreement_Parameter__c agreeParameter = createAgreementParameter(agree.Id, agmd);
                            ap4Ins.add(agreeParameter);
                            matchingCountryFound = true;
                        }
                    }
                    if(!matchingCountryFound ){
                        for (Agreement_Meta_Data__c agmd : agmds) {
                            if( existingMetaData.contains(agmd.Id)){
                                //Agreement Parameter already was created for the Meta Data
                                continue;
                            }
                            Boolean cond2 = agree.Program_Type__c == agmd.Program_Type__c && agree.Royalty_Type__c == agmd.Royalty_Type__c && agree.Agreement_type__c == agmd.From_Franchise_Type__c && agree.Direct_Franchisee_Type__c == agmd.To_Franchise_Type__c;
                            
                            if(cond2 && string.isBlank(agmd.Country__c) ){
                                Agreement_Parameter__c agreeParameter = createAgreementParameter(agree.Id, agmd);
                                ap4Ins.add(agreeParameter);
                            }
                            
                        }
                    }

                }
                if(ap4Ins.size() > 0)
                    insert ap4Ins;
            }
        }
    }
    
    private static Agreement_Parameter__c createAgreementParameter(Id agreementId, Agreement_Meta_Data__c amdt){
        Agreement_Parameter__c agreeParameter = new Agreement_Parameter__c();
        agreeParameter.Agreement__c = agreementId;
        agreeParameter.Royalty_Percent__c = amdt.Royalty_Percent__c;
        agreeParameter.Student_Count_Revenue__c = amdt.Student_Count_Revenue__c;
        agreeParameter.Account_Type__c = amdt.Source_Account_Type__c;
        agreeParameter.Source_Agreement_Meta_Data__c = amdt.Id; 
        return agreeParameter;   
    }
    
}