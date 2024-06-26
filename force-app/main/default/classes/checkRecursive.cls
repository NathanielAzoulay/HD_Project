/*---------------------------------------------------------------------------------------------------
Name:            checkRecursive.cls

Description:     check recursive to prevent trigger run more than one time in the same transaction .       
Date             Author          Summary of Changes 
16/11/2017       Rashad saeed 
-----------------------------------------------------------------------------------------------------*/
public Class checkRecursive{
    private static boolean run = true;
    public static set<String> recursionSet = new Set<String>();
    public static boolean runOnce(String triggerName){
        if(!recursionSet.contains(triggerName)){
            recursionSet.add(triggerName);
            return true;
        }else{
            return false;
        }
        /*
        if(run){
         run=false;
         return true;
        }else{
            return run;
        }
        */
    }
}