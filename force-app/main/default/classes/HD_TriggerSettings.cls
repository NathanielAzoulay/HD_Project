/******************************************************************************* 
Name              : HD_TriggerSettings
Description		  : Settings for enabling or disabling triggers
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair         04/06/2016             Dana                  [SW-18628]
1. Hernan Sinclair         02/20/2017             Dana                  [SW-23704]
*******************************************************************************/
global class HD_TriggerSettings {
	
	public static Set<String> disabledTriggers;
	public static Boolean disableAllTriggers = false;
	public static Set<String> disableTriggersFromTest = new Set<String>();
	
	public static Boolean IsTriggerActive( String triggerName ){
		
		if( disabledTriggers == null ){
			disabledTriggers = new Set<String>();
			for( Triggers_to_turn_off__c s : Triggers_to_turn_off__c.getAll().values() ){
				if(s.Disabled__c == true){
					disabledTriggers.add( s.Trigger_API_Name__c.ToLowerCase() );
				}
			} 
		}

		Boolean ret = !disabledTriggers.contains( triggerName.toLowerCase() );
		System.debug(LoggingLevel.INFO, '*** ret: ' + ret);
		if( Test.isRunningTest() && disableTriggersFromTest <> null && disableTriggersFromTest.contains(triggerName)){
			ret = false;
		System.debug(LoggingLevel.INFO, '*** ret: ' + ret);
		}
		if( Test.isRunningTest() && !disabledTriggers.contains( triggerName.toLowerCase()) && ( disableTriggersFromTest <> null && !disableTriggersFromTest.contains(triggerName)) ){
			ret = true;
		System.debug(LoggingLevel.INFO, '*** ret: ' + ret);
		}
		if( Test.isRunningTest() && disableAllTriggers){
			ret = !disableAllTriggers;
		System.debug(LoggingLevel.INFO, '*** ret: ' + ret);
		}
		
		System.debug(LoggingLevel.INFO, '*** triggerName: ' + triggerName);
		System.debug(LoggingLevel.INFO, '*** disableTriggersFromTest.contains(triggerName): ' + disableTriggersFromTest.contains(triggerName));
		System.debug(LoggingLevel.INFO, '*** disabledTriggers: ' + disabledTriggers);
		System.debug(LoggingLevel.INFO, '*** disableTriggersFromTest: ' + disableTriggersFromTest);
		System.debug(LoggingLevel.INFO, '*** ret: ' + ret);

		return ret;
	}
}