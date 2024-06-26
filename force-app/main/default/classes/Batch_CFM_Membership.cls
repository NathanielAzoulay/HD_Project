/******************************************************************************* 
Name              : Batch_CFM_Membership
Description       : Goes through all CollaborationGroupMember and checks if they are still valid. If not, they get deleted.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo            23/08/2016              
*******************************************************************************/
global without sharing class Batch_CFM_Membership implements Database.Batchable<sObject>, Database.Stateful{
    /* Testing
Batch_CFM_Membership b = new Batch_CFM_Membership();

for( CollaborationGroupMember cgm : [SELECT Id FROM CollaborationGroupMember WHERE CollaborationGroup.Name = 'test v1'] ){
b.restrictCGMIds.add(cgm.Id);
}

b.restrictCVIds.add('068e00000009UNH');

system.debug( 'b.restrictCGMIds: ' + b.restrictCGMIds );
system.debug( 'b.restrictCVIds: ' + b.restrictCVIds );

database.executebatch(b);
    */
    public String query = 'SELECT Id, CollaborationGroupId, MemberId, Member.ContactId, Member.Contact.Entity_Type__c, Member.Contact.Program_Type__c, Member.Contact.Specific_Program__c, Member.Contact.MailingCountry FROM CollaborationGroupMember WHERE';
    
    public Set<Id> collaborationGroupIds = new Set<Id>();
    public Set<Id> contactIds = new Set<Id>();
    
    public Map<Id, ContentVersion> cvByContDocId = new Map<Id, ContentVersion>();
    public Map<Id, Id> contDocByCollabGroup = new Map<Id, Id>();
    
    public Set<Id> sObj2UnFlag = new Set<Id>();
    
    public Boolean running4CV = true;
    public Integer step = 0;
    
    public Set<String> restrictCGMIds = new Set<String>();
    public Set<String> restrictCVIds = new Set<String>();
    public Integer recLimit = 0;
    public Integer limitBatch = 0;
    
    //Record Ids that had an error on processing. Unchecking these on the finish would prevent them from being re-executed.
    //HOWEVER, leaving them marked would leave the Batch in an infinite loop.
    //This set is to not update them but also not bring them again for processing
    public Set<Id> errorRecords = new Set<Id>();
    
    public Set<Id> procRecords = new Set<Id>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //Integer recLimit = 1;
        
        if( running4CV ){
            //Logic is being ran for changing Content Versions
            
            //Get library Ids
            Set<Id> libIds = ContentVersion_Methods.getLibrarieIds();
            
            //Retrieve CV that are marked as changed
            Set<Id> contentDocumentIds = new Set<Id>();
            String cvQuery = 'SELECT ' + ContentVersion_Methods.cvFields + ' FROM ContentVersion WHERE IsLatest = true AND Update_Content_Permission__c = true AND ContentDocument.ParentId IN :libIds ';
            
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
                cvQuery += ' LIMIT :recLimit';
            }
            
            for( ContentVersion cv : Database.query( cvQuery ) ){
                contentDocumentIds.add( cv.ContentDocumentId );
                cvByContDocId.put( cv.ContentDocumentId, cv );
                
                //To unFlag the ContentVersion at the finish
                sObj2UnFlag.add(cv.Id);
            }
            system.debug( 'contentDocumentIds: ' + contentDocumentIds );
            if( !contentDocumentIds.isEmpty() ){
                //Assumption: There will be only 1 ContentDocumentLink per ContentDocument, which means that the ContentDocument is only in 1 Collaboration Group and not many.
                for( ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocumentIds ] ){
                    if( cdl.LinkedEntityId.getSObjectType() == CollaborationGroup.sObjectType  ){
                        collaborationGroupIds.add( cdl.LinkedEntityId );
                        
                        contDocByCollabGroup.put( cdl.LinkedEntityId, cdl.ContentDocumentId );
                    }
                }
            }
            query += ' CollaborationGroupId IN :collaborationGroupIds';
        }else{
            //Logic is being ran for changing Contact
            
            String conQuery = 'SELECT Id FROM Contact WHERE Update_Contact_Permission__c = true ';
            
            if( !errorRecords.isEmpty() ){
                conQuery += ' AND Id NOT IN :errorRecords ';
            }
            
            if( !procRecords.isEmpty() ){
                conQuery += ' AND Id NOT IN :procRecords ';
            }
            
            if( recLimit > 0 ){
                conQuery += ' LIMIT :recLimit';
            }
            
            for( Contact con : Database.query( conQuery ) ){
                contactIds.add(con.Id);
                
                sObj2UnFlag.add(con.Id);
            }
            
            query += ' Member.ContactId IN :contactIds ';
            
            if( !errorRecords.isEmpty() ){
                query += ' AND Member.ContactId NOT IN :errorRecords ';
            }
            
            if( !procRecords.isEmpty() ){
                query += ' AND Member.ContactId NOT IN :procRecords ';
            }
        }
        
        if( !restrictCGMIds.isEmpty() ){
            query += ' AND Id IN :restrictCGMIds';
        }
        
        //Add that it does not remove membership for Service Wise User
        if( !test.isRunningTest() ){
        	query += ' AND MemberId != \'' + ContentVersion_Methods.userServiceWise + '\'';
        }
        
        system.debug(System.LoggingLevel.ERROR,'sObj2UnFlag: ' + sObj2UnFlag);
        system.debug(System.LoggingLevel.ERROR,'query: ' + query);
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, list<Sobject> scope) {
        Savepoint sp = Database.setSavepoint();
        List<HD_Log__c> hdLogs2Ins = new List<HD_Log__c>();
        
        try{
            system.debug(System.LoggingLevel.ERROR,'running4CV: ' + running4CV);
            if( !running4CV ){
                //Logic is being ran for changing Contact
                
                //Since running logic from the Contact, we don't have data from the Content Version
                //So we get it and build the map just as it would when runngin for Content Version
                //That way we do not change the validation logic
                
                Set<Id> collaborationGroupIds = new Set<Id>();
                
                for( CollaborationGroupMember cgm : (List<CollaborationGroupMember>) scope ){
                    //To unFlag the Contact at the finish
                    if( cgm.Member.ContactId != null ){
                        sObj2UnFlag.add( cgm.Member.ContactId );
                        
                        collaborationGroupIds.add(cgm.CollaborationGroupId);
                    }
                }
                
                Set<Id> contentDocumentIds = new Set<Id>();
                
                for( ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :collaborationGroupIds ] ){
                    contDocByCollabGroup.put( cdl.LinkedEntityId, cdl.ContentDocumentId );
                    contentDocumentIds.add(cdl.ContentDocumentId);
                }
                
                //Get library Ids
                Set<Id> libIds = ContentVersion_Methods.getLibrarieIds();
                
                //for( ContentDocument cd : [SELECT Id, (SELECT Id, Owner.ContactId, ContentDocumentId, Entity_Type__c, Program_Type__c, Specific_Program__c, Country__c FROM ContentVersions ORDER BY CreatedDate desc LIMIT 1) FROM ContentDocument WHERE Id IN :contentDocumentIds AND ParentId IN :libIds ] ){
                for( ContentDocument cd : database.query( 'SELECT Id, ( SELECT ' + ContentVersion_Methods.cvFields + ' FROM ContentVersions WHERE IsLatest = true ORDER BY CreatedDate desc LIMIT 1 ) FROM ContentDocument WHERE Id IN :contentDocumentIds AND ParentId IN :libIds ' ) ){
                    if( !cd.ContentVersions.isEmpty() ){
                        cvByContDocId.put( cd.Id, cd.ContentVersions[0] );
                    }
                }
            }
            
            
            List<CollaborationGroupMember> cgm2Del = new List<CollaborationGroupMember>();
            
            for( CollaborationGroupMember cgm : (List<CollaborationGroupMember>) scope ){
                if( running4CV ){
                    //Logic is being ran for changing Content Versions
                    procRecords.add( cvByContDocId.get( contDocByCollabGroup.get( cgm.CollaborationGroupId ) ).Id );
                }else{
                    //Logic is being ran for changing Contact
                    procRecords.add( cgm.Member.ContactId );
                }
                
                //Checking key just in case
                if( cgm.Member.ContactId != null && contDocByCollabGroup.containsKey( cgm.CollaborationGroupId ) && cvByContDocId.containsKey( contDocByCollabGroup.get( cgm.CollaborationGroupId ) ) ){
                    //Get the ContentVersion
                    ContentVersion cv = cvByContDocId.get( contDocByCollabGroup.get( cgm.CollaborationGroupId ) );
                    
                    //Set values to a temp Contact for ease of access
                    Contact con = new Contact( Id = cgm.Member.ContactId, Entity_Type__c = cgm.Member.Contact.Entity_Type__c, Program_Type__c = cgm.Member.Contact.Program_Type__c, Specific_Program__c = cgm.Member.Contact.Specific_Program__c, MailingCountry = cgm.Member.Contact.MailingCountry );
                    
                    Boolean canSee = ContentVersion_Methods.canSee(con, cv);
                    
                    system.debug(System.LoggingLevel.ERROR,'cv: ' + cv);
                    system.debug(System.LoggingLevel.ERROR,'con: ' + con);
                    system.debug(System.LoggingLevel.ERROR,'canSee: ' + canSee);
                    
                    if( canSee ){
                        //It is a match. Do nothing
                    }else{
                        //It is not a match. Mark this relation for deletion
                        cgm2Del.add( cgm );
                    }
                }
            }
            
            system.debug(System.LoggingLevel.ERROR,'cgm2Del: ' + cgm2Del);
            
            if( !cgm2Del.isEmpty() ){
                delete cgm2Del;
            }
        }catch(Exception e){
            Database.rollback(sp);
            
            GlobalHelperMethods.debugErrorMsg(e);
            
            for( CollaborationGroupMember cgm : (List<CollaborationGroupMember>) scope ){
                if( running4CV ){
                    //Logic is being ran for changing Content Versions
                    errorRecords.add( cvByContDocId.get( contDocByCollabGroup.get( cgm.CollaborationGroupId ) ).Id );
                }else{
                    //Logic is being ran for changing Contact
                    errorRecords.add( cgm.Member.ContactId );
                }
                
                hdLogs2Ins.add( new HD_Log__c( Contact__c = cgm.Member.ContactId, Error_Description__c = GlobalHelperMethods.ImproveErrorMessage(e), Status__c = 'Fail', Process_Name__c = 'Batch_CFM_Membership[running4CV='+String.valueOf(running4CV)+']' ) );
            }
        }
        
        if( !hdLogs2Ins.isEmpty() ){
            insert hdLogs2Ins;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        /*
        List<sObject> sObj2Upd = new List<sObject>();
        system.debug(System.LoggingLevel.ERROR,'sObj2UnFlag: ' + sObj2UnFlag);
        for( Id sObjId : sObj2UnFlag ){
            if( !errorRecords.contains(sObjId) ){
                if( running4CV ){
                    //Logic is being ran for changing Content Version
                    sObj2Upd.add( new ContentVersion(Id = sObjId, Update_Content_Permission__c = false) );
                }else{
                    //Logic is being ran for changing Contact
                    sObj2Upd.add( new Contact(Id = sObjId, Update_Contact_Permission__c = false) );
                }
            }
        }
        
        system.debug(System.LoggingLevel.ERROR,'sObj2Upd: ' + sObj2Upd);
        
        //update sObj2Upd;
        
        List<Database.SaveResult> slr = Database.update(sObj2Upd,false);
        List<HD_Log__c> hdLogs2Ins = new List<HD_Log__c>();
        
        for(Integer i = 0; i < slr.size(); i++){
            Database.SaveResult sr = slr.get(i);
            if(!sr.isSuccess()){
                errorRecords.add(sObj2Upd[i].Id);
                
                Id conId = sObj2Upd[i].Id;
                if( running4CV ){
                    conId = null;
                    if( cvByContDocId.containsKey( sObj2Upd[i].Id ) ){
                        conId = cvByContDocId.get( sObj2Upd[i].Id ).Owner.ContactId;
                    }
                }
                hdLogs2Ins.add( new HD_Log__c( Contact__c = conId, Error_Description__c = sr.getErrors()[0].getMessage(), Status__c = 'Fail', Process_Name__c = 'Batch_CFM_Membership' ) );
            }
        }
        
        if( !hdLogs2Ins.isEmpty() ){
            insert hdLogs2Ins;
            system.debug(System.LoggingLevel.ERROR,'hdLogs2Ins:' + hdLogs2Ins);
        }
        */
        
        procRecords.addAll(sObj2UnFlag);
        
        //Get library Ids
        Set<Id> libIds = ContentVersion_Methods.getLibrarieIds();
        
        //Check if there are still Records to process
        String moreRecordsQuery = 'SELECT Id FROM Contact WHERE Update_Contact_Permission__c = true AND Id NOT IN :errorRecords AND Id NOT IN :procRecords LIMIT 1';
        if( running4CV ){
            //Logic is being ran for changing Content Version
            moreRecordsQuery = 'SELECT Id FROM ContentVersion WHERE IsLatest = true AND Update_Content_Permission__c = true AND ContentDocument.ParentId IN :libIds AND Id NOT IN :errorRecords AND Id NOT IN :procRecords AND Id IN :restrictCVIds LIMIT 1';
        }
        List<sObject> mr = Database.query( moreRecordsQuery );
        
        Boolean moreRecords = mr.size() > 0 ;
        system.debug( 'mr: ' + mr );
        
        ContinueNextExecution( moreRecords );
    }
    
    public void ContinueNextExecution( Boolean moreRecords ){
        if( moreRecords ){
            //Rerun this batch with the same config if there are more records to be processed
            Batch_CFM_Membership batch = new Batch_CFM_Membership();
            batch.running4CV = running4CV;
            batch.procRecords = procRecords;
            batch.errorRecords = errorRecords;
            batch.restrictCVIds = restrictCVIds;
            batch.restrictCGMIds = restrictCGMIds;
            batch.recLimit = recLimit;
            batch.step = step;
            batch.limitBatch = limitBatch;
            
            if( !test.isRunningTest() ){
                //database.executeBatch(batch);
                Batch_CFM_Membership.RunBatch(batch, limitBatch);
            }
        }else if( step == 0 ){
            //After running this batch, reRun it but for the oposite of running4CV and increase step in 1.
            Batch_CFM_Membership batch = new Batch_CFM_Membership();
            batch.running4CV = !running4CV;
            batch.restrictCVIds = restrictCVIds;
            batch.restrictCGMIds = restrictCGMIds;
            batch.recLimit = recLimit;
            batch.step = step+1;
            batch.errorRecords = errorRecords;
            batch.limitBatch = limitBatch;
            
            if( !test.isRunningTest() ){
                //database.executeBatch(batch);
                Batch_CFM_Membership.RunBatch(batch, limitBatch);
            }
        }else if( step == 1 ){
            //Both logics have been run for this batch (for Contacts and for Content Version)
            //Now we leave running the other 2 batchs
            
            //FOR NOW WE RUN THEM AS IS, NO SETTINGS ARE CARRIED
            Batch_CFM_Contacts batch1 = new Batch_CFM_Contacts();
            batch1.errorRecords = errorRecords;
            batch1.recLimit = recLimit;
            batch1.limitBatch = limitBatch;
            
            if( !test.isRunningTest() ){
            	//database.executeBatch(batch1);
            	Batch_CFM_Contacts.RunBatch(batch1, limitBatch);
            }
            
            Batch_CFM_Users batch2 = new Batch_CFM_Users();
            batch2.errorRecords = errorRecords;
            batch2.recLimit = recLimit;
            batch2.limitBatch = limitBatch;
            
            if( !test.isRunningTest() ){
                //database.executeBatch(batch2);
                Batch_CFM_Users.RunBatch(batch2, limitBatch);
            }
        }
    }
    
    public static void RunBatch( Batch_CFM_Membership batch, Integer limitBatch ){
		batch.limitBatch = limitBatch;
		database.executeBatch( batch, limitBatch );
	}
	
    /*
    public static Boolean canSee( Contact con, ContentVersion cv){
        //Return TRUE : It is a Match
        
        Boolean containsEntityType = false;
        Boolean containsProgramType = false;
        Boolean containsSpecificProgram = false;
        Boolean containsCountry = false;
        Boolean isOwner = false;
        
        Set<String> entityTypesSet = new Set<String>(con.Entity_Type__c.split(';'));
        Set<String> programTypesSet = new Set<String>(con.Program_Type__c.split(';'));
        Set<String> specificProgramsSet = new Set<String>(con.Specific_Program__c.split(';'));
        Set<String> mailingCoutriesSet = new Set<String>(con.MailingCountry.split(';'));
        
        for( String et : cv.Entity_Type__c.split(';') ){
            if( entityTypesSet.contains(et) ){
                containsEntityType = true;
                break;
            }
        }
        
        for( String et : cv.Program_Type__c.split(';') ){
            if( programTypesSet.contains(et) ){
                containsProgramType = true;
                break;
            }
        }
        
        for( String et : cv.Specific_Program__c.split(';') ){
            if( specificProgramsSet.contains(et) ){
                containsSpecificProgram = true;
                break;
            }
        }
        
        for( String et : cv.Country__c.split(';') ){
            if( mailingCoutriesSet.contains(et) ){
                containsCountry = true;
                break;
            }
        }
        system.debug(System.LoggingLevel.ERROR,'cv.Owner.ContactId: ' + cv.Owner.ContactId);
        system.debug(System.LoggingLevel.ERROR,'con.Id: ' + con.Id);
        
        if( cv.Owner.ContactId == con.Id ){
            //Its the owner of the Content Version, for now do not remove him
            isOwner = true;
        }
        
        return isOwner || (containsEntityType && containsProgramType && containsSpecificProgram && containsCountry);
    }
    
    private static Set<Id> librarieIds;
    public static Set<Id> getLibrarieIds(){
        if( librarieIds == null ){
            librarieIds = new Set<Id>();
            
            Set<String> libraryNames = new Set<String>{'Business', 'Pedagogic', 'Seminars/Workshops'};
            
            for( HD_Settings_List__c cs :[SELECT Value__c FROM HD_Settings_List__c WHERE Name = 'Content Libraries List' LIMIT 1] ){
                libraryNames.addAll( cs.Value__c.split(',') );
            }
            
            for( ContentWorkspace cw : [SELECT Id FROM ContentWorkspace WHERE Name IN :libraryNames ] ){
                librarieIds.add(cw.Id);
            }
        }
        return librarieIds;
    }
    */
}