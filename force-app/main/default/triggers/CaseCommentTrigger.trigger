trigger CaseCommentTrigger on CaseComment (before insert){
    CaseComment_Handler handler = new CaseComment_Handler();
    /******************* before Insert    ************************/
    if (Trigger.isBefore && Trigger.isInsert){// before insert
        	handler.OnBeforeInsert(Trigger.new);
    }
}