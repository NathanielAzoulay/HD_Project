/**************************************************************
Name              : RSRedirect 
Description       : Redirect to the record after auto completed 
Created/Modified by   Created/Modified Date                       
-------------------------------------------------------------
1. Rashad Saeed        10/01/2016                 
*************************************************************/
public class RSRedirect{

    public String targetField { get; set; }
    Public Pagereference RedirectToViewMode(){
        return new Pagereference('/'+targetField+'?noredirect=1&isUserEntityOverride=1');
    } 
}