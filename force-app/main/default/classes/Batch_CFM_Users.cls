/******************************************************************************* 
Name              : Batch_CFM_Users
Description       : Goes through all ContentVersion and checks whether they can be associated to Users.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo            23/08/2016              
*******************************************************************************/
global class Batch_CFM_Users implements Database.Batchable<sObject>, Database.Stateful{
    /* Testing
Batch_CFM_Users b = new Batch_CFM_Users();
b.restrictConIds.add('003e000000cIFl8');
b.restrictConIds.add('003e000000bedXp');
b.restrictCVIds.add('068e00000009UNH');

system.debug( 'b.restrictConIds: ' + b.restrictConIds );
system.debug( 'b.restrictCVIds: ' + b.restrictCVIds );

database.executebatch(b);
    */
    //public Set<Id> contactIds = new Set<Id>();
    public Map<Id, Contact> conMap = new Map<Id, Contact>();
    
    public String entityTypes = '';
    public String programTypes = '';
    public String specificPrograms = '';
    public String mailingCoutries = '';
    
    //Get library Ids
    public Set<Id> libIds = ContentVersion_Methods.getLibrarieIds();
    
    public String query = 'SELECT ' + ContentVersion_Methods.cvFields + '  FROM ContentVersion WHERE IsLatest = true AND ContentDocument.ParentId IN :libIds  ';
    
    public Set<String> restrictCVIds = new Set<String>();
    public Set<String> restrictConIds = new Set<String>();
    
    public Integer recLimit = 0;
    public Integer limitBatch = 0;
    
    //Record Ids that had an error on processing. Unchecking these on the finish would prevent them from being re-executed.
    //HOWEVER, leaving them marked would leave the Batch in an infinite loop.
    //This set is to not update them but also not bring them again for processing
    public Set<Id> errorRecords = new Set<Id>();
    
    public Set<Id> procRecords = new Set<Id>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> entityTypesSet = new Set<String>();
        Set<String> programTypesSet = new Set<String>();
        Set<String> specificProgramsSet = new Set<String>();
        Set<String> mailingCoutriesSet = new Set<String>();
        
        String conQuery = 'SELECT Id, Entity_Type__c, Program_Type__c, Specific_Program__c, MailingCountry FROM Contact WHERE Update_Contact_Permission__c = true ';
        
        if( !restrictConIds.isEmpty() ){
            conQuery += ' AND Id IN :restrictConIds ';
        }
        
        if( !errorRecords.isEmpty() ){
            conQuery += ' AND Id NOT IN :errorRecords ';
        }
        
        if( !procRecords.isEmpty() ){
            conQuery += ' AND Id NOT IN :procRecords ';
        }
        
        if( recLimit > 0 ){
            conQuery += ' LIMIT :recLimit ';
        }
        system.debug('conQuery: ' + conQuery);
        conMap = new Map<Id, Contact>( (List<Contact>) database.query(conQuery));
        
        for( Contact con : conMap.values() ){
            if( String.isNotBlank(con.Entity_Type__c) ){
                entityTypesSet.addAll( con.Entity_Type__c.split(';') );
            }
            if( String.isNotBlank(con.Program_Type__c) ){
                programTypesSet.addAll( con.Program_Type__c.split(';') );
            }
            if( String.isNotBlank(con.Specific_Program__c) ){
                specificProgramsSet.addAll( con.Specific_Program__c.split(';') );
            }
            if( String.isNotBlank(con.MailingCountry) ){
                mailingCoutriesSet.addAll( con.MailingCountry.split(';') );
            }
        }
        /*
        entityTypes = String.valueOf(entityTypesSet).removeStart('{').removeEnd('}').replaceAll(',',';');
        programTypes = String.valueOf(programTypesSet).removeStart('{').removeEnd('}').replaceAll(',',';');
        specificPrograms = String.valueOf(specificProgramsSet).removeStart('{').removeEnd('}').replaceAll(',',';');
        mailingCoutries = String.valueOf(mailingCoutriesSet).removeStart('{').removeEnd('}').replaceAll(',',';');
        */
        
        if( entityTypesSet.isEmpty() ){
            entityTypesSet.add('');
        }
        
        if( programTypesSet.isEmpty() ){
            programTypesSet.add('');
        }
        
        if( specificProgramsSet.isEmpty() ){
            specificProgramsSet.add('');
        }
        
        if( mailingCoutriesSet.isEmpty() ){
            mailingCoutriesSet.add('');
        }
        
        for( String s : entityTypesSet ){
            entityTypes += ',\'' + s + '\'';
        }
        entityTypes = entityTypes.substring(1);
        
        for( String s : programTypesSet ){
            programTypes += ',\'' + s + '\'';
        }
        programTypes = programTypes.substring(1) ;
        
        for( String s : specificProgramsSet ){
            specificPrograms += ',\'' + s + '\'';
        }
        specificPrograms =  specificPrograms.substring(1) ;
        
        for( String s : mailingCoutriesSet ){
            mailingCoutries += ',\'' + s + '\'';
        }
        mailingCoutries =  mailingCoutries.substring(1) ;
        
        query += ' AND Entity_Type__c != null AND Entity_Type__c includes( '+entityTypes+') AND Program_Type__c != null AND Program_Type__c includes('+programTypes+') AND Specific_Program__c != null AND Specific_Program__c includes('+specificPrograms+') AND Country__c != null AND Country__c includes('+mailingCoutries+') ';
        
        if( !restrictCVIds.isEmpty() ){
            query += ' AND Id IN :restrictCVIds';
        }
        
        system.debug( 'entityTypes: ' + entityTypes );
        system.debug( 'programTypes: ' + programTypes );
        system.debug( 'specificPrograms: ' + specificPrograms );
        system.debug( 'mailingCoutries: ' + mailingCoutries );
        system.debug( 'query: ' + query );
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, list<Sobject> scope) {
        Savepoint sp = Database.setSavepoint();
        List<HD_Log__c> hdLogs2Ins = new List<HD_Log__c>();
        
        try{
            Map<Id, Set<Id> > contactIds = new Map<Id, Set<Id> >();
            Set<Id> conVerIds = new Set<Id>();
            Set<Id> conDocIds = new Set<Id>();
            
            for( ContentVersion cv : (List<ContentVersion>) scope ){
                for( Contact con : conMap.values() ){
                    if( ContentVersion_Methods.canSee(con, cv) ){
                        if( !contactIds.containsKey(con.Id) ){
                            contactIds.put( con.Id, new Set<Id>() );
                        }
                        //This Content Version with this Contact is a Match
                        contactIds.get( con.Id ).add( cv.ContentDocumentId );
                        //conVerIds.add(cv.Id);
                        conDocIds.add( cv.ContentDocumentId );
                    }
                }
            }
            
            if( !conDocIds.isEmpty() ){
                Map<Id, Set<Id>> collGroup = new Map<Id, Set<Id>>();
                Map<Id, Id> collGroupByConDoc = new Map<Id, Id>();
                
                for( ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :conDocIds ] ){
                    if( cdl.LinkedEntityId.getSObjectType() == CollaborationGroup.sObjectType  ){
                        if( !collGroup.containsKey( cdl.LinkedEntityId ) ){
                            collGroup.put( cdl.LinkedEntityId, new Set<Id>() );
                        }
                        collGroup.get( cdl.LinkedEntityId ).add( cdl.ContentDocumentId );
                        
                        //Assuming thats only a 1v1 relation between Content Document and CollaborationGroupMember
                        collGroupByConDoc.put( cdl.ContentDocumentId, cdl.LinkedEntityId );
                    }
                }
                
                Map<Id, Id> userByCon = new Map<Id, Id>();
                Map<Id, User> userMap = new Map<Id, User>();
                
                for( User us : [SELECT Id, ContactId, isActive FROM User WHERE ContactId IN :contactIds.keySet() ] ){
                    if( us.isActive ){
                        userByCon.put(us.ContactId, us.Id );
                        userMap.put(us.Id, us);
                    }else{
                        contactIds.remove( us.ContactId );
                    }
                }
                
                for( CollaborationGroupMember cgm : [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId IN :userMap.keySet() AND CollaborationGroupId IN :collGroup.keySet() ] ){
                    //This logic should remove those Content Document Ids that already exist for the Contact on a Collaboration Group Member
                    //Meaning that the relation between the Contact and the Content Document already exists.
                    Id conId = userMap.get(cgm.MemberId).ContactId;
                    if( contactIds.containsKey( conId ) ){
                        Set<Id> cdIdFromGroup = collGroup.get( cgm.CollaborationGroupId );
                        contactIds.get( conId ).removeAll( cdIdFromGroup );
                        
                        if( contactIds.get( conId ).isEmpty() ){
                            contactIds.remove( conId );
                        }
                    }
                }
                
                if( !contactIds.isEmpty() ){
                    //Some Contact remain with Content Version that do not have a Content File Membership, thus no relationship to the Collaboration Group itself
                    
                    Set<Id> userMemeberIds = new Set<Id>();
                    
                    List<CollaborationGroupMember> cgm2Ins = new List<CollaborationGroupMember>();
                    
                    for( Id conId : contactIds.keySet() ){
                        for( Id cdId : contactIds.get(conId) ){
                            if( collGroupByConDoc.containsKey( cdId ) ){
                                CollaborationGroupMember cgm = new CollaborationGroupMember();
                                cgm.CollaborationGroupId = collGroupByConDoc.get( cdId );
                                cgm.MemberId = userByCon.get( conId );
                     			
                                if( cgm.CollaborationGroupId != null && cgm.MemberId != null ){
                                    userMemeberIds.add(cgm.MemberId);      
                                    cgm2Ins.add(cgm);
                                }
                            }
                        }
                    }
                    
                    if( !cgm2Ins.isEmpty() ){
                    
                    	// -- CODE BLOCK FOR DISABLE THE FEED NOTIFICATION BEFORE CREATING THE MEMBER ON THE GROUP --
                    	Id hdCommId = ContentVersion_Methods.hdCommunityId;
                    
	                    List<NetworkMember> networkMembers2Up = new List<NetworkMember>();
	                    List<CustomNetworkMember__c> customNetworkMembers2Ins = new List<CustomNetworkMember__c>();
	                    
	                    for(List<NetworkMember> networkMembers : [SELECT Id FROM NetworkMember WHERE PreferencesDisableAllFeedsEmail = false AND MemberId IN :userMemeberIds AND NetworkId =: hdCommId]){
	                    	for(NetworkMember nm : networkMembers){
	                    		
	                    		nm.PreferencesDisableAllFeedsEmail = true;
	                    		networkMembers2Up.add(nm);
	                    		customNetworkMembers2Ins.add(new CustomNetworkMember__c(NetworkMemberId__c = nm.Id));
	                    	}
	                    }
	                    
	                    if(!networkMembers2Up.isEmpty()){
	                    	insert customNetworkMembers2Ins; // This is a creation of custom object that will support async rollback when the process fail in the middle and cannot apply 
	                    									 // the rollabck on the NetworkMember record, since what we are doing here is disable the email notification on Community over 
	                    									 // chatter groups. 
	                    	update networkMembers2Up;		 // Disble the chatter groups notification when join the user on the group...
	                    }
	                    // -- END PATIAL --
                        
                        List<Database.SaveResult> slr = Database.insert(cgm2Ins,false);
                        for(Integer i = 0; i < slr.size(); i++){
                            Database.SaveResult sr = slr.get(i);
                            if(!sr.isSuccess()){
                                hdLogs2Ins.add( new HD_Log__c( Contact__c = userMap.get(cgm2Ins[i].MemberId).ContactId, Error_Description__c = sr.getErrors()[0].getMessage(), Status__c = 'Fail', Process_Name__c = 'Batch_CFM_Users' ) );
                            }
                        }
                        
                        // -- CODE BLOCK FOR DISABLE THE FEED NOTIFICATION BEFORE CREATING THE MEMBER ON THE GROUP --
	                    if(!networkMembers2Up.isEmpty()){ // We apply the rollback on the NetworkMember since we need to active again the notification on any chatter feed.
	                    	
	                    	List<NetworkMember> networkMembers2UpRollback = new List<NetworkMember>();
	                    	for(NetworkMember nm : networkMembers2Up){
	                    		nm.PreferencesDisableAllFeedsEmail = false;
	                    		networkMembers2UpRollback.add(nm);
	                    	}
	                    	update networkMembers2UpRollback;
	                    	delete customNetworkMembers2Ins;
	                    }
	                    // -- END --                        
                    }
                }
            }
        }catch(Exception e){
            CatchException(e, sp, hdLogs2Ins);
        }
        
        if( !hdLogs2Ins.isEmpty() ){
            insert hdLogs2Ins;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        List<Contact> con2UnFlag = new List<Contact>();
        
        for( Id conId : conMap.keySet() ){
            procRecords.add( conId );
            if( !errorRecords.contains( conId ) ){
                con2UnFlag.add( new Contact(Id = conId, Update_Contact_Permission__c = false) );
            }
        }
        
        update con2UnFlag;
        
        //Check if there are still more Contact to process
        String reiterateQuery = 'SELECT Id FROM Contact WHERE Update_Contact_Permission__c = true AND Id NOT IN :errorRecords AND Id NOT IN :procRecords ';
        if( !restrictCVIds.isEmpty() ){
            reiterateQuery += ' AND Id IN :restrictConIds  ';
        }
        reiterateQuery += ' LIMIT 1';
        
        if( !database.query(reiterateQuery).isEmpty() ){
            Batch_CFM_Users batch = new Batch_CFM_Users();
            batch.errorRecords = errorRecords;
            batch.procRecords = procRecords;
            batch.restrictCVIds = restrictCVIds;
            batch.restrictConIds = restrictConIds;
            batch.recLimit = recLimit;
            batch.limitBatch = limitBatch;
            if( !test.isRunningTest() ){
                //database.executeBatch(batch);
                Batch_CFM_Users.RunBatch(batch, limitBatch);
            }
        }
    }
    
    public static void RunBatch( Batch_CFM_Users batch, Integer limitBatch ){
		batch.limitBatch = limitBatch;
		database.executeBatch( batch, limitBatch );
	}
	
	public void CatchException( Exception e, Savepoint sp, List<HD_Log__c> hdLogs2Ins ){
		//Moving the Catch to a method for ease of coverage. Functionaly, its the same.
		Database.rollback(sp);
        GlobalHelperMethods.debugErrorMsg(e);
        
        for( Contact con : conMap.values() ){
            errorRecords.add( con.Id );
            
            hdLogs2Ins.add( new HD_Log__c( Contact__c = con.Id, Error_Description__c = GlobalHelperMethods.ImproveErrorMessage(e), Status__c = 'Fail', Process_Name__c = 'Batch_CFM_Users' ) );
        }
	}
}