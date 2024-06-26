public class ContentVersion_Methods {
	private static Id hdCommunityId_private;
	public static Id hdCommunityId{
		get{
            try{
                if( hdCommunityId_private == null ){
                   hdCommunityId_private = [SELECT Id, Value__c FROM HD_Settings_List__c WHERE Name = 'HD Community ID' LIMIT 1][0].Value__c;
                } 
            }catch(Exception ex){
                System.debug(System.LoggingLevel.ERROR,' Error ' + ex.getMessage() + ' trace ' + ex.getStackTraceString());
            }

			return hdCommunityId_private;
		}
	}
    
    private static Id userServiceWise_private;
    public static Id userServiceWise{
        get{
            if( userServiceWise_private == null ){
                userServiceWise_private = [SELECT Id FROM User WHERE Name = 'Service Wise' LIMIT 1][0].Id;
            }
            return userServiceWise_private;
        }
    }
    
    public static String cvFields = ' Id, HDC_File__c, NetworkId, Title, OwnerId, Owner.ContactId, Status__c, Update_Content_Permission__c, ContentDocumentId, Entity_Type__c, Program_Type__c, Country__c, Specific_Program__c ';
    
    public class CFM_Result{
        public ContentVersion contentVersion;
        public CollaborationGroup colaborationGroup;
        public Boolean success;
        public String resultMsg;
        
        public CFM_Result( ContentVersion contentVersion, Boolean success, String resultMsg ){
            this.contentVersion = contentVersion;
            this.success = success;
            this.resultMsg = resultMsg;
        }
        
        public CFM_Result( ContentVersion contentVersion, Boolean success, String resultMsg, CollaborationGroup colaborationGroup ){
            this.contentVersion = contentVersion;
            this.success = success;
            this.resultMsg = resultMsg;
            this.colaborationGroup = colaborationGroup;
        }
    }
    
    public static Boolean validForNewChatterGroup( ContentVersion cv ){
        Boolean condition = String.isNotBlank(cv.Entity_Type__c) && String.isNotBlank(cv.Program_Type__c) && String.isNotBlank(cv.Country__c) && String.isNotBlank(cv.Specific_Program__c);
        condition &= String.isNotBlank( cv.Status__c ) && cv.Status__c.equalsIgnoreCase('Active');
        
        condition &= cv.NetworkId == ContentVersion_Methods.hdCommunityId;
        
        if( cv.Id != null ){
            condition &= !MonitorRecursionClass.contentFileToChatterGroup_Ids.contains( cv.Id );
        }
        return condition;
    }
    
    public static List<CFM_Result> createNewChatterGroup( List<ContentDocument> cdList ){
        Set<Id> cdIds = new Set<Id>();
        for( Integer i=0; i < cdList.size(); i++ ){
            cdIds.add( cdList[i].Id );
        }
        
        List<ContentVersion> cvList = new List<ContentVersion>();
        
        for( ContentVersion cv : (List<ContentVersion>)database.query('SELECT ' + cvFields + ' FROM ContentVersion WHERE ContentDocumentId IN : cdIds AND IsLatest = true') ){
            cvList.add( cv );
        }
        
        return createNewChatterGroup( cvList );
    }
    
    public static List<CFM_Result> createNewChatterGroup( List<ContentVersion> cvList ){
        //This logic will try to create the new Chatter Group for the ContentVersions
        //It returns a List of CFM_Result.
        //Only returns those that Succeded or Failed due to an error. The ones that didn't qualify won't be returned.
        
        List<CFM_Result> operationResult = new List<CFM_Result>();
        Id hdCommId = ContentVersion_Methods.hdCommunityId;//[SELECT Id, Value__c FROM HD_Settings_List__c WHERE Name = 'HD Community ID' LIMIT 1][0].Value__c;
        Map<Integer, CollaborationGroup> cg2InsByIndex = new Map<Integer, CollaborationGroup>();
        Map<Id, Integer> cv2checkCG = new Map<Id, Integer>();
        
        for( Integer i=0; i < cvList.size(); i++ ){
            ContentVersion cv = cvList[i];
            if( validForNewChatterGroup( cv ) ){
                CollaborationGroup cg = new CollaborationGroup();
                cg.Name = cv.ContentDocumentId;
                /*if( cg.Name.length() > 40 ){
                    cg.Name = cg.Name.substring(0,40);
                }*/
                //cg.IsArchived = true;
                cg.IsBroadcast = true;
                cg.NetworkId = hdCommId;
                cg.CollaborationType = 'Private';
                
                cg2InsByIndex.put(i, cg);
                
                cv2checkCG.put( cv.ContentDocumentId, i );
            }else if( cv.NetworkId != ContentVersion_Methods.hdCommunityId && cv.HDC_File__c ){
            	//Creating a File that is marked for HDC Community, but it is not being created by a logged in Community User.
            	operationResult.add(new CFM_Result( cv , false, Label.Content_Not_in_HDC ));
            }
        }
        
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
            
            //insert cg2InsByIndex.values();
            List<CollaborationGroup> cgList = cg2InsByIndex.values();
            
            List<Database.SaveResult> slr = Database.insert(cgList,false);
            for(Integer i = 0; i < slr.size(); i++){
                Database.SaveResult sr = slr.get(i);
                if(!sr.isSuccess()){
                    //Process failed to create the Collaboration Group.
                    //Remove it from the Map and also prepare a OpResult.
                    CollaborationGroup cg = cgList[i];
                    
                    for( Integer j : cg2InsByIndex.keySet() ){
                        if( cg2InsByIndex.get(j) == cg ){
                            operationResult.add(new CFM_Result( cvList[j] , false, sr.getErrors()[0].getMessage() ));
                            cg2InsByIndex.remove(j);
                            break;
                        }
                    }
                }
            }
            
            List<ContentDocumentLink> cdl2Ins = new List<ContentDocumentLink>();
            
            for( Integer i : cg2InsByIndex.keySet() ){
                
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = String.valueOf( cvList[i].ContentDocumentId );
                cdl.LinkedEntityId = cg2InsByIndex.get(i).Id;
                cdl.ShareType = 'V';
                
                cdl2Ins.add( cdl );
                
                MonitorRecursionClass.contentFileToChatterGroup_Ids.add( cvList[i].Id );
            }
            
            if( !cdl2Ins.isEmpty() ){
                insert cdl2Ins;
            }
            
            for( CollaborationGroup cg : cg2InsByIndex.values() ){
                cg.IsArchived = true;
            }
            update cg2InsByIndex.values();
            
            for( Integer i : cg2InsByIndex.keySet() ){
                //Process finished. Add all the ones processed to have an OpResult of success
                operationResult.add(new CFM_Result( cvList[i], true, '', cg2InsByIndex.get(i) ));
            }
        }
        
        return operationResult;
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
            
            if( test.isRunningTest() ){
            	librarieIds.add(null);
            }
        }
        return librarieIds;
    }
    
    public static Map<Id, Map<String, Set<String>>> contactsComparisonValues = new Map<Id, Map<String, Set<String>>>();
    public static Map<Id, Map<String, Set<String>>> contentVersionComparisonValues = new Map<Id, Map<String, Set<String>>>();
    
    public static Boolean canSee( Contact con, ContentVersion cv){
        //Return TRUE : It is a Match
        
        if( con.Entity_Type__c == null || con.Program_Type__c == null || con.Specific_Program__c == null || con.MailingCountry == null
                    || cv.Entity_Type__c == null || cv.Program_Type__c == null || cv.Specific_Program__c == null || cv.Country__c == null ){
            //If any of those fields is null, no proper comparison can be made, so return false.
            return false;
        }
        
        system.debug('cv.Owner.ContactId: ' + cv.Owner.ContactId);
        system.debug('con.Id: ' + con.Id);
        
        Boolean isOwner = false;
        
        if( cv.Owner.ContactId == con.Id ){
            //Its the owner of the Content Version, for now do not remove him
            isOwner = true;
            //Speed up
            return true;
        }
        
        Boolean isActive = false;
        
        if( cv.Status__c == 'Active' ){
            isActive = true;
        }
        
        if( !isActive ){
            //Speed up
            return false;
        }
        
        //Contact cache mapping
        if( !contactsComparisonValues.containsKey( con.Id ) ){
            contactsComparisonValues.put( con.Id, new Map<String, Set<String>>() );
        }
        //CV cache mapping
        if( !contentVersionComparisonValues.containsKey( cv.Id ) ){
            contentVersionComparisonValues.put( cv.Id, new Map<String, Set<String>>() );
        }
        
        /*
            Entity_Type__c
        */
        
        if( !contactsComparisonValues.get( con.Id ).containsKey('Entity_Type__c') ){
            contactsComparisonValues.get( con.Id ).put( 'Entity_Type__c', new Set<String>() );
            contactsComparisonValues.get( con.Id ).get( 'Entity_Type__c' ).addAll(con.Entity_Type__c.split(';'));
        }
        
        if( !contentVersionComparisonValues.get( cv.Id ).containsKey('Entity_Type__c') ){
            contentVersionComparisonValues.get( cv.Id ).put( 'Entity_Type__c', new Set<String>() );
            contentVersionComparisonValues.get( cv.Id ).get( 'Entity_Type__c' ).addAll( cv.Entity_Type__c.split(';') );
        }
        
        Set<String> conSet = contactsComparisonValues.get( con.Id ).get( 'Entity_Type__c' );
        Set<String> cvSet = contentVersionComparisonValues.get( cv.Id ).get( 'Entity_Type__c' );
        
        Integer conSize = conSet.size();
        Integer cvSize = cvSet.size();
        
        Set<String> resultSet = new Set<String>();
        resultSet.addAll( conSet );
        resultSet.addAll( cvSet );
        
        Boolean containsEntityType = false;
        
        if( resultSet.size() < conSize + cvSize ){
            containsEntityType = true;
        }
        
        /*
        Set<String> entityTypesSet = new Set<String>(con.Entity_Type__c.split(';'));
        for( String et : cv.Entity_Type__c.split(';') ){
            if( entityTypesSet.contains(et) ){
                containsEntityType = true;
                break;
            }
        }
        */
        
        if( !containsEntityType ){
            //Speed up
            return false;
        }
        
        
        /*
            Program_Type__c
        */
        
        if( !contactsComparisonValues.get( con.Id ).containsKey('Program_Type__c') ){
            contactsComparisonValues.get( con.Id ).put( 'Program_Type__c', new Set<String>() );
            contactsComparisonValues.get( con.Id ).get( 'Program_Type__c' ).addAll(con.Program_Type__c.split(';'));
        }
        
        if( !contentVersionComparisonValues.get( cv.Id ).containsKey('Program_Type__c') ){
            contentVersionComparisonValues.get( cv.Id ).put( 'Program_Type__c', new Set<String>() );
            contentVersionComparisonValues.get( cv.Id ).get( 'Program_Type__c' ).addAll( cv.Program_Type__c.split(';') );
        }
        
        conSet = contactsComparisonValues.get( con.Id ).get( 'Program_Type__c' );
        cvSet = contentVersionComparisonValues.get( cv.Id ).get( 'Program_Type__c' );
        
        conSize = conSet.size();
        cvSize = cvSet.size();
        
        resultSet = new Set<String>();
        resultSet.addAll( conSet );
        resultSet.addAll( cvSet );
        
        Boolean containsProgramType = false;
        
        if( resultSet.size() < conSize + cvSize ){
            containsProgramType = true;
        }
        
        /*
        Set<String> programTypesSet = new Set<String>(con.Program_Type__c.split(';'));
        for( String et : cv.Program_Type__c.split(';') ){
            if( programTypesSet.contains(et) ){
                containsProgramType = true;
                break;
            }
        }
        */
        
        if( !containsProgramType ){
            //Speed up
            return false;
        }
        
        
        /*
            Specific_Program__c
        */
        
        if( !contactsComparisonValues.get( con.Id ).containsKey('Specific_Program__c') ){
            contactsComparisonValues.get( con.Id ).put( 'Specific_Program__c', new Set<String>() );
            contactsComparisonValues.get( con.Id ).get( 'Specific_Program__c' ).addAll(con.Specific_Program__c.split(';'));
        }
        
        if( !contentVersionComparisonValues.get( cv.Id ).containsKey('Specific_Program__c') ){
            contentVersionComparisonValues.get( cv.Id ).put( 'Specific_Program__c', new Set<String>() );
            contentVersionComparisonValues.get( cv.Id ).get( 'Specific_Program__c' ).addAll( cv.Specific_Program__c.split(';') );
        }
        
        conSet = contactsComparisonValues.get( con.Id ).get( 'Specific_Program__c' );
        cvSet = contentVersionComparisonValues.get( cv.Id ).get( 'Specific_Program__c' );
        
        conSize = conSet.size();
        cvSize = cvSet.size();
        
        resultSet = new Set<String>();
        resultSet.addAll( conSet );
        resultSet.addAll( cvSet );
        
        Boolean containsSpecificProgram = false;
        
        if( resultSet.size() < conSize + cvSize ){
            containsSpecificProgram = true;
        }
        
        /*
        Set<String> specificProgramsSet = new Set<String>(con.Specific_Program__c.split(';'));
        for( String et : cv.Specific_Program__c.split(';') ){
            if( specificProgramsSet.contains(et) ){
                containsSpecificProgram = true;
                break;
            }
        }
        */
        
        if( !containsSpecificProgram ){
            //Speed up
            return false;
        }
        
        
        /*
            MailingCountry / Country__c
        */
        
        if( !contactsComparisonValues.get( con.Id ).containsKey('MailingCountry') ){
            contactsComparisonValues.get( con.Id ).put( 'MailingCountry', new Set<String>() );
            contactsComparisonValues.get( con.Id ).get( 'MailingCountry' ).addAll(con.MailingCountry.split(';'));
        }
        
        if( !contentVersionComparisonValues.get( cv.Id ).containsKey('Country__c') ){
            contentVersionComparisonValues.get( cv.Id ).put( 'Country__c', new Set<String>() );
            contentVersionComparisonValues.get( cv.Id ).get( 'Country__c' ).addAll( cv.Country__c.split(';') );
        }
        
        conSet = contactsComparisonValues.get( con.Id ).get( 'MailingCountry' );
        cvSet = contentVersionComparisonValues.get( cv.Id ).get( 'Country__c' );
        
        conSize = conSet.size();
        cvSize = cvSet.size();
        
        resultSet = new Set<String>();
        resultSet.addAll( conSet );
        resultSet.addAll( cvSet );
        
        Boolean containsCountry = false;
        
        if( resultSet.size() < conSize + cvSize ){
            containsCountry = true;
        }
        
        /*
        Set<String> mailingCoutriesSet = new Set<String>(con.MailingCountry.split(';'));
        for( String et : cv.Country__c.split(';') ){
            if( mailingCoutriesSet.contains(et) ){
                containsCountry = true;
                break;
            }
        }
        */
        
        if( !containsCountry ){
            //Speed up
            return false;
        }
        
        //This is an example of how the comparison for returning should work
        //In order to speed up the process, the logic can return earlier
        return isOwner || (containsEntityType && containsProgramType && containsSpecificProgram && containsCountry && isActive);
    }
    
    public static List<CFM_Result> deleteCollaborationGroups( List<ContentDocument> cdList ){
        List<CFM_Result> operationResult = new List<CFM_Result>();
        List<CollaborationGroup> cg2Del = new List<CollaborationGroup>();
        Map<Integer, ContentDocument > cdByIndex = new Map<Integer, ContentDocument>();
        
        Map<Id, ContentDocument> cdByCdId = new Map<Id, ContentDocument>();
        for( ContentDocument cd : cdList ){
            cdByCdId.put( cd.Id, cd );
        }
        
        Set<Id> cdIds = cdByCdId.keySet();
        
        for( ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIds ] ){
            if( cdl.LinkedEntityId.getSObjectType() == CollaborationGroup.sObjectType ){
                cdByIndex.put( cg2Del.size(), cdByCdId.get( cdl.ContentDocumentId ) );
                cg2Del.add( new CollaborationGroup(Id = cdl.LinkedEntityId ) );
            }
        }
        
        if( !cg2Del.isEmpty() ){
            List<database.Deleteresult> drs = database.delete( cg2Del, false );
            
            for( Integer i = 0; i < drs.size(); i++){
                database.Deleteresult dr = drs[i];
                if( !dr.isSuccess() ){
                    //operationResult.add( new CFM_Result( cdByIndex.get(i) , false, dr.getErrors()[0].getMessage() ) );
                }
            }
        }
        return operationResult;
    }
    
    
    /******************************************************************************* 
    Name              : ContentVersion_TriggerHandler
    Description       : Handler the before/after trigger on Content Version
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Sergio Caputo            10/01/2017              Ella                    SW-23163
    *******************************************************************************/
    
    public static void cloneContentVersionToCommunity( List<ContentVersion> scope ){
        
        //Get library Ids
        Set<Id> libIds = ContentVersion_Methods.getLibrarieIds();
        // Just we consider the specific libraries...
                    
        Set<Id> cvIds = new Set<Id>();
        String query = 'SELECT c.VersionNumber, c.VersionData, c.Update_Content_Permission__c, c.Title, c.TagCsv, c.SystemModstamp, c.Status__c, c.Specific_Program__c, c.ReasonForChange, c.RatingCount, c.PublishStatus, c.Program_Type__c, c.PositiveRatingCount, c.PathOnClient, c.OwnerId, c.Origin, c.NetworkId, c.NegativeRatingCount, c.Library_Name__c, c.Last_Update_Date__c, c.LastModifiedDate, c.LastModifiedById, c.Language, c.IsLatest, c.IsDeleted, c.Id, c.FirstPublishLocationId, c.File_URL__c, c.FileType, c.FeaturedContentDate, c.FeaturedContentBoost, c.Entity_Type__c, c.Description, c.CurrencyIsoCode, c.CreatedDate, c.CreatedById, c.Country__c, c.Content_Old_Id__c, c.ContentUrl, c.ContentSize, c.ContentModifiedDate, c.ContentModifiedById, c.ContentDocumentId, c.Checksum, c.Base_Course__c FROM ContentVersion c WHERE Id IN :cvIds ';
        
        if(Test.isRunningTest()){
            query += ' ORDER BY CreatedDate desc';
        }else{
            query += ' AND ContentDocument.ParentId IN: libIds ORDER BY CreatedDate desc'; 
        }       
        
        for( ContentVersion cv : scope ){
            cvIds.add(cv.Id);
        }
        
        List<ContentVersion> cv2Ins = new List<ContentVersion>();
        Map<Id, ContentVersion> cloneByCD = new Map<Id, ContentVersion>();
        Set<Id> contentDocumentIds = new Set<Id>();
        
        Id hdCommId = ContentVersion_Methods.hdCommunityId;//[SELECT Id, Value__c FROM HD_Settings_List__c WHERE Name = 'HD Community ID' LIMIT 1][0].Value__c;
        
        for( ContentVersion cv : database.query(query) ){
            if( !contentDocumentIds.contains( cv.ContentDocumentId ) ){
                //Create clones
                
                ContentVersion cv2 = cv.clone(false, true, false, false);
                cv2.ContentDocumentId = null;
                cv2.NetworkId = hdCommId;
                cv2.Created_By_Clone__c = true;
                
                cv2Ins.add(cv2);
                cloneByCD.put( cv.ContentDocumentId, cv2 );
                
                contentDocumentIds.add( cv.ContentDocumentId );
            }
        }
        
        if( !cv2Ins.isEmpty() ){
            
            for( ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocumentIds ] ){
                if( cdl.LinkedEntityId.getSObjectType() == ContentWorkspace.sObjectType ){
                    cloneByCD.get( cdl.ContentDocumentId ).FirstPublishLocationId = cdl.LinkedEntityId;
                }
            }
            insert cv2Ins;
        }
    }
    
}

/* 12/01/2017
    public static Boolean canSee( Contact con, ContentVersion cv){
        //Return TRUE : It is a Match
        
        if( con.Entity_Type__c == null || con.Program_Type__c == null || con.Specific_Program__c == null || con.MailingCountry == null
                    || cv.Entity_Type__c == null || cv.Program_Type__c == null || cv.Specific_Program__c == null || cv.Country__c == null ){
            //If any of those fields is null, no proper comparison can be made, so return false.
            return false;
        }
        
        Boolean containsEntityType = false;
        Boolean containsProgramType = false;
        Boolean containsSpecificProgram = false;
        Boolean containsCountry = false;
        Boolean isActive = false;
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
        system.debug('cv.Owner.ContactId: ' + cv.Owner.ContactId);
        system.debug('con.Id: ' + con.Id);
        
        if( cv.Owner.ContactId == con.Id ){
            //Its the owner of the Content Version, for now do not remove him
            isOwner = true;
        }
        
        if( cv.Status__c == 'Active' ){
            isActive = true;
        }
        
        return isOwner || (containsEntityType && containsProgramType && containsSpecificProgram && containsCountry && isActive);
    }
*/