/******************************************************************************* 
Name              : Lead_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez     			16/05/2016           
*******************************************************************************/

public class Lead_TriggerHandler {

   public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		
		if (Trigger.isBefore && Trigger.isInsert){ // Before Update
			
		}else if (Trigger.isBefore && Trigger.isUpdate){ // Before Insert
			//validationsOnLead();
		}
		/*
		else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
		{
		}
		*/
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		
		 
		if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{
			convertQualifiedLead();
			convertTeacherLead();
			lead_CreateSharingRules();		
		}
		
		else if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
			convertQualifiedLead();
			convertTeacherLead();
			lead_CreateSharingRules();
			DocumentsOnLeadConvert();
		}
		/*
		else if (Trigger.isAfter && Trigger.isDelete) // After Delete
		{
			
		}
		else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
		{
			
		}
		
		*/		
	} 
	
	
	/******************************************************************************* 
	Name              : DocumentsOnLeadConvert
	Description       : Changes the Documents with the Lead Id to point to the new Contact created from the convertion
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio	        	30/11/2016          	Yaara Nadir 		  [SW-22546]
	*******************************************************************************/
	
	public static void DocumentsOnLeadConvert(){
		system.debug( 'DocumentsOnLeadConvert' );
		
		if( HD_TriggerSettings.IsTriggerActive('DocumentsOnLeadConvert') ){
			try{
				Map<String, Id> conIdByLeadId = new Map<String, Id>();
				for( Integer i=0; i < trigger.size; i++ ){
					system.debug( 'trigger.new[i]: ' + trigger.new[i].get('IsConverted') );
					system.debug( 'trigger.old[i]: ' + trigger.old[i].get('IsConverted') );
					if( trigger.new[i].get('IsConverted') != trigger.old[i].get('IsConverted') ){
						String lId = String.valueOf(trigger.new[i].Id);
						
						conIdByLeadId.put( lId, (Id) trigger.new[i].get('ConvertedContactId') );
						conIdByLeadId.put( lId.substring(0,15), (Id) trigger.new[i].get('ConvertedContactId') );
					}
				}
				system.debug('conIdByLeadId: ' + conIdByLeadId );
				if( !conIdByLeadId.isEmpty() ){
					List<Document__c> docs2Upd = new List<Document__c>();
					
					for( Document__c doc : [SELECT Id, Application__c FROM Document__c WHERE Application__c IN : conIdByLeadId.keySet() ] ){
						if( conIdByLeadId.containsKey(doc.Application__c) ){
							doc.Application__c = conIdByLeadId.get(doc.Application__c);
							docs2Upd.add(doc);
						}
					}
					
					update docs2Upd;
				}
			}catch( Exception e ){
				trigger.new[0].addError( GlobalHelperMethods.ImproveErrorMessage(e) );
			}
		}
	}
	
	
	/******************************************************************************* 
	Name              : convertTeacherLead
	Description       : The trigger will auto convert the Lead to new Teacher Contact. The Contact owner of the new teacher contact will always be the Logged-in userand also the same account of this Logged-in user
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio	        	21/11/2016          	Ella  Bernachik 		  [SW-22396]
	2. Gustavo	        	15/08/2017          	Ella  Bernachik 		  [SW-26173]
	SW-
	*******************************************************************************/
	
	public static void convertTeacherLead(){
		
		if( HD_TriggerSettings.IsTriggerActive('convertTeacherLead') ){
			try{

				Id contactFranchiseeRT = Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
				Id contactStaffRT = Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Staff').getRecordTypeId();
				Id teacherRT = Lead.sObjectType.getDescribe().getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
				User currentUser = [SELECT Id, ContactId, Contact.AccountId, Contact.RecordTypeId, Contact.Account.Account_Type__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1][0];
				
				Set<Id> leads = new Set<Id>();
				Map<Id, User> ownerMap = new Map<Id, User>();
				
				for( Integer i=0; i < trigger.size; i++ ){
					Lead newLead = (Lead) trigger.new[i];
					
					Boolean condition = newLead.RecordTypeId == teacherRT && newLead.Status == 'Qualified';
					if( currentUser.ContactId != null ){
						condition &= (currentUser.Contact.RecordTypeId == contactFranchiseeRT || currentUser.Contact.RecordTypeId == contactStaffRT);
						condition &= currentUser.Contact.Account.Account_Type__c == 'MF';
					}
					condition &= !newLead.IsConverted;
					
					if( condition ){
						leads.add(newLead.Id);
						ownerMap.put( newLead.OwnerId, null );
					}
				}
				
				if( !leads.isEmpty() ){
					LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
					Map<Id,Database.LeadConvert> leads2convert = new Map<Id,Database.LeadConvert>();
					
					for( User us : [SELECT Id, Contact.AccountId FROM User WHERE Id IN :ownerMap.keySet() ] ){
						ownerMap.put( us.Id, us );
					}
					
					Map<Id, AccountContactRelation> acrMap = new Map<Id, AccountContactRelation>();
					
					for( Id ldId : leads ){
						Database.LeadConvert lc = new Database.LeadConvert();
						Lead l = (Lead) trigger.newMap.get(ldId);
						
						lc.setLeadId(l.Id);
						lc.setDoNotCreateOpportunity(true);
						
						lc.setAccountId(currentUser.Contact.AccountId);
						
						if( currentUser.Id != l.OwnerId && ownerMap.containsKey(l.OwnerId) && ownerMap.get(l.OwnerId).Contact.AccountId != null ){
							//lc.setAccountId( ownerMap.get(l.OwnerId).Contact.AccountId );
							acrMap.put( l.Id, new AccountContactRelation(AccountId = ownerMap.get(l.OwnerId).Contact.AccountId) );
						}
						
						lc.setConvertedStatus(convertStatus.MasterLabel);							
						leads2convert.put(l.Id, lc);
					}
					
					if(!leads2convert.isEmpty()){
						if(MonitorRecursionClass.isLeadConverting != true){
							MonitorRecursionClass.isLeadConverting = true;
							List<Database.Leadconvertresult> lcrList = Database.convertLead(leads2convert.values());
							
							List<Contact> con2Upd = new List<Contact>();
							List<AccountContactRelation> acr2Ins = new List<AccountContactRelation>();
							
							for( Database.Leadconvertresult lcr : lcrList ){
								if( lcr.isSuccess() ){
									Id conId = lcr.getContactId();
									Lead l = (Lead) trigger.newMap.get(lcr.getLeadId());
									con2Upd.add( new Contact( Id = conId, OwnerId = Userinfo.getUserId(), Lead_Owner__c = l.OwnerId ) );
									
									if( acrMap.containsKey( l.Id ) ){
										acrMap.get( l.Id ).ContactId = conId;
										acr2Ins.add( acrMap.get( l.Id ) );
									}
								}
							}
							
							//First we need to create the relationship and AFTER that we update the Contact
							//This is to help the logic from ContactCreateSharingRules, otherwise it won't work
							system.debug('acr2Ins: ' + acr2Ins);
							if( !acr2Ins.isEmpty() ){
								insert acr2Ins;
							}
							
							update con2Upd;
						}
					}else{
						trigger.new[0].addError( Label.Lead );
					}
				}
			}catch(Exception e){
				trigger.new[0].addError( GlobalHelperMethods.ImproveErrorMessage(e) );
			}
		}
	}
	
	/******************************************************************************* 
	Name              : convertQualifiedLead
	Description       : Convert lead to student with standard mapping and account with same company name						
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez        	16/05/2016          	Yaara 		          	[SW-19442]
	*******************************************************************************/

    class MyException extends Exception {}

	public static void convertQualifiedLead(){
		
		if( HD_TriggerSettings.IsTriggerActive('convertQualifiedLead') ){
			try{
				Id studentRecordTypeId = Lead.sObjectType.getDescribe().getRecordTypeInfosByName().get('Student').getRecordTypeId();
				
				Map<Id,Database.LeadConvert> leads2convert = new Map<Id,Database.LeadConvert>();
				Map<String,Set<Integer>> companiesLeads = new Map<String,Set<Integer>>();
				for(Integer i=0; i < trigger.size; i++ ){
					Lead l = (Lead) trigger.new[i];

					Boolean cond = l.RecordTypeId == studentRecordTypeId && l.Status == 'Qualified';
					//cond &= Trigger.isInsert || Trigger.isUpdate; 
					if( cond ){
						if(!companiesLeads.containsKey(l.Company)){
							companiesLeads.put(l.Company, new Set<Integer>());
						}
						companiesLeads.get(l.Company).add(i);
					}
				}

				if(!companiesLeads.isEmpty()){	
					LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
					
					for( Account acc :[SELECT Id, Name FROM Account WHERE Name IN :companiesLeads.keySet()]){
						for(Integer idx : companiesLeads.get(acc.Name)){
							Database.LeadConvert lc = new Database.LeadConvert();
							Lead l = (Lead) trigger.new[idx];

							lc.setLeadId(l.Id);
							lc.setDoNotCreateOpportunity(true);
							lc.setAccountId(acc.Id);
							lc.setConvertedStatus(convertStatus.MasterLabel);							
							leads2convert.put(l.Id, lc);
						}							
					}

					if(!leads2convert.isEmpty()){
						if(MonitorRecursionClass.isLeadConverting != true){
							MonitorRecursionClass.isLeadConverting = true;
							Database.convertLead(leads2convert.values());
						}
					}else{
						trigger.new[0].addError( Label.Lead );
					}				
				}
			}catch(Exception e){
				System.debug(System.LoggingLevel.ERROR, 'convertQualifiedLead catch ' + e.getMessage() + ' Line: ' +e.getStackTraceString());
				trigger.new[0].addError( GlobalHelperMethods.ImproveErrorMessage(e) );
			}
		}
	}

	/******************************************************************************* 
	Name              : lead_CreateSharingRules
	Description       : Handler the sharing record of Lead object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez 	  		06/22/2016     			Yaara 				SW-20031
	*******************************************************************************/
	
	public static void lead_CreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('lead_CreateSharingRules') ){
			List<Lead> leads = new List<Lead>();
			
			for(Integer i=0; i < trigger.size; i++ ){
				Lead l = (Lead) trigger.new[i];

				if ( trigger.isInsert || (trigger.isUpdate && ((Lead) trigger.old[i]).OwnerId <> l.OwnerId) ) {
					leads.add(l);
				}				
			}

			if(!leads.isEmpty()){
				HD_SharingMethods.Lead_CreateSharingRules(leads);
			}
		}
	}

}