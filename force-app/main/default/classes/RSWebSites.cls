/**************************************************************
Name              : RSWebSites
Description       : rest for websites .
Created/Modified by   Created/Modified Date                       
-------------------------------------------------------------
1. Rashad Saeed        19/02/2017                 
*************************************************************/
@RestResource(urlMapping='/RSWebSites/*')
Global without sharing class RSWebSites {
    global static set<string> allCountrySet = new set<string>{ 'Albania',
                                                                'Algeria',
                                                                'Andorra',
                                                                'Angola',
                                                                'Antigua',
                                                                'Argentina',
                                                                'Armenia',
                                                                'Australia',
                                                                'Austria',
                                                                'Azerbaijan',
                                                                'Bahamas',
                                                                'Bahrain',
                                                                'Bangladesh',
                                                                'Barbados',
                                                                'Belarus',
                                                                'Belgium',
                                                                'Belize',
                                                                'Benin',
                                                                'Bhutan',
                                                                'Bolivia',
                                                                'Bosnia',
                                                                'Botswana',
                                                                'Brazil',
                                                                'Brunei',
                                                                'Bulgaria',
                                                                'Burma',
                                                                'Burundi',
                                                                'Cambodia',
                                                                'Cameroon',
                                                                'Canada',
                                                                'Cape Verde',
                                                                'Central African Republic',
                                                                'Chad',
                                                                'Chile',
                                                                'China',
                                                                'Colombia',
                                                                'Comoros',
                                                                'Congo',
                                                                'Costa Rica',
                                                                'Croatia',
                                                                'Cuba',
                                                                'Cyprus',
                                                                'Czech Republic',
                                                                'Denmark',
                                                                'Djibouti',
                                                                'Dominica',
                                                                'East Timor',
                                                                'Ecuador',
                                                                'Egypt',
                                                                'El Salvador',
                                                                'England',
                                                                'Eritrea',
                                                                'Estonia',
                                                                'Ethiopia',
                                                                'Fiji',
                                                                'Finland',
                                                                'France',
                                                                'Gabon',
                                                                'Gambia',
                                                                'Georgia',
                                                                'Germany',
                                                                'Ghana',
                                                                'Great Britain',
                                                                'Greece',
                                                                'Grenada',
                                                                'Grenadines',
                                                                'Guatemala',
                                                                'Guinea',
                                                                'Guyana',
                                                                'Haiti',
                                                                'Honduras',
                                                                'Hungary',
                                                                'Iceland',
                                                                'India',
                                                                'Indonesia',
                                                                'Iran',
                                                                'Iraq',
                                                                'Ireland',
                                                                'Israel',
                                                                'Italy',
                                                                'Ivory Coast',
                                                                'Jamaica',
                                                                'Japan',
                                                                'Jordan',
                                                                'Kazakhstan',
                                                                'Kenya',
                                                                'Kiribati',
                                                                'Korea',
                                                                'Kuwait',
                                                                'Kyrgyzstan',
                                                                'Laos',
                                                                'Latvia',
                                                                'Lebanon',
                                                                'Lesotho',
                                                                'Liberia',
                                                                'Libya',
                                                                'Liechtenstein',
                                                                'Lithuania',
                                                                'Luxembourg',
                                                                'Macedonia',
                                                                'Madagascar',
                                                                'Malawi',
                                                                'Malaysia',
                                                                'Maldives',
                                                                'Mali',
                                                                'Malta',
                                                                'Marshall',
                                                                'Mauritania',
                                                                'Mauritius',
                                                                'Mexico',
                                                                'Micronesia',
                                                                'Moldova',
                                                                'Monaco',
                                                                'Mongolia',
                                                                'Montenegro',
                                                                'Morocco',
                                                                'Mozambique',
                                                                'Myanmar',
                                                                'Namibia',
                                                                'Nepal',
                                                                'Netherlands',
                                                                'New Zealand',
                                                                'Nicaragua',
                                                                'Niger',
                                                                'Nigeria',
                                                                'Norway',
                                                                'Oman',
                                                                'Pakistan',
                                                                'Palau',
                                                                'Panama',
                                                                'Papua',
                                                                'Paraguay',
                                                                'Peru',
                                                                'Philippines',
                                                                'Poland',
                                                                'Portugal',
                                                                'Qatar',
                                                                'Romania',
                                                                'Russia',
                                                                'Rwanda',
                                                                'Samoa',
                                                                'San Marino',
                                                                'Sao Tome',
                                                                'Saudi Arabia',
                                                                'Senegal',
                                                                'Serbia',
                                                                'Seychelles',
                                                                'Sierra Leone',
                                                                'Singapore',
                                                                'Slovakia',
                                                                'Slovenia',
                                                                'Solomon',
                                                                'Somalia',
                                                                'South Africa',
                                                                'South Sudan',
                                                                'Spain',
                                                                'Sri Lanka',
                                                                'St. Kitts',
                                                                'St. Lucia',
                                                                'Saint Kitts',
                                                                'Santa Lucia',
                                                                'Sudan',
                                                                'Suriname',
                                                                'Swaziland',
                                                                'Sweden',
                                                                'Switzerland',
                                                                'Syria',
                                                                'Taiwan',
                                                                'Tajikistan',
                                                                'Tanzania',
                                                                'Thailand',
                                                                'Tobago',
                                                                'Togo',
                                                                'Tonga',
                                                                'Trinidad',
                                                                'Tunisia',
                                                                'Turkey',
                                                                'Turkmenistan',
                                                                'Tuvalu',
                                                                'Uganda',
                                                                'Ukraine',
                                                                'United Arab Emirates',
                                                                'United Kingdom',
                                                                'United States',
                                                                'Uruguay',
                                                                'Uzbekistan',
                                                                'Vanuatu',
                                                                'Vatican',
                                                                'Venezuela',
                                                                'Vietnam',
                                                                'Yemen',
                                                                'Zambia',
                                                                'Zimbabwe'
                                                };
    Global Class Country {
        String City ;
        List <Lc> Lcs ;
        Id MF ;
        String MFCompany ;
        Public Country (String City , id Mf,List <Lc> LCs,String Company ){
          this.City = City;  
          this.mf= mf;
          this.lcs =Lcs;
          this.MFcompany=company;
        }
    }
   
    Global Class Lc{
       Id LcUserId;
       Id ContactId; 
       String MailingStreet;
       String Company ; 
       Public Lc (contact c,Id LcUserId )
           {
             this.LcUserId = LcUserId ; 
             this.MailingStreet = c.account.BillingStreet; 
             this.ContactId = c.id;
             this.company = c.Account.name;  
           }
    }
    Global Class Info {
        //List <String> AllSFCountries ; 
        String Country ;
        //Map <string,string> rMapApi = new Map <String , string >();
        List <Country> Cities;
        String MF;
        Public info (String Country ,List <Country>Cities ,String Mf){
            this.Country = Country; 
            this.Cities= Cities;
            This.MF = Mf;
           // rMapApi.put ('Franchisee','test');
            /*
            AllSFCountries = new List <String>();
            Schema.DescribeFieldResult CountryResult = Account.BillingCountry.getDescribe();
            List<Schema.PicklistEntry> Count = CountryResult.getPicklistValues();
            List <String> AllCountries= new List <String>();
            for( Schema.PicklistEntry c : Count) 
                this.AllSFCountries.add(String.valueOf (c));*/
        }
    }
    
    Global Class Infos {
        List <Info> Info = new List <info>();
        Map <string,string> rMapApi = new Map <String , string >() ;
        Global Infos (List <Info> rInfo )
        {
          this.Info = rInfo;  
          //Map <string,string> rMapApi = new Map <String , string >();
          this.rMapApi.put ('Franchisee','MF');//MF
          this.rMapApi.put ('Other','MF');//MF 
          this.rMapApi.put ('Student','LcUserId');//Lc
          this.rMapApi.put ('Teacher','LcUserId');//Lc  
        }
    }
    @HttpPost
    global static Infos doPost() {
        
       RestRequest req = RestContext.request;
       RestResponse res = Restcontext.response;    
        
       Id FranchiseeRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();   
       Id MfRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();   
       Id LcRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();   
 
       List<Contact> rLcConatcts = [SELECT Account.MF_Name__c,Account.MF_USER_ID__c,Account.Account_Status__c,Account.recordTypeid,MailingCountry,Account.Name,Account.parent.Name,
                                    MailingCity,Account_Type__c,Id,Account.BillingStreet,
                                    Account.BillingCountry,Account.BillingCity,Account.Partner_Account_User__c,
                                    Account.parent.Partner_Account_User__c ,Account.parent.recordTypeid,
                                    Account.parent.Account_Type__c
                                    FROM contact where
                                    recordTypeId =:FranchiseeRecordType
                                    and Status__c ='Active'
                                    and Account.BillingCountry!=null
                                    and Account.BillingCity!=null
                                    and contact.Account.recordTypeid =: LcRecordType
                                    and contact.Account.Partner_Account_User__c !=null
                                    and Contact.Account.Account_Status__c = 'Active'
                                    ];
     
      Map <String , Map <String,List <Contact>>> CountryCityCon = new Map  <String , Map <String,List <Contact>>>  ();  
      Map <String ,List <Lc>>  LcsMap = new Map  <String ,List <Lc>> ();
      Map <String , Id> MfsMap = new Map  <String ,Id> ();  
      Map <String ,String> MfsCompany = new Map <String,String>();  
      Map <String ,set <Id>>  CountryMF = new Map  <String ,set <Id>> ();  
      
      //Map <Id , Id> ContactMfMap = new Map <Id,Id>(); 
      //Map <Id , Id> ContactUserMap = new Map <Id,Id>();
      /*   
      List<User> rusers = [select MF_ID__c ,Contact.id from User where
                          Contact.recordtypeid =:FranchiseeRecordType 
                          and contact.Account.recordTypeid =: LcRecordType
                          //And MF_ID__c !=NULL
                         ]; 
     for (user r : rusers)   
     {
         ContactMfMap.put (r.Contact.id,r.MF_ID__c);
         ContactUserMap.put (r.Contact.id, r.id);
         System.debug(' @@@@@@@@@@@ user contact Id '+r.Contact.id);
     }
        */
      for (Contact c :rLcConatcts) 
      {
          if (!CountryMF.containsKey(c.Account.BillingCountry))
              CountryMF.put (c.Account.BillingCountry,new Set<Id>{c.Account.MF_USER_ID__c});
          else
              CountryMF.get(c.Account.BillingCountry).add(c.Account.MF_USER_ID__c);
          MfsMap.put(c.Account.BillingCountry+c.Account.BillingCity,c.Account.MF_USER_ID__c);
          MfsCompany.put (c.Account.BillingCountry+c.Account.BillingCity,c.Account.MF_Name__c);
          //if (c.Account.parent.recordTypeid == MfRecordType && c.Account.parent.Account_Type__c=='MF')
              
             // MfsMap.put(c.Account.BillingCountry+c.Account.BillingCity,c.Account.parent.Partner_Account_User__c);
          //else
             // MfsMap.put(c.Account.BillingCountry+c.Account.BillingCity,ContactMfMap.get(c.id));
          
          if (!LcsMap.containsKey(c.Account.BillingCountry+c.Account.BillingCity))
          {
              
              LcsMap.put(c.Account.BillingCountry+c.Account.BillingCity,new List<Lc>{new Lc (c,c.Account.Partner_Account_User__c)});
          }
          else
          {
              LcsMap.get (c.Account.BillingCountry+c.Account.BillingCity).add(new Lc (c,c.Account.Partner_Account_User__c));
          }
          
          if (!CountryCityCon.containsKey(c.Account.BillingCountry))
          {
              Map <String ,List<Contact>> tempMap = new  Map <String ,List<Contact>> ();
              tempMap.put (c.Account.BillingCity,new List <Contact>{c});
              
              //ConCityCon.put (c.MailingCountry,new Map <String,List <Contact>> (c.MailingCountry,con));  
              CountryCityCon.put(c.Account.BillingCountry, new Map <String ,List<Contact>>(tempMap));
              System.debug('@@@@@@@@@@@@@ ConCityCon '+CountryCityCon);
          }
          else  if ( CountryCityCon.get(c.Account.BillingCountry).containsKey(c.Account.BillingCity)) {
              
              
              CountryCityCon.get(c.Account.BillingCountry).get(c.Account.BillingCity).add (c);
          }
          else
          {
              CountryCityCon.get(c.Account.BillingCountry).put(c.Account.BillingCity,new List<Contact>{c});
          }
      }
        
     List <Info> Infos = new List <Info> ();   
     set<string> countriesFromRecordSet = new set<string>();    
     for (String Country : CountryCityCon.keySet() )
     {   
         countriesFromRecordSet.add(Country);
         List <Country> Cities = new List <Country> ();
         System.debug('@@@@@@@@@@@@@ Country'+Country); 
         for (String City : CountryCityCon.get(Country).keySet())
         {
           
           Cities.add (new Country (City,MfsMap.get(Country+City),LcsMap.get(Country+City),MfsCompany.get(Country+City)));
           System.debug('@@@@@@@@@@@@@ City '+LcsMap.get(Country+City)+' City'+City);
         }
         Cities.add(new Country('Other', null, new List <Lc>{}, ''));
         
         if (CountryMF.get(Country).size()==1) {
            
            String Mf =  String.valueOF (CountryMF.get(Country));
             Mf= Mf.substringBetween('{','}'); 
            Infos.add (new Info(Country,Cities,Mf)); 
         }
       else
            Infos.add (new Info(Country,Cities,''));  
       System.debug('@@@@@@@@@@@@@ Infos '+Infos);
     }
     //Add other countries 
     if(countriesFromRecordSet.size() > 0){
         for(string country : allCountrySet){
             if(!countriesFromRecordSet.contains(country)){
                 List <Country> Cities = new List <Country> ();
                 Cities.add(new Country('Other', null, new List <Lc>{}, ''));
                 Infos.add (new Info(Country, Cities,'MF01'));    
             }    
         }    
     }
     
         System.debug('@@@@@@@@@@@@@ Infos '+Infos); 
     Infos jsonObj  = new Infos(Infos); 
     return jsonObj;
     //return new List <Info>();
   }
    
   
}