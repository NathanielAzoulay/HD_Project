/**************************************************************************************** 
    Name              : RSLGAssessment 
    Description       : Controller of the VF RSLGAssessment  , to Update LGS Assessment From LG level . 
    Revision History  :-
    Created/Modified by         Created/Modified Date     Requested by      
    ------------------------------------------------------------------
    1. Rashad Saeed (Created)           29/4/17               HD                   
    -------------------------------------------------------------------
***********************************************************************/
public  class RSLGAssessment {
    public Id LGId  {get;set;}
    Public List <BC_Assessment__c> BC_AssList; 
    Public List <LG_Student_Assessment__c> LGS_AssList {get;set;}
    public List<SelectOption> BC_AssOptionList { get; set; }
    public String selectedBC_Ass{get;set;}
    Public String query {get;set;}
    Public RSLGAssessment (){
        LGId = ApexPages.currentPage().getParameters().get('LGID');
        if (LGId==null)
            ApexPages.Message myMsg1 = new ApexPages.Message(ApexPages.Severity.Error,'Please Contact HDC Admin');
        else {
        LG__c rL =[select BC_ID__c ,Id , Name , Course_Sub_Type__c, Course_Sub_Type__r.Base_Course__r.Id from LG__c where Id =:LGId];  
        Id BsId = rL.BC_ID__c ;
        BC_AssList = new List <BC_Assessment__c>();
        LGS_AssList = new List <LG_Student_Assessment__c>();
        BC_AssList = [select Id , Assessment_Name_Text__c from BC_Assessment__c where Base_Course__c=:BsId];
        BC_AssOptionList = new List<SelectOption>();
        BC_AssOptionList.add(new  SelectOption ('None','None'));
        for (BC_Assessment__c bc:BC_AssList) 
            BC_AssOptionList.add(new  SelectOption (bc.Id,bc.Assessment_Name_Text__c));
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('LG_Student_Assessment__c');
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get('RSLGAssessment');
        query = 'SELECT ';
        for(Schema.FieldSetMember f : fieldSetObj.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        }  
    }
    public PageReference ChangeBCAss(){
        query = query.substringBeforeLast('Id FROM LG_Student_Assessment__c');
        query += 'Id FROM LG_Student_Assessment__c ' +' where BC_Assessment__c =' +'\''+selectedBC_Ass+'\''+' and LG_Student__r.LG__r.Id ='+ '\'' + LGId + '\'';
        System.debug('@@@@@@@@@  Query '+ Query);
        system.debug(selectedBC_Ass);
        // LGS_AssList = [select Id , Name from LG_Student_Assessment__c where BC_Assessment__c=:selectedBC_Ass and LG_Student__r.LG__r.Id=:LGId];
        if (selectedBC_Ass == 'None')
            LGS_AssList.Clear();
        else
            LGS_AssList = Database.query(query);
        return null;
    }
    public PageReference rReturn()
    {
        pagereference redirect =  new PageReference('/'+LGId);
        redirect.setRedirect(true);
        return redirect; 
    }
    public PageReference rSave()
    {
        try { 
        Map <Id,Sobject> LGAssMap =  new Map <Id,Sobject>(Database.query(query));
        for (LG_Student_Assessment__c asses :  LGS_AssList)
        {
            if (asses == LGAssMap.get(asses.Id))
                LGAssMap.remove(asses.Id);  
            else
                LGAssMap.put(asses.Id, asses);
        }
        
         
            if (LGAssMap.values()!=null)
                Update LGAssMap.values();
            
            ApexPages.Message myMsg1 = new ApexPages.Message(ApexPages.Severity.CONFIRM,'Records updated successfully ' + String.valueOf (LGAssMap.size()+' Records'));
            ApexPages.addMessage(myMsg1); }
        catch(Exception e) {
            ApexPages.Message myMsg1 = new ApexPages.Message(ApexPages.Severity.Error,''+e.getMessage());
            ApexPages.addMessage(myMsg1);
        }
        
        return null; 
    }
    
}