public without sharing class NotificationNetworkSetting {
    
    public static void disableNotification(Set<Id> userIds){ 
   	 	
   	 	enable_disable_commonlogic(userIds, true);   	 	
   	}
    
    public static void enableNotification(Set<Id> userIds){
    	
    	enable_disable_commonlogic(userIds, false);
    }
    
    private static void enable_disable_commonlogic(Set<Id> userIds, Boolean disable){
    	
    	Id hdCommId = ContentVersion_Methods.hdCommunityId;
    	
    	List<NetworkMember> networkMembers2Up = new List<NetworkMember>();
        for(List<NetworkMember> networkMembers : [SELECT Id, MemberId FROM NetworkMember WHERE MemberId IN :userIds AND NetworkId =: hdCommId]){
        	for(NetworkMember nm : networkMembers){
        		nm.PreferencesDisableAllFeedsEmail = disable;
        		networkMembers2Up.add(nm);
        	}
        }
        
        if(!networkMembers2Up.isEmpty()){
        	update networkMembers2Up;	
	    } 
    }
}