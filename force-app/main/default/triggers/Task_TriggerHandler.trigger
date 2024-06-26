trigger Task_TriggerHandler on Task (before insert) {
   
    if( HD_TriggerSettings.IsTriggerActive('Task_TriggerHandler') ){

        for (Task t: Trigger.New){
            // if public is not true
            if (t.IsVisibleInSelfService  != true ){
                t.IsVisibleInSelfService = true;
            }
        }
        
        
        
    }
        TaskTriggerHandler handler = new TaskTriggerHandler();
        handler.changeOwnerMethod(Trigger.new);
   }