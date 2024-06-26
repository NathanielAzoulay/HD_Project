public with sharing class StringUtil {
    
    @InvocableMethod(label='Remove duplicates from semicolon delimited string')
    public static List<String> RemoveDuplicatesFromStr(List<String> semicolonDelimitedStrs) {

        List<String> uniqueValsStr = new List<String>();

        if(semicolonDelimitedStrs.size() > 0){
            for(String strVal : semicolonDelimitedStrs){
                if(String.isNotBlank(strVal)){
                    List<string> strLst = strVal.split(';');
                    Set<String> strSet = new Set<String>(strLst); //convert to set will remove dups.
                    String finalStr = String.join(strSet,';');
                    uniqueValsStr.add(finalStr);
                }
            }
        }

        return uniqueValsStr;
    }
}