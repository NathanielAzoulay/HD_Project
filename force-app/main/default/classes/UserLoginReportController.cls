/******************************************************************************* 
  Name              : UserLoginReportController 
  Description       : 
  Revision History  :-
  Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
  ----------------------------------------------------------------------------------------
  1. Aparna             21/06/2017                Rashad Saeed
  *******************************************************************************/

public with sharing class UserLoginReportController {

    public List<AggregateResult>        lstUser;
    public List<ModalForActiveUsers>    lstModalAV              {get; set;}
    public List<AggregateResult>        lstUser1;
    public List<UsersGByMailCountry>    lstUserGroupByMCountry  {get;set;}
    public List<AggregateResult>        lstUser2;
    public List<UsersGroupByCntryPName> lstUsersByCandPName     {get;set;}

    public UserLoginReportController() {
    
        lstUser = [SELECT contact.recordtype.name rec, profile.Name pName, count(id) activeUserCount, count(LastLoginDate) lastLoginCount FROM user WHERE isActive=true and ContactId != null GROUP BY contact.recordtype.name , profile.Name];
        ModalForActiveUsers activeUsers   = new ModalForActiveUsers();
        Map<String, List<ProfileModal>> m = new Map<String, List<ProfileModal>>();
        if(lstUser.size()>0){
            for(AggregateResult ar : lstUser){
            String recType                = (String)ar.get('rec');
            List<ProfileModal> pModelList = m.get(recType);
            
            if(pModelList ==null)
                pModelList = new List<ProfileModal>(); 
            ProfileModal pm          = new ProfileModal();
            pm.profileName           = (String) ar.get('pName');
            pm.countOfActiveUsers    = (integer) ar.get('activeUserCount');
            pm.countOfLastLoginUsers = (Integer) ar.get('lastLoginCount');
            pModelList.add(pm);
            m.put(recType,pModelList);
         }
        }
        
        
        lstModalAV = new List<ModalForActiveUsers>();
        
        for(String recTypeName : m.keyset()){
        ModalForActiveUsers acUserCount = new ModalForActiveUsers();
        acUserCount.contactRecordType   = recTypeName;
        acUserCount.lstProfileModal     = m.get(recTypeName);
        
            for(ProfileModal PModal : m.get(recTypeName)){
                if(acUserCount.countOfLastLoginRecords == null){
                    acUserCount.countOfLastLoginRecords = 0;
                }
                if(acUserCount.countOfActiveRecords == null){
                    acUserCount.countOfActiveRecords = 0;
                }
                
                if(PModal.countOfLastLoginUsers > 0){
                    acUserCount.countOfLastLoginRecords += Integer.valueOf(PModal.countOfLastLoginUsers);
                }
                if(PModal.countOfActiveUsers >0){
                    acUserCount.countOfActiveRecords    += Integer.valueOf(PModal.countOfActiveUsers);
                }
                  
            }
            
            lstModalAV.add(acUserCount);
        }
        
        lstUser1 = [SELECT contact.MailingCountry contMCountry, count(id) activeUserCount, count(LastLoginDate) lastLoginCount FROM user WHERE isActive=true and ContactId != null and contact.MailingCountry != null GROUP BY contact.MailingCountry ];
        lstUserGroupByMCountry = new List<UsersGByMailCountry>();
        if(lstUser1.size()>0){
        
            for(AggregateResult ar : lstUser1){
            
            UsersGByMailCountry usersGbyCntry = new UsersGByMailCountry();
            usersGbyCntry.countryName      = (String) ar.get('contMCountry');
            if(usersGbyCntry.lastLoginCount == null)
                usersGbyCntry.lastLoginCount = 0;
            usersGbyCntry.lastLoginCount   = (integer) ar.get('lastLoginCount');  
            if(usersGbyCntry.activeUsersCount == null)
                usersGbyCntry.activeUsersCount = 0;
            usersGbyCntry.activeUsersCount = (integer) ar.get('activeUserCount');
            lstUserGroupByMCountry.add(usersGbyCntry);
            
            }
        }
        
        
        lstUser2 = [SELECT contact.MailingCountry contMCountry, profile.Name pName, count(id) activeUserCount, count(LastLoginDate) lastLoginCount FROM user WHERE isActive=true and ContactId != null and contact.MailingCountry != null GROUP BY contact.MailingCountry, profile.Name];
        UsersGroupByCntryPName activeUsers2  = new UsersGroupByCntryPName();
        Map<String, List<ProfileModal>> m2   = new Map<String, List<ProfileModal>>();
        if(lstUser2.size()>0){
          for(AggregateResult ar : lstUser2){
            String countryName               = (String)ar.get('contMCountry');
            List<ProfileModal> pModelList2   = m2.get(countryName);
            
            if(pModelList2 == null)
                pModelList2 = new List<ProfileModal>(); 
            ProfileModal pm2          = new ProfileModal();
            pm2.profileName           = (String) ar.get('pName');
            pm2.countOfActiveUsers    = (integer) ar.get('activeUserCount');
            pm2.countOfLastLoginUsers = (Integer) ar.get('lastLoginCount');
            pModelList2.add(pm2);
            m2.put(countryName,pModelList2);
         }  
        }
        
        
        lstUsersByCandPName = new List<UsersGroupByCntryPName>();
        
        for(String recCountryName : m2.keyset()){
        UsersGroupByCntryPName acUserCount2 = new UsersGroupByCntryPName();
        acUserCount2.mailingCountryName     = recCountryName;
        acUserCount2.proModalList           = m2.get(recCountryName);
        
            for(ProfileModal PModal2 : m2.get(recCountryName)){
                if(acUserCount2.lastLoginUsersRecords == null){
                    acUserCount2.lastLoginUsersRecords = 0;
                }
                if(acUserCount2.activeUsersRecords == null){
                    acUserCount2.activeUsersRecords = 0;
                }
                
                if(PModal2.countOfLastLoginUsers > 0){
                    acUserCount2.lastLoginUsersRecords += Integer.valueOf(PModal2.countOfLastLoginUsers);
                }
                if(PModal2.countOfActiveUsers >0){
                    acUserCount2.activeUsersRecords    += Integer.valueOf(PModal2.countOfActiveUsers);
                }
                  
            }
            
            lstUsersByCandPName.add(acUserCount2);
        }
    }

    
    public class ModalForActiveUsers{
        public String             contactRecordType       {get;set;}
        public List<ProfileModal> lstProfileModal         {get;set;}
        public Integer            countOfLastLoginRecords {get;set;}
        public Integer            countOfActiveRecords    {get;set;} 
    }
    public class ProfileModal{
        public String  profileName           {get;set;}
        public Integer countOfLastLoginUsers {get;set;}
        public Integer countOfActiveUsers    {get;set;}
    }
    
    public class UsersGByMailCountry{
        public String countryName       {get;set;}
        public Integer lastLoginCount   {get;set;}
        public Integer activeUsersCount {get;set;}
    }
     public class UsersGroupByCntryPName{
        public String             mailingCountryName    {get;set;}
        public List<ProfileModal> proModalList            {get;set;}
        public Integer            lastLoginUsersRecords {get;set;}
        public Integer            activeUsersRecords    {get;set;}
    }
}