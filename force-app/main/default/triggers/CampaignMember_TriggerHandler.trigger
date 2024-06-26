/******************************************************************************* 
Name              : CampaignMember_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez     			16/05/2016           
*******************************************************************************/

trigger CampaignMember_TriggerHandler on CampaignMember(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	CampaignMember_TriggerHandler.executeTriggerHandler();
}