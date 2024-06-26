/******************************************************************************* 
Name              : LG_Discount_TriggerHandler
Description       : Handler the before/after trigger on LG Discount
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas          03/07/2016              
*******************************************************************************/
public with sharing class LG_Discount_TriggerHandler {

    public static void executeTriggerHandler(){
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        
        if (Trigger.isBefore && Trigger.isInsert) // Before Update
        {
            populateLGDiscountFielsOnBefore();
        }
        
        else if (Trigger.isBefore && Trigger.isUpdate) // Before Insert
        {
            populateLGDiscountFielsOnBefore();
        }
        /*
        else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
        {
        }
        */
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        
         
        if (Trigger.isAfter && Trigger.isInsert) // After Insert
        {
            updateLGPaymentWhenLGDiscountIsApproved();  
        }
        else
        if (Trigger.isAfter && Trigger.isUpdate) // After Update
        {
            updateLGPaymentWhenLGDiscountIsApproved();
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
    Description       : Populate fields before duplicatecheck
                        1) Update LG Code before insert and when edited
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Nicolas              03/07/2016          Ella  Bernachik             [SW-18074]
    2. Nicolas              03/14/2016          Ella  Bernachik             [SW-18074]
    *******************************************************************************/
    public static void populateLGDiscountFielsOnBefore(){
        if( HD_TriggerSettings.IsTriggerActive('populateLGDiscountFielsOnBefore') ){
            
            Map<Id, List<LG_Discount__c>> lgDiscounts = new Map<Id,List<LG_Discount__c>>();
            for(Integer i=0; i < trigger.size; i++ ){
                //if lg Student in this LG Discount is null step to the next LG Discount
                LG_Discount__c r = (LG_Discount__c)trigger.new[i];
                if(r.LG_Student__c == Null)
                    continue;
                
                if(trigger.isInsert || r.LG_Student__c <> ((LG_Discount__c)trigger.old[i]).LG_Student__c){
        
                    //create new map of discounts by lg Student
                    if(!lgDiscounts.containsKey(r.LG_Student__c))
                        lgDiscounts.put(r.LG_Student__c, new List<LG_Discount__c>());
            
                    lgDiscounts.get(r.LG_Student__c).add(r);
                }
            }
            
            if(!lgDiscounts.isEmpty()){
            
                //look if lg students were already queried
                Map<Id, LG_Student__c> lgMap = MonitorRecursionClass.getLgStudentFromCache(lgDiscounts.keySet());
            
                for(LG_Student__c lgS : lgMap.values()){
                    for(LG_Discount__c d : lgDiscounts.get(lgS.Id)){
                        //d.LG_Code__c = lg.LG_Code__c;
                        d.LG_Student_Code__c = lgS.Name;                    
                    }
                }
            }
            
            /* THEY CHANGED THE REQUIREMENT
            Map<Id, List<LG_Discount__c>> lgDiscounts = new Map<Id,List<LG_Discount__c>>();
            for(Integer i=0; i < trigger.size; i++ ){
                //if lg in this student is null step to the next student
                LG_Discount__c r = (LG_Discount__c)trigger.new[i];
                if(r.LG__c == Null)
                    continue;
                
                if(trigger.isInsert || r.LG__c <> ((LG_Discount__c)trigger.old[i]).LG__c){
        
                    //create new list of discounts on lg
                    if(!lgDiscounts.containsKey(r.LG__c))
                        lgDiscounts.put(r.LG__c, new List<LG_Discount__c>());
            
                    //add student to lg
                    lgDiscounts.get(r.LG__c).add(r);
                }
            }
            
            if(!lgDiscounts.isEmpty()){
            
                //look if lgs were already queried
                Map<Id, LG__c> lgMap = MonitorRecursionClass.getLgFromCache(lgDiscounts.keySet());
            
                for(LG__c lg : lgMap.values()){
                    for(LG_Discount__c d : lgDiscounts.get(lg.Id)){
                        //d.LG_Code__c = lg.LG_Code__c;
                        d.LG_Student_Code__c = lg.LG_Student__r.Name;                   
                    }
                }
            }
            */

        }
    }
    
    /******************************************************************************* 
    Description       : Update related LG Payments when discount it being approved                      
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan Sinclair         05/03/2016           Yaara                   [SW-18009]
    *******************************************************************************/
    public static List<LG_Discount__c> lgDiscountApproved = new List<LG_Discount__c>();
    public static List<LG_Discount__c> lgDiscountStudentApproved = new List<LG_Discount__c>();      
    public static void updateLGPaymentWhenLGDiscountIsApproved(List<LG_Discount__c> theLgDiscountApproved){
    	
    	if( HD_TriggerSettings.IsTriggerActive('updateLGPaymentWhenLGDiscountIsApproved') ){
    	
    		Set<Id> lgIds = new Set<Id>();
            Set<Id> approvedOneTimeDiscountIds = new Set<Id>();
            for(LG_Discount__c r : theLgDiscountApproved){
        	    
        	    lgIds.add(r.LG__c);
                if(r.Discount_Type__c == 'One Time (Month)'){
                    approvedOneTimeDiscountIds.add(r.Id);
                }
                LG_Payment_TriggerHandler.applyOnlyOnDiscountIds.add(r.Id);
            }
            updateLGPaymentWhenLGDiscountIsApproved_internalLogic(lgIds, approvedOneTimeDiscountIds);
            theLgDiscountApproved.clear();
    	}    	
    }
    
    public static void updateLGPaymentWhenLGDiscountIsApproved(){
        
        if( HD_TriggerSettings.IsTriggerActive('updateLGPaymentWhenLGDiscountIsApproved') ){
            
            Set<Id> lgIds = new Set<Id>();
            Set<Id> approvedOneTimeDiscountIds = new Set<Id>();
            for(Integer i=0; i < trigger.size; i++ ){
                
                LG_Discount__c r = (LG_Discount__c)trigger.new[i];
               
                Boolean condition = r.LG__c <> null && r.Discount_Status__c == 'Approved' && (Trigger.isInsert || ((LG_Discount__c)trigger.old[i]).Discount_Status__c <> r.Discount_Status__c);
                condition &= !LG_Payment_TriggerHandler.applyOnlyOnDiscountIds.contains(r.Id); // For avoid recursion 
                if(condition){
                	
                	if(r.LG_Student__c == null){
                		lgDiscountApproved.add(r); // This will allow us to fire the logic after the update prices from LG (since the PB will fire after this update on LG Discount)
                	}else{
                		lgDiscountStudentApproved.add(r); // This will allow us to fire the logic after the update prices from LG Student (since the PB will fire after this update on LG Discount)
                	}
                	
                    lgIds.add(r.LG__c);
                    if(r.Discount_Type__c == 'One Time (Month)'){
                        approvedOneTimeDiscountIds.add(r.Id);
                    }
                    LG_Payment_TriggerHandler.applyOnlyOnDiscountIds.add(r.Id);
                }
            }
            
            updateLGPaymentWhenLGDiscountIsApproved_internalLogic(lgIds, approvedOneTimeDiscountIds);
        }
    }
      
    public static void updateLGPaymentWhenLGDiscountIsApproved_internalLogic( Set<Id> lgIds,  Set<Id> approvedOneTimeDiscountIds){
            
        if(!lgIds.isEmpty()){
            
            LG_Payment_TriggerHandler.lgPayment2ApplyDiscount.clear();
            List<Decimal> lgPaymentAmounts = new List<Decimal>();
            for(LG_Payment__c p : [SELECT LG_Student__c, LG__c, Planned_Date__c, Planned_Price__c, LG_Discount_One_Time__c FROM LG_Payment__c WHERE LG__c IN : lgIds]){
                LG_Payment_TriggerHandler.lgPayment2ApplyDiscount.add(p);
                lgPaymentAmounts.add(p.Planned_Price__c);
            }
            
            if(!LG_Payment_TriggerHandler.lgPayment2ApplyDiscount.IsEmpty()){
                
                List<LG_Payment__c> lgPayment2UpdateDiscount = new List<LG_Payment__c>();
                
                LG_Payment_TriggerHandler.updateLGStudentPaymentOnInsert(); // Try to apply the existing discounts (considering the new ones)...
                for(Integer i = 0; i < LG_Payment_TriggerHandler.lgPayment2ApplyDiscount.size(); i++){
                    
                    LG_Payment__c p = LG_Payment_TriggerHandler.lgPayment2ApplyDiscount[i];
                    
                    Boolean condition = p.LG_Discount_One_Time__c <> null && approvedOneTimeDiscountIds.contains(p.LG_Discount_One_Time__c);
                    condition |= lgPaymentAmounts[i] != p.Planned_Price__c; // if the price was modified by other discount.
                    if(condition){
                        lgPayment2UpdateDiscount.add(p);
                    }
                }
                
                if(!lgPayment2UpdateDiscount.isEmpty()){
                    LG_Payment_TriggerHandler.lgPayment2ApplyDiscount.clear(); // for avoding recursion
                    update lgPayment2UpdateDiscount;
                    
                    LG_Payment_TriggerHandler.updateLGStudentPaymentOnInsert_HasRunIt = true; // For avoiding that the PB execute again the Logic on the LG payment discount!!!
                }
            }   
		}
	}

}