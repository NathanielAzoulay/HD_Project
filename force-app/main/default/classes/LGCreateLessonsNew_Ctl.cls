public class LGCreateLessonsNew_Ctl {

    public class MyException extends Exception {}

    public Boolean updateEndPayingDate {get;set;}
    
    public String showError {get; set;}
    public Boolean showForm {get; set;}  // From Issue "SW-18001" when is true, we should Open window to request for Start Date (Please Enter Starting Date: ________).
    public Boolean showTypeOfCreationLGLessons {get; set;}
    public Boolean showDone {get; set;}
    public LG__c currentLG   {get; set;}
    public Date selectedDate{get; set;}
    
    private Decimal originalLGLessonsNro;
    private Date originalLGEndDate;
    private String originalCreateLGLessonBy;
      
    public LGCreateLessonsNew_Ctl(Id recordId) {
        System.debug('in LGCreateLessonsNew_Ctl '+recordId);
        updateEndPayingDate = false;
        showTypeOfCreationLGLessons = false;
        
        currentLG = [SELECT Id, Name, LG_Type__c, LG_Lessons__c, Price_per_Month__c, Recommended_Lessons__c, Number_of_Lessons__c, Create_LG_Lessons_By__c, LG_Start_Date__c, LG_End_Date__c, 
                            LG_End_Paying_Date__c, Franchisee__c, Franchisee__r.BillingCountry, Franchisee__r.ParentId, 
                            (SELECT LG__c, Day__c, Start_Hour__c, End_Hour__c, Teacher__c FROM LG_Days_Hours__r) 
                     FROM LG__c 
                     WHERE Id =: recordId]; 
        
        originalLGLessonsNro = currentLG.LG_Lessons__c;
        originalLGEndDate  = currentLG.LG_End_Date__c;
        originalCreateLGLessonBy = currentLG.Create_LG_Lessons_By__c;
        showForm = currentLG.Number_of_Lessons__c > 0;
        if(!showForm){
          showTypeOfCreationLGLessons = true; // From Issue "SW-23793" we will diplay the two possible way of create LG Lesson (by start/end date or No. of lessons recommended)
        }
        showDone = false;
    }
    
    public LGCreateLessonsNew_Ctl(ApexPages.StandardController controller) {
        updateEndPayingDate = false;
        showTypeOfCreationLGLessons = false;
        
        currentLG = [SELECT Id, Name, LG_Type__c, LG_Lessons__c, Price_per_Month__c, Recommended_Lessons__c, Number_of_Lessons__c, Create_LG_Lessons_By__c, LG_Start_Date__c, LG_End_Date__c, LG_End_Paying_Date__c, Franchisee__c, Franchisee__r.BillingCountry, Franchisee__r.ParentId, (SELECT LG__c, Day__c, Start_Hour__c, End_Hour__c, Teacher__c FROM LG_Days_Hours__r) FROM LG__c WHERE Id =: controller.getId()]; 
        
        originalLGLessonsNro = currentLG.LG_Lessons__c;
        originalLGEndDate  = currentLG.LG_End_Date__c;
        originalCreateLGLessonBy = currentLG.Create_LG_Lessons_By__c;
        showForm = currentLG.Number_of_Lessons__c > 0;
        if(!showForm){
          showTypeOfCreationLGLessons = true; // From Issue "SW-23793" we will diplay the two possible way of create LG Lesson (by start/end date or No. of lessons recommended)
        }
        showDone = false;
    }
      
    public void doCreateForEndDate(){
        System.debug('in doCreateForEndDate '+currentLG);

        if(string.isBlank(currentLG.Create_LG_Lessons_By__c)){
          currentLG.Create_LG_Lessons_By__c = 'LG End Date';
        }      
        doCreateLGLessons(currentLG.Create_LG_Lessons_By__c);  
    }
      
    public void doCreateForNumOfLessons(){
        if(string.isBlank(currentLG.Create_LG_Lessons_By__c)){
          currentLG.Create_LG_Lessons_By__c = 'Number of Lessons';
        }
        doCreateLGLessons(currentLG.Create_LG_Lessons_By__c);      
    }
      
    public void doCreate(){ // Method call when exist already LG Lessons...the user will select the selectedDate.
        doCreateForEndDate(); // In case that the field was not initializate before we will consider as previous LG Lesson creation (By end date and not the new logic by LG Lesson number )
    }
      
    public void doCreateLGLessons(String createLGLessonsBy){
        
        try{
          
          if(selectedDate <> null && selectedDate > currentLG.LG_End_Date__c){
            throw new MyException('The selected date cannot be greater than \'LG End Date\'');
          }
          
          Boolean needs2UpdateLGLessonsBy = false;
          if(originalCreateLGLessonBy <> currentLG.Create_LG_Lessons_By__c){
            needs2UpdateLGLessonsBy = true;
          }
          
          LG__c lg2Up =  new LG__c(Id = currentLG.Id, Create_LG_Lessons_By__c = currentLG.Create_LG_Lessons_By__c);
          
          Boolean needsChanged_LGEndDate = false; 
          Boolean hasChanged_LGLessonsNro = false;      
          
          LGCreateLessonWithoutBatch b = new LGCreateLessonWithoutBatch();
          if(createLGLessonsBy == 'LG End Date'){
            b.records2process = LGHelperMethods.getAllLessonsDays(currentLG.Id, selectedDate);
          }else{
            
            b.records2process = LGHelperMethods.getAllLessonsDaysByNumberOfLessons(currentLG.Id, currentLG.LG_Lessons__c, selectedDate);
            
            if(b.records2process.size() > 0){
            
              // Get the last lesson date
              Datetime dt = b.records2process[b.records2process.size()-1].Lesson_Date_Hour__c;
              Date lastLessonDate = Date.newInstance(dt.year(), dt.month(), dt.day());
              
              // Check if we should update the LG
              hasChanged_LGLessonsNro = originalLGLessonsNro <> currentLG.LG_Lessons__c;
              needsChanged_LGEndDate = originalLGEndDate <> lastLessonDate;
              
              // Check if we need to update the related LG
              if(needsChanged_LGEndDate || hasChanged_LGLessonsNro || updateEndPayingDate){
                
                lg2Up.Name = currentLG.Name; // Requiere for sending the notification details (check method sendNotifications)...
                lg2Up.LG_End_Date__c = lastLessonDate;
                lg2Up.LG_Lessons__c = currentLG.LG_Lessons__c;
                if(updateEndPayingDate){
                  lg2Up.LG_End_Paying_Date__c = lastLessonDate; // The last Leasson
                }
              }
            }
          }
          
          if(needs2UpdateLGLessonsBy || needsChanged_LGEndDate || hasChanged_LGLessonsNro || updateEndPayingDate){
            
            update lg2Up;
            if(needsChanged_LGEndDate /*&& !needs2UpdateLGLessonsBy*/){ // Create a feed to the current user...
            sendNotifications(new List<LG__c>{lg2Up});
          }
          }
          
          b.doInsert = true;
          b.lgStudents = [SELECT Id, Student_Course_Start_Date__c, Student_Course_End_Date__c, Billing_Type__c, Lesson_Type__c, (Select Planned_Date__c, Planned_Price__c From LG_Payments__r) FROM LG_Student__c WHERE LG__c =: currentLG.Id AND (Status_in_LG__c = 'Registered' OR Status_in_LG__c = 'Signed for Demo')];
          b.processName = 'Batch - Create LG Lessons';
          b.selectedDate = selectedDate;
          if(!b.records2process.isEmpty()){
            b.rollback_key = b.records2process[0].Rollback_Key__c; 
            //Database.executeBatch(b);
            b.doSyncTask(b.records2process);
          } 
          
          showDone = true;
          showForm = false;
          showTypeOfCreationLGLessons = false;
        }catch(MyException ex){    
          showForm = false;
          showError = GlobalHelperMethods.ImproveErrorMessage(ex);
        }catch(Exception ex){  
          showTypeOfCreationLGLessons = false;
          showError = GlobalHelperMethods.ImproveErrorMessage(ex);
        }
      }   
      
      
      // Important this method requiered that all LG records on the parameters has Name and LG_End_Date__c populated.
      public static void sendNotifications(List<LG__c> lgs){
      
      Savepoint sp = Database.setSavepoint();
      
      try{
            
        for(LG__c lg : lgs){    
        
          Id userToMention = UserInfo.getUserId();
          
          ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();      
          messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
          
          ConnectApi.MarkupBeginSegmentInput markupParagraphBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
          markupParagraphBeginSegment.markupType = ConnectApi.MarkupType.Paragraph;
          messageBodyInput.messageSegments.add(markupParagraphBeginSegment);
          
          // Populate chatter the first part of text body 
          ConnectApi.TextSegmentInput textSegmentInputFirstPart = new ConnectApi.TextSegmentInput();          
          textSegmentInputFirstPart.text = 'Dear ';            
          messageBodyInput.messageSegments.add(textSegmentInputFirstPart);
          
          // Add mention 
          ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
          mentionSegmentInput.id = userToMention;
          messageBodyInput.messageSegments.add(mentionSegmentInput);
          
          ConnectApi.MarkupEndSegmentInput markupParagraphEndSegment = new ConnectApi.MarkupEndSegmentInput();
          markupParagraphEndSegment.markupType = ConnectApi.MarkupType.Paragraph;
          messageBodyInput.messageSegments.add(markupParagraphEndSegment);    
                                                                              
          // Populate chatter the last part of text body                   
          ConnectApi.TextSegmentInput textSegmentInputLastPart = new ConnectApi.TextSegmentInput();          
          textSegmentInputLastPart.text = 'Please notice that the end date for the LG "' + lg.Name + '" is updated to "' + lg.LG_End_Date__c.format()+'"';            
          messageBodyInput.messageSegments.add(textSegmentInputLastPart);
          
          // Add the body to the feeditem and assign it to the helper record
          ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
          feedItemInput.body = messageBodyInput;
          feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
          feedItemInput.subjectId = lg.Id; // The LG lesson where will be add the feed.
          
          // Create the chatter post
          ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
          
          // Assign the chatter post to the OEM Requests topic          
          //ConnectApi.Topics.assignTopicByName(null, feedElement.id, 'OEM Requests');
        }      
      }catch(Exception e){
        Database.rollback(sp);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));      
      }            
    }
}