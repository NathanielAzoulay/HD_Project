/******************************************************************************* 
Name              : Batch_CFM_Contacts
Description       : Goes through all Users and checks whether they can be associated to new/changed Content Version files.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo            23/08/2016              
*******************************************************************************/
global class Batch_CFM_Contacts implements Database.Batchable<sObject>, Database.Stateful{
    /* Testing
Batch_CFM_Contacts b = new Batch_CFM_Contacts();
b.restrictConIds.add('003e000000cIFl8');
b.restrictConIds.add('003e000000bedXp');
b.restrictCVIds.add('068e00000009UNH');

system.debug( 'b.restrictConIds: ' + b.restrictConIds );
system.debug( 'b.restrictCVIds: ' + b.restrictCVIds );

database.executebatch(b);
    */
    //public Set<Id> contentVersionIds = new Set<Id>();
    public String entityTypes = '';
    public String programTypes = '';
    public String specificPrograms = '';
    public Set<String> mailingCoutries = new Set<String>();
    
    public Map<Id, ContentVersion> cvMap = new Map<Id, ContentVersion>();
    public Map<Id, HD_Log__c> hdLogByCV = new Map<Id, HD_Log__c>();
    public HD_Log__c hdLogWithCVIds = new HD_Log__c();
    
    public String query = 'SELECT Id, Entity_Type__c, Program_Type__c, Specific_Program__c, MailingCountry FROM Contact WHERE MailingCountry != null AND MailingCountry IN :mailingCoutries ';
    
    public Set<String> restrictConIds = new Set<String>();
    public Set<String> restrictCVIds = new Set<String>();
    
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
        //Set<String> mailingCoutriesSet = new Set<String>();
        
        //Get library Ids
        Set<Id> libIds = ContentVersion_Methods.getLibrarieIds();
        
        String cvQuery = 'SELECT '+ ContentVersion_Methods.cvFields +' FROM ContentVersion WHERE IsLatest = true AND Update_Content_Permission__c = true AND ContentDocument.ParentId IN :libIds  ';
        
        if( !restrictCVIds.isEmpty() ){
            cvQuery += ' AND Id IN :restrictCVIds ';
        }
        
        if( !errorRecords.isEmpty() ){
            cvQuery += ' AND Id NOT IN :errorRecords ';
        }
        
        if( !procRecords.isEmpty() ){
            cvQuery += ' AND Id NOT IN :procRecords ';
        }
        
        if( recLimit > 0 ){
            cvQuery += ' LIMIT :recLimit ';
        }
        
        cvMap = new Map<Id, ContentVersion>( (List<ContentVersion>)database.query(cvQuery) );
        for( ContentVersion cv : cvMap.values() ){
            if( String.isNotBlank(cv.Entity_Type__c) ){
                entityTypesSet.addAll( cv.Entity_Type__c.split(';') );
            }
            if( String.isNotBlank(cv.Program_Type__c) ){
                programTypesSet.addAll( cv.Program_Type__c.split(';') );
            }
            if( String.isNotBlank(cv.Specific_Program__c) ){
                specificProgramsSet.addAll( cv.Specific_Program__c.split(';') );
            }
            if( String.isNotBlank(cv.Country__c) ){
                //mailingCoutriesSet.addAll( cv.Country__c.split(';') );
                mailingCoutries.addAll( cv.Country__c.split(';') );
            }
        }
        /*
        entityTypes = String.valueOf(entityTypesSet).removeStart('{').removeEnd('}').replaceAll(',',';');
        programTypes = String.valueOf(programTypesSet).removeStart('{').removeEnd('}').replaceAll(',',';');
        specificPrograms = String.valueOf(specificProgramsSet).removeStart('{').removeEnd('}').replaceAll(',',';');
        //mailingCoutries = String.valueOf(mailingCoutriesSet).removeStart('{').removeEnd('}').replaceAll(',',';');
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
        
        query += ' AND Entity_Type__c != null AND Entity_Type__c includes( '+entityTypes+') AND Program_Type__c != null AND Program_Type__c includes('+programTypes+') AND Specific_Program__c != null AND Specific_Program__c includes('+specificPrograms+') ';
        
        if( !restrictConIds.isEmpty() ){
            query += ' AND Id IN :restrictConIds';
        }
        
        system.debug( 'entityTypes: ' + entityTypes );
        system.debug( 'programTypes: ' + programTypes );
        system.debug( 'specificPrograms: ' + specificPrograms );
        
        system.debug( 'query: ' + query );
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, list<Sobject> scope) {
        Savepoint sp = Database.setSavepoint();
        hdLogByCV = new Map<Id, HD_Log__c>();
        
        try{
            Map<Id, Set<Id> > contactIds = new Map<Id, Set<Id> >();
            //Set<Id> conVerIds = new Set<Id>();
            Map<Id, Id> conDocIds = new Map<Id, Id>();
            
            for( Contact con : (List<Contact>) scope ){
                contactIds.put( con.Id, new Set<Id>() );
                
                for( ContentVersion cv : cvMap.values() ){
                    
                    if( ContentVersion_Methods.canSee(con, cv) ){
                        //This Content Version with this Contact is a Match
                        contactIds.get( con.Id ).add( cv.ContentDocumentId );
                        //conVerIds.add(cv.Id);
                        conDocIds.put( cv.ContentDocumentId, cv.Id );
                    }
                }
            }
            
            system.debug( 'conDocIds: ' + conDocIds );
            
            if( !conDocIds.isEmpty() ){
                Map<Id, Set<Id>> collGroup = new Map<Id, Set<Id>>();
                Map<Id, Id> collGroupByConDoc = new Map<Id, Id>();
                Set<Id> cdIds = conDocIds.keySet();
                
                for( ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIds ] ){
                    if( cdl.LinkedEntityId.getSObjectType() == CollaborationGroup.sObjectType  ){
                        if( !collGroup.containsKey( cdl.LinkedEntityId ) ){
                            collGroup.put( cdl.LinkedEntityId, new Set<Id>() );
                        }
                        collGroup.get( cdl.LinkedEntityId ).add( cdl.ContentDocumentId );
                        
                        //Assuming thats only a 1v1 relation between Content Document and CollaborationGroupMember
                        collGroupByConDoc.put( cdl.ContentDocumentId, cdl.LinkedEntityId );
                    }
                }
                system.debug('contactIds: ' + contactIds);
                system.debug('collGroup: ' + collGroup);
                
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
                    system.debug('cgm: ' + cgm);
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
                    
                    Set<Id> userMemeberIds = new Set<Id>();
                    
                    //Some Contact remain with Content Version that do not have a Content File Membership, thus no relationship to the Collaboration Group itself
                    List<CollaborationGroupMember> cgm2Ins = new List<CollaborationGroupMember>();
                    Map<Id, Map<Id, Id>> cdIdByCGIdByMemberId = new Map<Id, Map<Id, Id>>();
                    
                    for( Id conId : contactIds.keySet() ){
                        Id userId = userByCon.get( conId );
                        
                        cdIdByCGIdByMemberId.put( userId, new Map<Id, Id>() );
                        
                        for( Id cdId : contactIds.get(conId) ){
                            if( collGroupByConDoc.containsKey( cdId ) ){
                                CollaborationGroupMember cgm = new CollaborationGroupMember();
                                cgm.CollaborationGroupId = collGroupByConDoc.get( cdId );
                                cgm.MemberId = userId;
                                
                                if( cgm.CollaborationGroupId != null && cgm.MemberId != null ){
                                    userMemeberIds.add(cgm.MemberId); 
                                    cgm2Ins.add(cgm);
                                    cdIdByCGIdByMemberId.get( userId ).put( cgm.CollaborationGroupId, cdId );
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
                            
                            system.debug( 'cgm2Ins[i].MemberId: ' + cgm2Ins[i].MemberId );
                            system.debug( 'userMap.get(cgm2Ins[i].MemberId).ContactId: ' + userMap.get(cgm2Ins[i].MemberId).ContactId );
                            system.debug( 'sr.isSuccess(): ' + sr.isSuccess() );
                            
                            if(!sr.isSuccess()){
                                Id cvId = conDocIds.get( cdIdByCGIdByMemberId.get( cgm2Ins[i].MemberId ).get( cgm2Ins[i].CollaborationGroupId ) );
                                errorRecords.add( cvId );
                                hdLogByCV.put( cvId, new HD_Log__c( Contact__c = userMap.get(cgm2Ins[i].MemberId).ContactId, Error_Description__c = 'Error Code [101]: ' + sr.getErrors()[0].getMessage(), Status__c = 'Fail', Process_Name__c = 'Batch_CFM_Contacts' ) );
                                hdLogWithCVIds.Error_Description__c = cvId + ',';
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
        }catch( Exception e ){
        	CatchException(e, sp, hdLogByCV);
        }
        
        if( !hdLogByCV.isEmpty() ){
        	hdLogWithCVIds.Process_Name__c = 'Batch_CFM_Contacts';
        	hdLogWithCVIds.Status__c = 'Fail';
        	hdLogWithCVIds.Error_Description__c = 'ContentVersion Ids: ' + hdLogWithCVIds.Error_Description__c;
        	hdLogByCV.put(null, hdLogWithCVIds);
            insert hdLogByCV.values();
        }
    }

    global void finish(Database.BatchableContext BC) {
        
        List<ContentVersion> cv2Upd = new List<ContentVersion>();
        
        for( Id cvId : cvMap.keySet() ){
            procRecords.add( cvId );
            if( !errorRecords.contains(cvId) ){
                cv2Upd.add( new ContentVersion(Id = cvId, Update_Content_Permission__c = false) );
            }
            
            if( hdLogByCV.containsKey(cvId) ){
                cv2Upd.add( new ContentVersion(Id = cvId, HD_Log__c = hdLogByCV.get(cvId).Id ) );
            }
        }
        
        //update cv2UnFlag;
        List<Database.SaveResult> slr = Database.update(cv2Upd,false);
        List<HD_Log__c> hdLogs2Ins = new List<HD_Log__c>();
        
        for(Integer i = 0; i < slr.size(); i++){
            Database.SaveResult sr = slr.get(i);
            if(!sr.isSuccess()){
                errorRecords.add( cv2Upd[i].Id );
                hdLogs2Ins.add( new HD_Log__c( Contact__c = cvMap.get( cv2Upd[i].Id ).Owner.ContactId, Error_Description__c = 'Error Code [102]: ' + sr.getErrors()[0].getMessage(), Status__c = 'Fail', Process_Name__c = 'Batch_CFM_Contacts' ) );
            }
        }
        
        if( !hdLogs2Ins.isEmpty() ){
            insert hdLogs2Ins;
            system.debug('hdLogs2Ins:' + hdLogs2Ins);
        }
        
        Set<Id> libIds = ContentVersion_Methods.getLibrarieIds();
        
        //Check if there are still more Content Version to process
        String reiterateQuery = 'SELECT Id FROM ContentVersion WHERE IsLatest = true AND Update_Content_Permission__c = true AND Id NOT IN :errorRecords AND Id NOT IN :procRecords AND ContentDocument.ParentId IN :libIds  ';
        if( !restrictCVIds.isEmpty() ){
            reiterateQuery += ' AND Id IN :restrictCVIds ';
        }
        reiterateQuery += ' LIMIT 1';
        
        if( !database.query(reiterateQuery).isEmpty() ){
            Batch_CFM_Contacts batch = new Batch_CFM_Contacts();
            batch.procRecords = procRecords;
            batch.errorRecords = errorRecords;
            batch.restrictCVIds = restrictCVIds;
            batch.restrictConIds = restrictConIds;
            batch.recLimit = recLimit;
            batch.limitBatch = limitBatch;
            if(!Test.isRunningTest()){ // for avoiding the test error "System.LimitException: Too many async jobs enqueued for this apex test context" 
                //database.executeBatch(batch);
                Batch_CFM_Contacts.RunBatch(batch, limitBatch);
            }
        }
    }
	
	public static void RunBatch( Batch_CFM_Contacts batch, Integer limitBatch ){
		batch.limitBatch = limitBatch;
		database.executeBatch( batch, limitBatch );
	}
	
	public void CatchException( Exception e, Savepoint sp, Map<Id, HD_Log__c> hdLogs2Ins ){
		//Moving the Catch to a method for ease of coverage. Functionaly, its the same.
        Database.rollback(sp);
        
        GlobalHelperMethods.debugErrorMsg(e);
        
        for( ContentVersion cv : cvMap.values() ){
            errorRecords.add( cv.Id );
            
            hdLogByCV.put( cv.Id, new HD_Log__c( Contact__c = cv.Owner.ContactId, Error_Description__c = 'Error Code [100]: ' + GlobalHelperMethods.ImproveErrorMessage(e), Status__c = 'Fail', Process_Name__c = 'Batch_CFM_Contacts' ) );
            hdLogWithCVIds.Error_Description__c = cv.Id + ',';
        }
	}
}