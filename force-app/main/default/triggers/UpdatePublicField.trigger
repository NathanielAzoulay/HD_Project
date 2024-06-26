trigger UpdatePublicField on Task (before insert) {
    if( HD_TriggerSettings.IsTriggerActive('UpdatePublicField') ){

		for (Task t: Trigger.New){
		    // if public is not true
		    if (t.IsVisibleInSelfService  != true ){
		        t.IsVisibleInSelfService = true;
			}
		}
	}

}