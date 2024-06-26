/******************************************************************************* 
Name              : ContentVersion_TriggerHandler
Description       : Handler the before/after trigger on Content Version
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo	  		12/08/2016          	
*******************************************************************************/
public class ContentVersion_TriggerHandler {
	
	public static void executeTriggerHandler(){
		//Batya - commented..
		//  ---------------------------- BEFORE EVENTS -----------------------------
		/*if (Trigger.isBefore && Trigger.isInsert){
			checkForDuplicateContentVersion();
			UpdateContentPermission();
		}
		if (Trigger.isBefore && Trigger.isUpdate){
			checkForDuplicateContentVersion();
			UpdateContentPermission();
			deleteChatterGroupOnNotActive();
		}
		
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			//checkForDuplicateContentVersion();
			contentFileToChatterGroup();
		}
		
		if (Trigger.isAfter && Trigger.isUpdate){
			contentFileToChatterGroup();
			cloneContentVersionToCommunity();
		}*/
	}

	/******************************************************************************* 
	Name              : deleteChatterGroupOnNotActive
	Description       : When Content Version goes inactive, it will try to delete the Chatter Group that was created from it
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	26/01/2017          Dafna Margalit  		  [SW-23390]
	*******************************************************************************/
	//Batya - commented..
	/*public static void deleteChatterGroupOnNotActive(){
		if( HD_TriggerSettings.IsTriggerActive('deleteChatterGroupOnNotActive') ){
			List<ContentDocument> cDocs2del = new List<ContentDocument>();
			for( Integer i=0; i < trigger.size; i++ ){
				ContentVersion cvNew = (ContentVersion) trigger.new[i];
				ContentVersion cvOld = (ContentVersion) trigger.old[i];

				Boolean cond = cvNew.Status__c  != cvOld.Status__c && cvNew.Status__c == 'Not Active';
				cond &= cvNew.NetworkId == ContentVersion_Methods.hdCommunityId;

				if( cond ){
					cDocs2del.add( new ContentDocument(Id = cvNew.ContentDocumentId)  );
				}
			}

			if( !cDocs2del.isEmpty() ){
				ContentVersion_Methods.deleteCollaborationGroups( cDocs2del );
			}
		}
	}*/
	
	/******************************************************************************* 
	Name              : ContentVersion_TriggerHandler
	Description       : Handler the before/after trigger on Content Version
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio Caputo	  		10/01/2017          	Ella					SW-23163
	*******************************************************************************/
	//Batya - commented..
    /*public static void cloneContentVersionToCommunity(){
		if( HD_TriggerSettings.IsTriggerActive('checkForDuplicateContentVersion') ){
			List<ContentVersion> cv2Proc = new List<ContentVersion>();
			
			for( Integer i=0; i < trigger.size; i++ ){
				ContentVersion cvNew = (ContentVersion) trigger.new[i];
				ContentVersion cvOld = (ContentVersion) trigger.old[i];
				
				if( cvNew.Clone_Date__c != cvOld.Clone_Date__c && cvOld.Clone_Date__c == null ){
					cv2Proc.add( cvNew );
				}
			}
			
			if( !cv2Proc.isEmpty() ){
				ContentVersion_Methods.cloneContentVersionToCommunity( cv2Proc );
			}
		}
	}*/
	
	/******************************************************************************* 
	Name              : checkForDuplicateContentVersion
	Description       : Checks for duplicate CV
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio Caputo         	10/11/2016          Ella  Bernachik			  [SW-22259]
	*******************************************************************************/
	
	//Batya - commented..
    /*public static void checkForDuplicateContentVersion(){
		
		if( HD_TriggerSettings.IsTriggerActive('checkForDuplicateContentVersion') ){
			Map<String, Set<Integer>> cvByOldId = new Map<String, Set<Integer>>();
			
			for( Integer i=0; i < trigger.size; i++ ){
				ContentVersion cv = (ContentVersion) trigger.new[i];
				
				if( String.isNotBlank(cv.Content_Old_Id__c) ){
					if( !cvByOldId.containsKey( cv.Content_Old_Id__c ) ){
						cvByOldId.put( cv.Content_Old_Id__c, new Set<Integer>() );
					}
					cvByOldId.get( cv.Content_Old_Id__c ).add(i);
				}
			}
			
			system.debug('cvByOldId: ' + cvByOldId.keySet());
			for( ContentVersion cv : [SELECT Id, Title, Content_Old_Id__c, ContentDocumentId FROM ContentVersion WHERE Content_Old_Id__c IN :cvByOldId.keySet() ] ){
				Boolean isError = false;
				for( Integer i : cvByOldId.get(cv.Content_Old_Id__c) ){
					//If they have the same ContentDocument Id then they are different version from the same Content
					//Otherwise, they are duplicates and shouldn't be allowed.
					if( cv.ContentDocumentId != (Id) trigger.new[i].get('ContentDocumentId') ){
						isError = true;
						trigger.new[i].addError( Label.Content_Duplication_Error.replaceAll('File Name:', 'File Name: ' + cv.Title).replaceAll('File ID:', ' | File ID: ' + cv.Id), false );
						
						break;
					}
				}
				if( isError ){
					break;
				}
			}
			
			
			// for( Integer i=0; i < trigger.size; i++ ){
			// 	ContentVersion cv = (ContentVersion) trigger.new[i];
			// 	system.debug('cv.Content_Old_Id__c: ' + cv.Content_Old_Id__c);
			// 	system.debug('cv.VersionNumber: ' + cv.VersionNumber);
			// 	if( String.isNotBlank(cv.Content_Old_Id__c) ){
			// 		if( !cvByOldId.containsKey( cv.Content_Old_Id__c ) ){
			// 			cvByOldId.put( cv.Content_Old_Id__c, new Set<Integer>() );
			// 		}
			// 		cvByOldId.get( cv.Content_Old_Id__c ).add(i);
			// 	}
			// }
			// system.debug('cvByOldId: ' + cvByOldId.keySet());
			// for( ContentVersion cv : [SELECT Id, Title, Content_Old_Id__c, VersionNumber FROM ContentVersion WHERE Content_Old_Id__c IN :cvByOldId.keySet() ] ){
			// 	Boolean isError = false;
			// 	for( Integer i : cvByOldId.get(cv.Content_Old_Id__c) ){
			// 		if( cv.Id == trigger.new[i].Id ){
			// 			continue;
			// 		}
					
			// 		Boolean condition = cv.VersionNumber == trigger.new[i].get( 'VersionNumber' );
					
			// 		if( condition ){
			// 			//There is a match where Content_Old_Id__c is the same aswell as the VersionNumber
			// 			//Throw an error.
			// 			isError = true;
			// 			trigger.new[i].addError( Label.Content_Duplication_Error.replaceAll('File Name:', 'File Name: ' + cv.Title).replaceAll('File ID:', ' | File ID: ' + cv.Id), false );
						
			// 			break;
			// 		}
			// 	}
			// 	if( isError ){
			// 		break;
			// 	}
			// }
			
		}
	}*/
	
	/******************************************************************************* 
	Name              : contentFileToChatterGroup
	Description       : Each time a File (Content Version) is created under a Library with the relevant fields populated:
						- Create new Chatter Group - The Chatter Group should be private, broadcast only and archived
						- Create a new ContentDocumentLink to grant permissions to the Chatter Group
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio Caputo         	12/08/2016          Ella  Bernachik			  [SW-20569]
	*******************************************************************************/
	//Batya - commented..
	/*public static void contentFileToChatterGroup(){
		
		if( HD_TriggerSettings.IsTriggerActive('contentFileToChatterGroup') ){
			
			// Id hdCommunityId = [SELECT Id, Value__c FROM HD_Settings_List__c WHERE Name = 'HD Community ID' LIMIT 1][0].Value__c;
			// Map<Integer, CollaborationGroup> cg2InsByIndex = new Map<Integer, CollaborationGroup>();
			// Map<Id, Integer> cv2checkCG = new Map<Id, Integer>();
			
			List<ContentVersion> cvList = new List<ContentVersion>();
			
			for( Integer i=0; i < trigger.size; i++ ){
				ContentVersion cv = (ContentVersion) trigger.new[i];
				
				// Boolean condition = String.isNotBlank(cv.Entity_Type__c) && String.isNotBlank(cv.Program_Type__c) && String.isNotBlank(cv.Country__c) && String.isNotBlank(cv.Specific_Program__c);
				// condition &= String.isNotBlank( cv.Status__c ) && cv.Status__c.equalsIgnoreCase('Active');
				// condition &= ( trigger.isInsert || (trigger.isUpdate && ( cv.Status__c != trigger.old[i].get( 'Status__c' ) )) );
				
				// condition &= !MonitorRecursionClass.contentFileToChatterGroup_Ids.contains( trigger.new[i].Id );
				
				Boolean condition = ( trigger.isInsert || (trigger.isUpdate && ( cv.Status__c != trigger.old[i].get( 'Status__c' ) )) );
				
				if( condition || test.isRunningTest()){
					cvList.add( cv );
					
					// system.debug('cv.Title: ' + cv.Title );
					// CollaborationGroup cg = new CollaborationGroup();
					// cg.Name = cv.Title;
					// //cg.IsArchived = true;
					// cg.IsBroadcast = true;
					// cg.NetworkId = hdCommunityId;
					// cg.CollaborationType = 'Private';
					
					// cg2InsByIndex.put(i, cg);
					
					// cv2checkCG.put( cv.ContentDocumentId, i );
					
				}
			}
			
			if( !cvList.isEmpty() ){
				List<ContentVersion_Methods.CFM_Result> cfmResults = ContentVersion_Methods.createNewChatterGroup( cvList );
				Map<Id, CollaborationGroupMember> cgm2Ins = new Map<Id, CollaborationGroupMember>();
                
				for( ContentVersion_Methods.CFM_Result cfmResult : cfmResults ){
					if( !cfmResult.success ){
						trigger.newMap.get( cfmResult.contentVersion.Id ).addError( cfmResult.resultMsg );
                    }else{
                        cgm2Ins.put( cfmResult.colaborationGroup.Id, new CollaborationGroupMember(CollaborationGroupId = cfmResult.colaborationGroup.Id, MemberId = ContentVersion_Methods.userServiceWise) );
                    }
				}
                
                if( !cgm2Ins.isEmpty() ){
                    for( CollaborationGroupMember cgm : [SELECT Id, CollaborationGroupId FROM CollaborationGroupMember WHERE CollaborationGroupId IN :cgm2Ins.keySet() AND MemberId = :ContentVersion_Methods.userServiceWise ] ){
                        cgm2Ins.remove( cgm.CollaborationGroupId );
                    }
                    insert cgm2Ins.values();
                }
			}
			
			// if( !cg2InsByIndex.isEmpty() ){
			// 	//Get library Ids
			// 	Set<Id> libIds = ContentVersion_Methods.getLibrarieIds();
			// 	//Remove any Content Document that doesn't belong to the Libraries
			// 	Set<Id> cdIds = cv2checkCG.keySet();
			// 	for( ContentDocument cd : [SELECT Id FROM ContentDocument WHERE Id IN :cdIds AND ParentId NOT IN :libIds ] ){
			// 		cg2InsByIndex.remove(cv2checkCG.get(cd.Id));
			// 	}
				
			// 	//Find if for the ContentVersion there already exists a Collaboration Group, because we don't need to create one if there already exists one.
				
			// 	for( ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIds ] ){
			// 		if( cdl.LinkedEntityId.getSObjectType() == CollaborationGroup.sObjectType  ){
			// 			//Remove the index from Collaboration Groups to insert map
			// 			cg2InsByIndex.remove(cv2checkCG.get(cdl.ContentDocumentId));
			// 		}
			// 	}
				
			// 	insert cg2InsByIndex.values();
			// 	List<ContentDocumentLink> cdl2Ins = new List<ContentDocumentLink>();
				
			// 	for( Integer i : cg2InsByIndex.keySet() ){
					
			// 		ContentDocumentLink cdl = new ContentDocumentLink();
			// 		cdl.ContentDocumentId = String.valueOf( trigger.new[i].get('ContentDocumentId') );
			// 		cdl.LinkedEntityId = cg2InsByIndex.get(i).Id;
			// 		cdl.ShareType = 'V';
					
			// 		cdl2Ins.add( cdl );
					
			// 		MonitorRecursionClass.contentFileToChatterGroup_Ids.add( trigger.new[i].Id );
			// 	}
				
			// 	if( !cdl2Ins.isEmpty() ){
			// 		insert cdl2Ins;
			// 	}
				
			// 	for( CollaborationGroup cg : cg2InsByIndex.values() ){
			// 		cg.IsArchived = true;
			// 	}
			// 	update cg2InsByIndex.values();
			// }
			
		}
	}*/

	/******************************************************************************* 
	Name              : UpdateContentPermission
	Description       : Each change in EITHER of the fields will change this field to be TRUE
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	22/09/2016          Ella  Bernachik			  [SW-21578]
	*******************************************************************************/
	//Batya - commented..
	/*public static void UpdateContentPermission(){
		if( HD_TriggerSettings.IsTriggerActive('UpdateContentPermission') ){
			for( Integer i=0; i < trigger.size; i++ ){
				ContentVersion cv = (ContentVersion) trigger.new[i];
				Boolean condition = Trigger.isUpdate;
				if(condition){
					ContentVersion oldcv = (ContentVersion) trigger.old[i];
					condition = cv.Entity_Type__c != oldcv.Entity_Type__c;
					condition |= cv.Program_Type__c != oldcv.Program_Type__c;
					condition |= cv.Specific_Program__c != oldcv.Specific_Program__c;
					condition |= cv.Country__c != oldcv.Country__c;
					condition |= cv.Status__c != oldcv.Status__c;
				}
				if(Trigger.isInsert || condition){
					cv.Update_Content_Permission__c = true;
				}
			}
		}
	}*/
	
}