/******************************************************************************* 
Name              : Contact_TriggerHandler
Description       : Handler the before/after trigger on Contact
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/13/2016
*******************************************************************************/
public class Contact_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- BEFORE EVENTS -----------------------------
		if (Trigger.isBefore && Trigger.isInsert){
			setRecordTypeOnConvert();
		}else if (Trigger.isBefore && Trigger.isUpdate){
			DeactivateTeacherUser();
		}
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			ContactCreateSharingRules();
		}
		else if (Trigger.isAfter && Trigger.isUpdate){
			ContactCreateSharingRules();
			ContactUpdateMFID();
			//HandleUserCreation();
			allowLGPaymentRecalculationWithNewDiscount();
		}				
	}


	/******************************************************************************* 
	Name              : ContactCreateSharingRules
	Description       : Handler the sharing record of Contact object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	05/27/2016         	Yaara Nadir				  [SW-19588]
	*******************************************************************************/
	
	public static void ContactUpdateMFID(){
		
		if( HD_TriggerSettings.IsTriggerActive('ContactUpdateMFID') ){
			Id recTypeLcSetLsfId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
   			Id recTypeMfFpId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
   
			Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
	        Id recTypeStaffId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId();
	        Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();

	        Map<Id,Id> conIds = new Map<Id,Id>();
	       	Set<Id> giveTTPermissions = new Set<Id>();

			for(Integer i=0; i < trigger.size; i++){
				Contact con = (Contact) trigger.new[i];
				Contact oldCon = (Contact) trigger.old[i];
				if(con.AccountId != oldCon.AccountId){
					conIds.put(con.Id, null);
				}

		        //SW-22697
		        //SW-25678 Boolean condtt = con.RecordTypeId == recTypeTeacherId;
		        Boolean condtt = con.TT_Qualified__c == 'TT' && oldCon.TT_Qualified__c != 'TT';
		        condtt = condtt && con.Contact_Partner_User__c != null;
		        if(condtt){
					giveTTPermissions.add(con.Id);
		        }

	        }   

	        if (!conIds.isEmpty()) {
	       		//Set<Id> users2up = new Set<Id>();
	        	for (Contact con : [SELECT SET__c, Status__c, Email, FirstName, LastName, RecordTypeId, Direct_Franchisee__c, Account.Name, Account.Direct_Franchisee__c,
			        Account.Account_Type__c, Account.Parent.Account_Type__c, Account.Parent.Parent.Account_Type__c, Account.Parent.Parent.Parent.Account_Type__c,
			        Account.IsPartner, Account.Partner_Account_User__c, Account.ParentId, Account.Parent.Partner_Account_User__c, Account.RecordTypeId,
			        Account.Parent.OwnerId, Account.CurrencyIsoCode, User_Creation_Status__c, MailingCountry, Account.BillingCountry, Account.Permitted_Users_per_Account__c,
			        Account.Owner.UserType FROM Contact WHERE Id IN :conIds.keySet()]){

		        	Id mfId;

			        if(con.Account.Account_Type__c == 'MF' && (con.RecordTypeId == recTypeFranchiseeId || con.RecordTypeId == recTypeStaffId)){
			            mfId = con.AccountId;
			        }

			        if(con.RecordTypeId == recTypeTeacherId && con.SET__c == false){
			            mfId = con.AccountId;
			        }

			        Boolean cond = con.Account.Account_Type__c == 'FP' && (con.RecordTypeId == recTypeFranchiseeId || con.RecordTypeId == recTypeStaffId);
			        cond = cond || con.Account.RecordTypeId == recTypeLcSetLsfId && (con.RecordTypeId == recTypeFranchiseeId || con.RecordTypeId == recTypeStaffId);
			        cond = cond || con.RecordTypeId == recTypeTeacherId && con.SET__c == true;

			        if(cond){

			            Account directFranchisee = con.Account.Parent;
			            for(Integer i = 0; i<3 ; i++){ // navigate to the top level of the account Hierarchy looking for MF
			                if(directFranchisee == null){
			                    break;
			                }
			                if(directFranchisee.Account_Type__c == 'MF'){
			                    mfId = directFranchisee.Id;
			                    break;
			                }
			                directFranchisee = directFranchisee.Parent;
			            }
			        }

			        if(mfId != null){
			        	conIds.put(con.Id, mfId);
			        }
				}
		    }

	        if (!conIds.isEmpty() || !giveTTPermissions.isEmpty()) {
	       		List<Id> users2TT = new List<Id>();
				for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :giveTTPermissions]){
				    if(giveTTPermissions.contains(u.ContactId)){
				    	users2TT.add(u.Id);
				    }
		        }

				if (System.isBatch()) {
					AsyncUpdateUsers asyncJob = new AsyncUpdateUsers();
					asyncJob.conIds = conIds;
					asyncJob.giveTTPermissions = giveTTPermissions;
					System.enqueueJob(asyncJob);

			        if( !users2TT.isEmpty() ){
						AsyncPermissionSetAssigns asyncJob2 = new AsyncPermissionSetAssigns();
						asyncJob2.users2TT = users2TT;
						System.enqueueJob(asyncJob2);
			        }
				}else{
		        	UpdateUsers(conIds, giveTTPermissions);
			        if( !users2TT.isEmpty() ){
			        	PermissionSetAssigns(users2TT);
			        }
				}

		    }

		}
    }

    @future
    public static void UpdateUsers(Map<Id,Id> conIds, Set<Id> giveTTPermissions){
		List<User> users2up = new List<User>();
		for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :conIds.keySet() OR ContactId IN :giveTTPermissions]){
		    if(conIds.containsKey(u.ContactId)){
		    	u.MF_ID__c = conIds.get(u.ContactId);
		    }
		    if(giveTTPermissions.contains(u.ContactId)){
				u.TT_Qualified__c = 'TT';
		    }
        	users2up.add(u);
        }

        if (!users2up.isEmpty()) {
			update users2up;
        }
	}

    @future
    public static void PermissionSetAssigns(List<Id> userIds){
		
		PermissionSet ttAdditionalPermissionsSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'TT_Additional_Permissions' LIMIT 1];
		List<PermissionSetAssignment> permissionSetAssigns2ins = new List<PermissionSetAssignment>();
		for (Id assignId : userIds) {                
			permissionSetAssigns2ins.add(new PermissionSetAssignment(PermissionSetId = ttAdditionalPermissionsSet.Id, AssigneeId = assignId));
		}

		insert permissionSetAssigns2ins;

    }
	
	/******************************************************************************* 
	Name              : ContactCreateSharingRules
	Description       : Handler the sharing record of Contact object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	05/27/2016         	Yaara Nadir				  [SW-19588]
	*******************************************************************************/
	public static Boolean isUserCreationOnProcess = false;
	public static void ContactCreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('ContactCreateSharingRules') && !isUserCreationOnProcess){
			
	        Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
			
			List<Contact> contacts = new List<Contact>();
			List<Contact> teachers = new List<Contact>();
			List<Id> contactIds = new List<Id>();
			for(Integer i=0; i < trigger.size; i++){
				Contact con = (Contact)trigger.new[i];
				Boolean cond1 = trigger.isUpdate && ((Contact)trigger.old[i]).OwnerId <> con.OwnerId;
				Boolean cond2 = cond1 || trigger.isUpdate && ((Contact)trigger.old[i]).AccountId <> con.AccountId;
				if(trigger.isInsert || cond2){
					contacts.add(con);
				}
				if(cond1){
					contactIds.add(con.Id);
				}
				Boolean cond3 = trigger.isUpdate && ((Contact)trigger.old[i]).AccountId <> con.AccountId && con.RecordTypeId == recTypeTeacherId;
				if(cond3){
					teachers.add(con);
				}
			}

			if(!contacts.isEmpty()){
				HD_SharingMethods.Contact_CreateSharingRules(contacts);
			}

			if(!teachers.isEmpty()){
				HD_SharingMethods.Contact_CreateTeacherSharingRules(teachers);
			}

			if(!contactIds.isEmpty()){
				//create sharing for related accounts
				System.debug(LoggingLevel.ERROR, '*** Contact_CreateRelationshipSharingRules: ' + contactIds);
				HD_SharingMethods.Contact_CreateRelationshipSharingRules(contactIds);
			}
		}
	}

	/******************************************************************************* 
	Name              : DeactivateTeacherUser
	Description       : 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	12/12/2016         	Yaara Nadir				  [SW-22575]
	*******************************************************************************/
	
	public static void DeactivateTeacherUser(){
		if( HD_TriggerSettings.IsTriggerActive('DeactivateTeacherUser') ){

			List<Id> contactIds = new List<Id>();
			Set<Id> cIds = new Set<Id>();
			for(Integer i=0; i < trigger.size; i++){
				Contact con = (Contact)trigger.new[i];
				if(trigger.isUpdate){
					cIds.add(con.Id);
				}
			}

			Set<Id> contactWithUser = new Set<Id>();
			if(!cIds.isEmpty()){
				for(User u : [SELECT ContactId FROM User WHERE ContactId IN :cIds]){
					contactWithUser.add(u.ContactId);
				}
			}

			for(Integer i=0; i < trigger.size; i++){
				Contact con = (Contact)trigger.new[i];
				Boolean cond1 = trigger.isUpdate && ((Contact)trigger.old[i]).Status__c <> con.Status__c && (con.Status__c == 'Not Active' || con.Status__c == 'Never Employed');
				//SW-25680 Boolean cond2 = con.RecordTypeId == teacherTypeId;
				Boolean cond2 = contactWithUser.contains(con.Id);
				if(cond1 && cond2){
					contactIds.add(con.Id);
					con.User_Creation_Status__c = 'User Deactivated';
				}
			}

			if(!contactIds.isEmpty()){
				if (System.isBatch()) {
					AsyncDeactivateUser asyncJob = new AsyncDeactivateUser();
					asyncJob.contactIds = contactIds;
					System.enqueueJob(asyncJob);
				}else{
					DeactivateTeacherUserFuture(contactIds);
				}
			}

		}
	}

	@future
	public static void DeactivateTeacherUserFuture(List<Id> contactIds){
		List<User> users2up = new List<User>();
		for (User u : [SELECT Id FROM User WHERE ContactId IN :contactIds]) {
			u.IsActive = false;
			users2up.add(u);
		}

		update users2up;
	}


	/******************************************************************************* 
	Name              : setRecordTypeOnConvert
	Description       : change the default recordtype on creation
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	05/27/2016         	Yaara Nadir				  [SW-19588]
	*******************************************************************************/
	
	public static void setRecordTypeOnConvert(){
		if( MonitorRecursionClass.isLeadConverting == true && HD_TriggerSettings.IsTriggerActive('setRecordTypeOnConvert') ){
    		Id recTypeStudentId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();    
			
			for(Integer i=0; i < trigger.size; i++ ){
				Contact con = (Contact)trigger.new[i];
				con.RecordTypeId = recTypeStudentId;			
			}
		}
	}
	
	
	/******************************************************************************* 
	Name              : updateLGPaymentOnDiscountChanged
	Description       : will allow the update of all LG Payment with the new discount.
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan	         	04/13/2017         		   Dafna				  [SW-24275] #5
	*******************************************************************************/
	
	public static void allowLGPaymentRecalculationWithNewDiscount(){
		if( HD_TriggerSettings.IsTriggerActive('allowLGPaymentRecalculationWithNewDiscount') ){
    		Set<Id> conIds = new Set<Id>();
    		for(Integer i=0; i < trigger.size; i++ ){
    			
    			Contact r = (Contact)trigger.new[i];
    			Contact rOld = (Contact)trigger.old[i];
				if(rOld.Student_Discount__c <> r.Student_Discount__c){	
					conIds.add(r.Id);
				}		
			}
			
			if(!conIds.isEmpty()){
				
				Set<Id> lgSIds = new Set<Id>();
				for(LG_Student__c lgS : [SELECT Id FROM LG_Student__c WHERE Student__c IN: conIds AND Status_in_LG__c = 'Registered']){
					lgSIds.add(lgS.Id);
				}
				
				if(!lgSIds.isEmpty()){
					LGHelperMethods.doRecreateLGPayment2LGStudent(lgSIds);			
				}
			}
		}
	}

}