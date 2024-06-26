/******************************************************************************* 
Name              : Seminar_TriggerHandler
Description       : Handler the before/after trigger on Account
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez 	  		06/22/2016          	       	
*******************************************************************************/
public class Seminar_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		/*
		if (Trigger.isBefore && Trigger.isInsert) // Before Update
		{
			
		}*/ 
		if (Trigger.isBefore && Trigger.isUpdate) // Before Insert
		{
			//deactivateAccountUsers();
			MaintainManualShares();
			seminarCreateSharingRulesBefore();
		}
		/*
		else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
		{
		}
		*/
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
	
		if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{
			seminarCreateSharingRules();
		}
		
		else if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
			MaintainManualShares();
			seminarCreateSharingRules();
			SeminarDeleteManualSharing();
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
	Name              : MaintainManualShares
	Description       : Keep manual shares when owner changes
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez 	  		09/01/2017     			Dafna Margalit		SW-23154
	*******************************************************************************/
	
	static private List<Seminar__Share> oldManualShares = new List<Seminar__Share>();
	public static void MaintainManualShares(){
		if( HD_TriggerSettings.IsTriggerActive('MaintainManualShares') ){
			if (Trigger.isBefore){
				Set<Id> semIds = new Set<Id>();
				for(Integer i=0; i < trigger.size; i++ ){
					Seminar__c sem = (Seminar__c) trigger.new[i];
					Boolean cond = ((Seminar__c) trigger.old[i]).OwnerId <> sem.OwnerId;
					if (cond) {
						semIds.add(sem.Id);
					}
				}

				if(!semIds.isEmpty()){
					for (Seminar__Share sShare : [SELECT ParentId, UserOrGroupId, AccessLevel FROM Seminar__Share WHERE ParentId IN :semIds] ) {
						oldManualShares.add(new Seminar__Share(ParentId = sShare.ParentId, UserOrGroupId = sShare.UserOrGroupId, AccessLevel = sShare.AccessLevel));
					}
				}
			}

			if (Trigger.isAfter && !oldManualShares.isEmpty()){
				Database.insert(oldManualShares,false);
			}
		}
	}

	/******************************************************************************* 
	Name              : seminarCreateSharingRulesBefore
	Description       : Handler the sharing record of Seminar__c object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez 	  		15/12/2016     			Ella 				SW-22711
	*******************************************************************************/
	
	public static void seminarCreateSharingRulesBefore(){
		if( HD_TriggerSettings.IsTriggerActive('seminarCreateSharingRules') ){
			for(Integer i=0; i < trigger.size; i++ ){
				//SW-22711 - 3
				Seminar__c r = (Seminar__c) trigger.new[i];		
				Boolean cond = trigger.isInsert && r.Teacher_Trainer__c != null;
				cond = trigger.isUpdate && ((Seminar__c) trigger.old[i]).Teacher_Trainer__c <> r.Teacher_Trainer__c;
				if (cond) {
					r.TT_Permissions__c = true;
				}

				//SW-22711 - 5
				cond = trigger.isUpdate && ((Seminar__c) trigger.old[i]).Teacher_Trainer__c <> r.Teacher_Trainer__c;
				cond |= trigger.isUpdate && ((Seminar__c) trigger.old[i]).TT_Status__c <> r.TT_Status__c;
				cond &= r.Teacher_Trainer__c != null && r.TT_Status__c == 'Rejected by TT';
				if (cond) {
					r.TT_Permissions__c = false;
				}
			}
		}
	}
	
	/******************************************************************************* 
	Name              : seminarCreateSharingRules
	Description       : Handler the sharing record of Seminar__c object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez 	  		06/22/2016     			Yaara 				SW-20017
	2. G. Fernandez 	  		15/12/2016     			Ella 				SW-22711
	3. G. Fernandez 	  		06/03/2016     			Dafna Margalit		SW-23981
	4. G. Fernandez 	  		30/08/2017     			Dafna Margalit		SW-26375
	*******************************************************************************/
	
	public static void seminarCreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('seminarCreateSharingRules') ){
			Map<Id,Set<Seminar__c>> hostFranchisees = new Map<Id,Set<Seminar__c>>();
			Map<Id,Set<Seminar__c>> seminarTypes = new Map<Id,Set<Seminar__c>>();
			Map<Id,Set<Seminar__c>> seminarTypesProcApplication = new Map<Id,Set<Seminar__c>>();

			Map<Id,Set<Seminar__c>> seminarTeacherTrainers = new Map<Id,Set<Seminar__c>>();
			Map<Id,Set<Seminar__c>> seminarTeacherTrainers2del = new Map<Id,Set<Seminar__c>>();
			
        	Map<Id,Seminar__c> seminarTeacherSh2Ins = new Map<Id,Seminar__c>();
        	Set<Id> allHostingFranchisee = new Set<Id>();
        	Map<Id,List<Seminar__c>> hostingFranchiseeSh2Ins = new Map<Id,List<Seminar__c>>();

        	Set<Id> allSeminarWithTTstatus = new Set<Id>();
        	//Map<Id,List<Seminar__c>> ttStatusSh2Ins = new Map<Id,List<Seminar__c>>();

			for(Integer i=0; i < trigger.size; i++ ){
				Seminar__c r = (Seminar__c) trigger.new[i];		
				
				Boolean cond = trigger.isUpdate && ((Seminar__c) trigger.old[i]).OwnerId <> r.OwnerId;
				cond |= trigger.isUpdate && r.Hosting_Franchisee__c != null && ((Seminar__c) trigger.old[i]).Hosting_Franchisee__c <> r.Hosting_Franchisee__c;
				cond |= trigger.isInsert && r.Hosting_Franchisee__c != null;

				if (cond) {
					if(!hostFranchisees.containsKey(r.Hosting_Franchisee__c)){
						hostFranchisees.put(r.Hosting_Franchisee__c, new Set<Seminar__c>());
					}
					hostFranchisees.get(r.Hosting_Franchisee__c).add(r);
				}

				//SW-22711 Update #2
				cond = trigger.isInsert;
				cond |= trigger.isUpdate && ((Seminar__c) trigger.old[i]).Status__c <> r.Status__c;
				cond |= trigger.isUpdate && ((Seminar__c) trigger.old[i]).OwnerId <> r.OwnerId;
				cond &= r.Status__c == 'Confirmed';
				if (cond) {
					if(!seminarTypes.containsKey(r.Seminar_Type__c)){
						seminarTypes.put(r.Seminar_Type__c, new Set<Seminar__c>());
					}
					seminarTypes.get(r.Seminar_Type__c).add(r);
				}

				//SW-22711 5
				cond = trigger.isUpdate && ((Seminar__c) trigger.old[i]).Teacher_Trainer__c <> r.Teacher_Trainer__c;
				cond |= trigger.isUpdate && ((Seminar__c) trigger.old[i]).TT_Status__c <> r.TT_Status__c;
				cond &= r.Teacher_Trainer__c != null && r.TT_Status__c == 'Rejected by TT';
				if (cond) {
					if(!seminarTeacherTrainers2del.containsKey(((Seminar__c) trigger.old[i]).Teacher_Trainer__c)){
						seminarTeacherTrainers2del.put(((Seminar__c) trigger.old[i]).Teacher_Trainer__c, new Set<Seminar__c>());
					}
					seminarTeacherTrainers2del.get(((Seminar__c) trigger.old[i]).Teacher_Trainer__c).add(r);
				}

				//SW-22711 - 1.1
				//SW-22711 - 1.2
				cond = trigger.isUpdate && ((Seminar__c) trigger.old[i]).OwnerId <> r.OwnerId;
				cond |= trigger.isUpdate && ((Seminar__c) trigger.old[i]).Status__c <> r.Status__c;
				cond |= trigger.isInsert && r.Teacher_Trainer__c != null;
				cond &= r.Status__c == 'Confirmed';
				if (cond) {
					seminarTeacherSh2Ins.put(r.Id,r);
				}

				//SW-23981
				allHostingFranchisee.add(r.Hosting_Franchisee__c);

				//SW-22711 - 3
				cond = trigger.isInsert;
				cond |= trigger.isUpdate && ((Seminar__c) trigger.old[i]).Teacher_Trainer__c <> r.Teacher_Trainer__c;
				cond &= r.Teacher_Trainer__c != null;
				if (cond) {
					//sharing
					if(!seminarTeacherTrainers.containsKey(r.Teacher_Trainer__c)){
						seminarTeacherTrainers.put(r.Teacher_Trainer__c, new Set<Seminar__c>());
					}
					seminarTeacherTrainers.get(r.Teacher_Trainer__c).add(r);
				}

				//SW-22711 - 4
				cond = trigger.isUpdate && r.TT_Status__c == 'Approved by TT' && ((Seminar__c) trigger.old[i]).TT_Status__c <> r.TT_Status__c;
				if (cond) {
					//sharing
					/*if(!ttStatusSh2Ins.containsKey(r.Teacher_Trainer__c)){
						ttStatusSh2Ins.put(r.Teacher_Trainer__c, new Set<Seminar__c>());
					}
					ttStatusSh2Ins.get(r.Teacher_Trainer__c).add(r);*/
					allSeminarWithTTstatus.add(r.Id);
				}

				//SW-23981 7
				cond = trigger.isUpdate && ((Seminar__c) trigger.old[i]).OwnerId <> r.OwnerId;
				cond |= trigger.isUpdate && ((Seminar__c) trigger.old[i]).Status__c <> r.Status__c;
				cond |= trigger.isInsert;
				cond &= r.Status__c == 'Processing Application';
				if(cond){
					if(!seminarTypesProcApplication.containsKey(r.Seminar_Type__c)){
						seminarTypesProcApplication.put(r.Seminar_Type__c, new Set<Seminar__c>());
					}
					seminarTypesProcApplication.get(r.Seminar_Type__c).add(r);
				}
									
			}

			if(!hostFranchisees.isEmpty()){
				HD_SharingMethods.Seminar_HostFranchiseeCreateSharingRules(hostFranchisees);
			}

			if(!seminarTypes.isEmpty()){
				HD_SharingMethods.Seminar_TypesCreateSharingRules(seminarTypes);
			}

			if(!seminarTeacherTrainers2del.isEmpty()){
				HD_SharingMethods.Seminar_TeacherTrainersDeleteSharingRules(seminarTeacherTrainers2del);
			}

			if(!seminarTeacherTrainers.isEmpty()){
				HD_SharingMethods.Seminar_TeacherTrainersCreateSharingRules(seminarTeacherTrainers);
			}

        	List<Seminar__Share> sh2Ins = new List<Seminar__Share>();
        	List<Seminar_Teachers__Share> stsh2Ins = new List<Seminar_Teachers__Share>();
        	//SW-26375
        	//List<ContactShare> sttsh2Ins = new List<ContactShare>();
				
			Map<Id,Set<Id>> teacherSeminars = new Map<Id,Set<Id>>();
			Map<Id,Seminar_Teachers__c> teacherMap = new Map<Id,Seminar_Teachers__c>();
			if(!seminarTeacherSh2Ins.isEmpty()){

				for(Seminar_Teachers__c st : [SELECT Id, Teacher_Status_in_seminar__c, Seminar__c, Teacher__r.Contact_Partner_User__c, Teacher__r.Account.Partner_Account_User__c, Teacher__r.Account.Partner_Account_Manager__c FROM Seminar_Teachers__c WHERE Seminar__c IN :seminarTeacherSh2Ins.keySet() AND Teacher_Status_in_seminar__c = 'Registered']){
                	sh2Ins.add(new Seminar__Share(ParentId = st.Seminar__c, UserOrGroupId = st.Teacher__r.Contact_Partner_User__c, AccessLevel = 'Read'));
                	stsh2Ins.add(new Seminar_Teachers__Share(ParentId = st.Id, UserOrGroupId = st.Teacher__r.Contact_Partner_User__c, AccessLevel = 'Read'));
					if (!teacherSeminars.containsKey(st.Seminar__c)) {
						teacherSeminars.put(st.Seminar__c ,new Set<Id>());
					}
					teacherSeminars.get(st.Seminar__c).add(st.Id);
					teacherMap.put(st.Id, st);
				}
			
				//SW-23981
	        	//getting hosting franchisee users
	            Map<Id,Account> accUser = new Map<Id,Account>();
	            for (Account acc : [SELECT Partner_Account_User__c, Partner_Account_Manager__c FROM Account WHERE Id IN :allHostingFranchisee]) {
	                accUser.put(acc.Id,acc);
	            }

	            //SW-22711 1)-1.2
	            //comparing users and adding sharing 
	            if(!teacherSeminars.isEmpty()){
		            for(Id sId : seminarTeacherSh2Ins.keySet()){
		                Seminar__c sem = seminarTeacherSh2Ins.get(sId);
	            		if(accUser.containsKey(sem.Hosting_Franchisee__c)){           
		                    Id userId = accUser.get(sem.Hosting_Franchisee__c).Partner_Account_User__c;
		                    Id mUserId = accUser.get(sem.Hosting_Franchisee__c).Partner_Account_Manager__c;
		                    
		            		if(teacherSeminars.containsKey(sem.Id)){
			                    for (Id semTeacher : teacherSeminars.get(sem.Id)) {
			                    	Seminar_Teachers__c st =  teacherMap.get(semTeacher);
				                    Id accUserTeacherId = st.Teacher__r.Account.Partner_Account_User__c;

				                    if (accUserTeacherId!=null && userId != accUserTeacherId) {
				                        sh2Ins.add(new Seminar__Share(ParentId = sem.Id, UserOrGroupId = accUserTeacherId, AccessLevel = 'Read'));
		        						stsh2Ins.add(new Seminar_Teachers__Share(ParentId = semTeacher, UserOrGroupId = accUserTeacherId, AccessLevel = 'Read'));
				                    } 

				                    Id accManagerUserTeacherId = st.Teacher__r.Account.Partner_Account_Manager__c;

			                        if(accManagerUserTeacherId!=null && mUserId!=accManagerUserTeacherId){
		                        		sh2Ins.add(new Seminar__Share(ParentId = sem.Id, UserOrGroupId = accManagerUserTeacherId, AccessLevel = 'Read'));
		            					stsh2Ins.add(new Seminar_Teachers__Share(ParentId = semTeacher, UserOrGroupId = accManagerUserTeacherId, AccessLevel = 'Read'));
			                        }
			                    }  

		            		}	
		            	}	
		        	}
		        }
	        }

			//SW-23981
			if(!seminarTypesProcApplication.isEmpty()){
				Map<Id, User> uIds = new Map<Id, User>();
				List<Seminar_Type__Share> stslist = new List<Seminar_Type__Share>();
				for (Seminar_Type__Share sts : [SELECT Id, ParentId, UserOrGroupId FROM Seminar_Type__Share WHERE ParentId IN :seminarTypesProcApplication.keySet()]) {
					uIds.put(sts.UserOrGroupId, null);
					stslist.add(sts);
				}

				//get mf from users with share
				for (User u : [SELECT Name, MF_ID__c, Profile.Name FROM User WHERE Id IN :uIds.keySet()]) {
					uIds.put(u.Id, u);
				}

				for (Seminar_Type__Share sts : stslist) {
					if(seminarTypesProcApplication.containsKey(sts.ParentId) && uIds.containsKey(sts.UserOrGroupId)){
						for (Seminar__c sem : seminarTypesProcApplication.get(sts.ParentId)) {
							User u = uIds.get(sts.UserOrGroupId);
							Boolean isValid = u !=null && u.MF_ID__c != null && u.MF_ID__c InstanceOf ID;
							if(isValid && sem.Hosting_Franchisee__c == Id.valueOf(u.MF_ID__c) && (u.Profile.Name == 'HDC LC User' || u.Profile.Name == 'HDC LC Logistic')){
		                		sh2Ins.add(new Seminar__Share(ParentId = sem.Id, UserOrGroupId = u.Id, AccessLevel = 'Read'));
							}
						}
					}
				}

				
			}

			if(!allSeminarWithTTstatus.isEmpty()){

				for(Seminar_Teachers__c st : [SELECT Teacher__c, Seminar__r.Teacher_Trainer__r.Contact_Partner_User__c FROM Seminar_Teachers__c WHERE Seminar__c IN :allSeminarWithTTstatus]){
                	stsh2Ins.add(new Seminar_Teachers__Share(ParentId = st.Id, UserOrGroupId = st.Seminar__r.Teacher_Trainer__r.Contact_Partner_User__c, AccessLevel = 'Edit'));
                	//sttsh2Ins.add(new ContactShare(ContactId = st.Teacher__c, UserOrGroupId = st.Seminar__r.Teacher_Trainer__r.Contact_Partner_User__c, ContactAccessLevel = 'Read'));
				}

            }

            if(!sh2Ins.isEmpty()){
                Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
            }


            if(!stsh2Ins.isEmpty()){
                Database.SaveResult[] newSharingData = database.insert(stsh2Ins, false);
            }

            /*if(!sttsh2Ins.isEmpty()){
                Database.SaveResult[] newSharingData = database.insert(sttsh2Ins, false);
            }*/
		}
	}

	/******************************************************************************* 
	Name              : SeminarDeleteManualSharing
	Description       : Handler the sharing record of Seminar__c object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez 	  		07/19/2016     			Yaara 				SW-20471
	*******************************************************************************/
	
	public static void SeminarDeleteManualSharing(){
		if( HD_TriggerSettings.IsTriggerActive('SeminarDeleteManualSharing') && !Test.isRunningTest()){

			List<Seminar__c> seminar2delShare = new List<Seminar__c>();
			
			for(Integer i=0; i < trigger.size; i++ ){
				Seminar__c seminarOld = (Seminar__c) trigger.old[i];		
				Seminar__c seminar = (Seminar__c) trigger.new[i];	
				
				Boolean cond = seminarOld.Status__c == 'Confirmed' && seminar.Status__c != 'Confirmed';
								 
				if (cond) {
					seminar2delShare.add(seminar);
				}
			}

			if(!seminar2delShare.isEmpty()){
				Batch_SeminarDeleteManualSharing b = new Batch_SeminarDeleteManualSharing();
				b.seminarCancelled = seminar2delShare;
				Database.executeBatch(b,10);
				//HD_SharingMethods.SeminarDeleteManualSharing(seminar2delShare);
			}
		}
	}
}