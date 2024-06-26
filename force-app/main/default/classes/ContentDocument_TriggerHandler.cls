/******************************************************************************* 
Name              : ContentDocument_TriggerHandler
Description       : Handler the before/after trigger on Content Document
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo	  		09/11/2016          	
*******************************************************************************/
public class ContentDocument_TriggerHandler {
	public static void executeTriggerHandler(){
		
		//  ---------------------------- BEFORE EVENTS -----------------------------
		if (Trigger.isBefore && Trigger.isInsert){
			
		}
		if (Trigger.isBefore && Trigger.isUpdate){ 
			
		}
		if (Trigger.isBefore && Trigger.isDelete){ 
			deleteChatterGroupOnDelete();
		}
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			
		}
		
		if (Trigger.isAfter && Trigger.isUpdate){
			contentDocumentToChatterGroup();
		}
		
		if (Trigger.isAfter && Trigger.isDelete){
			
		}
	}
	
	/******************************************************************************* 
	Name              : deleteChatterGroupOnDelete
	Description       : On deletion of a Content Document, it will try to delete the Chatter Group that was created from it
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio Caputo         	07/12/2016          Ella  Bernachik			  [SW-20569]
	*******************************************************************************/
	
	public static void deleteChatterGroupOnDelete(){
		if( HD_TriggerSettings.IsTriggerActive('deleteChatterGroupOnDelete') ){
			ContentVersion_Methods.deleteCollaborationGroups( (List<ContentDocument>) trigger.old );
		}
	}
	
	public static void contentDocumentToChatterGroup(){
		if( HD_TriggerSettings.IsTriggerActive('contentDocumentToChatterGroup') ){
			/*
			Id hdCommunityId = [SELECT Id, Value__c FROM HD_Settings_List__c WHERE Name = 'HD Community ID' LIMIT 1][0].Value__c;
			Map<Integer, CollaborationGroup> cg2InsByIndex = new Map<Integer, CollaborationGroup>();
			Map<Id, Integer> cv2checkCG = new Map<Id, Integer>();
			*/
			List<ContentDocument> cdList = new List<ContentDocument>();
			
			for( integer i=0; i < trigger.size; i++ ){
				Boolean condition = trigger.new[i].get('ParentId') != trigger.old[i].get('ParentId');
				condition &= !MonitorRecursionClass.contentFileToChatterGroup_Ids.contains( trigger.new[i].Id );
				
				if( condition ){
					cdList.add( (ContentDocument) trigger.new[i] );
					/*
					CollaborationGroup cg = new CollaborationGroup();
					//cg.Name = cv.Title;
					//cg.IsArchived = true;
					cg.IsBroadcast = true;
					cg.NetworkId = hdCommunityId;
					cg.CollaborationType = 'Private';
					
					cg2InsByIndex.put(i, cg);
					
					cv2checkCG.put( trigger.new[i].Id , i );
					*/
				}
			}
			
			if( !cdList.isEmpty() ){
				List<ContentVersion_Methods.CFM_Result> cfmResults = ContentVersion_Methods.createNewChatterGroup( cdList );
				Map<Id, CollaborationGroupMember> cgm2Ins = new Map<Id, CollaborationGroupMember>();
                
				for( ContentVersion_Methods.CFM_Result cfmResult : cfmResults ){
					if( !cfmResult.success ){
						system.debug( 'cfmResult: ' + cfmResult );
						system.debug( 'cfmResult: ' + cfmResult.contentVersion );
						system.debug( 'cfmResult: ' + cfmResult.resultMsg );
						trigger.newMap.get( cfmResult.contentVersion.ContentDocumentId ).addError( cfmResult.resultMsg );
                    }else{
                        //Success, we create a member for Service Wise User if it doesn't exist
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
			/*
			if( !cg2InsByIndex.isEmpty() ){
				//Get library Ids
				Set<Id> libIds = ContentVersion_Methods.getLibrarieIds();
				//Remove any Content Document that doesn't belong to the Libraries
				Set<Id> cdIds = cv2checkCG.keySet();
				for( ContentDocument cd : [SELECT Id FROM ContentDocument WHERE Id IN :cdIds AND ParentId NOT IN :libIds ] ){
					cg2InsByIndex.remove(cv2checkCG.get(cd.Id));
				}
				
				//Find if for the ContentVersion there already exists a Collaboration Group, because we don't need to create one if there already exists one.
				
				for( ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIds ] ){
					if( cdl.LinkedEntityId.getSObjectType() == CollaborationGroup.sObjectType  ){
						//Remove the index from Collaboration Groups to insert map
						cg2InsByIndex.remove(cv2checkCG.get(cdl.ContentDocumentId));
					}
				}
				
				for( ContentVersion cv : [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN : cv2checkCG.keySet() AND IsLatest = true ] ){
					Integer index = cv2checkCG.get( cv.ContentDocumentId );
					
					if( cg2InsByIndex.containsKey(index) ){
						cg2InsByIndex.get(index).Name = cv.Title;
					}
				}
				
				insert cg2InsByIndex.values();
				List<ContentDocumentLink> cdl2Ins = new List<ContentDocumentLink>();
				
				for( Integer i : cg2InsByIndex.keySet() ){
					
					ContentDocumentLink cdl = new ContentDocumentLink();
					cdl.ContentDocumentId = String.valueOf( trigger.new[i].Id );
					cdl.LinkedEntityId = cg2InsByIndex.get(i).Id;
					cdl.ShareType = 'V';
					
					cdl2Ins.add( cdl );
					
					MonitorRecursionClass.contentFileToChatterGroup_Ids.add( trigger.new[i].Id );
				}
				
				if( !cdl2Ins.isEmpty() ){
					insert cdl2Ins;
				}
				
				for( CollaborationGroup cg : cg2InsByIndex.values() ){
					cg.IsArchived = true;
				}
				update cg2InsByIndex.values();
			}
			*/
		}
	}
}