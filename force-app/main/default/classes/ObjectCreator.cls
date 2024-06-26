public class ObjectCreator{

	public static Seminar_Type__c getNewSeminarType(){
		Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
    	seminarType.Active__c = true;
	    seminarType.Program_Type__c = 'HDE';
	    seminarType.Type__c = 'Seminar';
	    return seminarType;
	}
	
	public static Agreement__c getNewAgreement(Id accId){
		Agreement__c agreement = new Agreement__c(From_Franchisee__c = accId, Agreement_Status__c = 'Active', Royalty_Type__c = '1 - Standard');
        return agreement;
	}
	
	public static List<Agreement_Parameter__c> getNewAgreementParametersByStudents(Id agId){
		List<Agreement_Parameter__c> ag2Ins = new List<Agreement_Parameter__c>();
		for(Integer i = 0; i < 4; i++){
			ag2Ins.add(new Agreement_Parameter__c(Agreement__c = agId, Student_Count_Revenue__c = i*100, Royalty_Percent__c = i*10));	
		}		
        return ag2Ins;
	}
	
	public static List<Agreement_Parameter__c> getNewAgreementParametersByType(Id agId, String accType){
		List<Agreement_Parameter__c> ag2Ins = new List<Agreement_Parameter__c>();
		for(Integer i = 0; i < 4; i++){
			ag2Ins.add(new Agreement_Parameter__c(Agreement__c = agId, Account_Type__c = accType, Royalty_Percent__c = i*10));	
		}		
        return ag2Ins;
	}	

	public static Base_Course__c getNewBaseCourse(){
		Base_Course__c bc = new Base_Course__c(Program_Type__c = 'HDE', Status__c = 'Active', Max_Lessons_per_Day__c = 2 );
        return bc;
	}

	public static Course_Sub_Type__c getNewCourseSubType(Id accId, Id baseCurseId){
		Course_Sub_Type__c cSubType = new Course_Sub_Type__c(Franchisee_Name__c = accId, Number_of_Lessons_a_Week__c = 3, Course_Sub_Type_Name__c = 'Test', Course_Sub_Type_Active__c = true, Program_Type__c = 'HDE', Base_Course__c = baseCurseId, Price_per_Month__c = 0);
        return cSubType;
	}

	public static LG__c getNewLG(Id accId, Id curseSubTypeId, Id agreeId){
		LG__c lg = new LG__c();
	    lg.Agreement__c = agreeId;
	    lg.Course_Sub_Type__c = curseSubTypeId;
	    //lg.Parent_Franchisee__c = accId;
	    lg.Course_Price__c = 100;
	    lg.Price_per_Month__c = 100;
	    lg.Price_per_Session__c = 100;
	    lg.Gap_between_Price_Payments__c = 1;
	    lg.LG_Start_Date__c = system.today();
	    lg.LG_End_Date__c = system.today().addMonths(1);
	    lg.LG_Start_Paying_Date__c = system.today();
	    lg.LG_End_Paying_Date__c = system.today().addMonths(1);
        lg.Billing_Type__c = 'Price per Month';
        lg.CurrencyIsoCode = 'USD';
        lg.LG_Type__c = 'Standard';
        lg.Group_Status__c = 'Planned';
        return lg;
	}

	public static LG_Lesson__c getNewLG_Lesson(Id lgId, Id conId, Id lgDHId){  
        /*
         System.DmlException: Insert failed. First exception on row 0; 
		first error: DUPLICATES_DETECTED, You're trying to create a duplicate LG Lesson for a LG with the same lesson date and hour: []
         */ 
		//Adding name field by Avihai during DUPLICATE ERROR
        Integer rand = Math.round(Math.random()*1000);
        Date randomDate;
        //for(Integer i = 0; i<30;i++){
			randomDate = system.today().addDays(1+rand);
//        }        
		LG_Lesson__c lgLesson = new LG_Lesson__c(LG__c = lgId, Lesson_Date_Hour__c = randomDate, Lesson_Teacher__c = conId, LG_Days_Hours__c = lgDHId ); //Adding random field by Avihai Task-000001699
        //LG_Lesson__c lgLesson = new LG_Lesson__c(LG__c = lgId, Lesson_Date_Hour__c = system.today().addDays(1), Lesson_Teacher__c = conId, LG_Days_Hours__c = lgDHId );
        return lgLesson;
	} 

	public static LG_Days_Hours__c getNewLG_Days_Hours(Id lgId){
		LG_Days_Hours__c lgDH1 = new LG_Days_Hours__c( LG__c = lgId, Day__c = 'Mon', Start_Hour__c = '08:00' );
        return lgDH1;
	}

	public static Contact getNewContact(Id acc, Id typeId){
		String letters = 'ABCDabcdefghijqlmnopqrstuvwxyzZ';
		String name = '';
		for(Integer i = 0; i<30;i++){
			Integer cut = Math.round(Math.random()*(letters.length()-1));			
			name += letters.substring(cut,cut+1);		
		}
		Contact con = new Contact(FirstName = name, LastName = 'Test ' + name, AccountId = acc, RecordTypeId = typeId);		
		return con;
	}

	public static Account getNewAccount(){
        
        Country_Details__c CountryDetails = new Country_Details__c(Name ='United States');
        Insert CountryDetails;
		String name = 'Test ' + String.valueOf(Math.round(Math.random()*10000));
		Account acc = new Account(Name = name, Account_Status__c = 'Active', BillingCountry = 'France',Country_Detail__c=CountryDetails.Id, Agreement_Received_Date__c = System.today(), HD_Share_Of_Franchisee_Fee__c = '33');
        return acc;
	}

	public static Holiday_Vacation__c getNewHolidayVacation(Id recordTypeId){
		Holiday_Vacation__c hv = new Holiday_Vacation__c(Name = 'Holiday Test', RecordTypeId = recordTypeId, Start_Date__c = System.today(), End_Date__c = System.today().addDays(2));
        return hv;
	}

	public static Franchisee_Additional_Holidays__c getNewAdditionalHoliday(Id franchiseAccId){
		Franchisee_Additional_Holidays__c additionalHoliday = new Franchisee_Additional_Holidays__c(Country_Religion__c = 'Spain', Franchisee__c = franchiseAccId, CurrencyIsoCode = 'EUR');
        return additionalHoliday;
	}

	public static Franchisee_VAT__c getNewFranchiseeVat(Id franchiseeId, Decimal vatValue){
		Franchisee_VAT__c franchiseeVat = new Franchisee_VAT__c();
		franchiseeVat.VAT__c = vatValue;
		franchiseeVat.VAT_End_Date__c = System.today().addMonths(1);
		franchiseeVat.VAT_From_Date__c = System.today().addMonths(-1);
		franchiseeVat.Franchisee__c = franchiseeId;
		return franchiseeVat;
	}

	public static LG_Payment__c getNewLGPayment(Id lgId, Id studentId, Id studentContactId){
		LG_Payment__c payment = new LG_Payment__c();
        payment.LG__c = lgId;
        payment.Payment_Type__c = 'Standard';
        payment.Planned_Date__c = system.today();
        payment.LG_Student__c = studentId;
        payment.Student__c = studentContactId;
		return payment;
	}
	
	public static Teacher_Agreement__c getNewTeacherAgreement(Id teacherContactId ){
		Teacher_Agreement__c tAgree = new Teacher_Agreement__c();
        tAgree.Teacher__c = teacherContactId;
		return tAgree;
	}
	
	public static Group_Income_Per_Month__c getNewGroupIncomePerMonth( Id agreementId, Id lgId ){
		Group_Income_Per_Month__c gipm = new Group_Income_Per_Month__c();
		gipm.Agreement__c = agreementId;
		gipm.LG__c = lgId;
		return gipm;
	}
	
	public static Family__c getNewFamily(){
		Family__c family = new Family__c(Name = 'test ' + String.valueOf(Math.random()) );
		return family;
	}
	
	public static FR_Order__c getNewOrder(Id priceListTitleId, Id recordTypeId){		
		
		FR_Order__c order = new FR_Order__c();
		order.RecordTypeId = recordTypeId;
		order.Price_List_Title__c = priceListTitleId;
		order.Required_Date__c = System.today().addMonths(1);
		//order.Method_of_Payment__c = 'Test Method';
		return order;
	}

	public static FR_Order_Product__c getNewOrderProduct(Id orderId, Id productPriceId ,Id recordTypeId){		
		FR_Order_Product__c orderProduct = new FR_Order_Product__c();		
		orderProduct.RecordTypeId = recordTypeId;
		orderProduct.Order__c = orderId;
		orderProduct.Quantity__c = 2;
		orderProduct.Product_Price__c = productPriceId;

		return orderProduct;
	}


	public static Price_List_Title__c getNewPriceListTitle(){		
		Price_List_Title__c priceListTitle = new Price_List_Title__c();
		priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('HD').getRecordTypeId();
		priceListTitle.Name = 'Test Price List';
		priceListTitle.CurrencyIsoCode = 'EUR';
		priceListTitle.Program_Type__c = 'HDE';
		priceListTitle.Target_entity_type__c = 'MF';
		priceListTitle.Active__c = true;

		return priceListTitle;
	}

	public static Price_List_Title__c getNewPriceListTitleFranchisee(Id priceListTitleId){		
		Price_List_Title__c priceListTitle = getNewPriceListTitle();
		priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
		priceListTitle.HD_Price_List_Title__c = priceListTitleId;
		priceListTitle.CurrencyIsoCode = 'USD';
		return priceListTitle;
	}

	public static Product_Price__c getNewProductPrice(Id priceListId){
		Product_Price__c productPrice = new Product_Price__c();		
		productPrice.RecordTypeId = Schema.SObjectType.Product_Price__c.getRecordTypeInfosByName().get('HD').getRecordTypeId();
		productPrice.Selling_Price__c = 10;
		productPrice.Price_List_Title__c = priceListId;
		productPrice.Unique_Product_Price_ID__c = 'test_' + String.valueOf(Math.random());
		return productPrice;
	}

	public static HD_Product__c getNewHDProduct(){
		HD_Product__c hdProduct = new HD_Product__c();		
		hdProduct.Name = 'Test Product';
	    String PN_Code = 'test_' + String.valueOf(Math.random());
		Integer maxSize = 14;
        //Avihai added substring accordin to the following error. Task-000001930 17/07/2018
        //During Error in apex class test : This error occurred when the flow tried to update records: 
        //STRING_TOO_LONG: Set PN code: data value too large: test_0.2488200782490957 (max length=15)
		if(PN_Code.length() > maxSize ){
    		PN_Code = PN_Code.substring(0, maxSize);
		}
		hdProduct.PN_Code__c = PN_Code;
		hdProduct.Product_Category__c = 'Marketing';
		hdProduct.Language__c = 'English';
		hdProduct.Program_Type__c = 'HDE';
		hdProduct.Product_Status__c = 'Active';
		hdProduct.Product_Type__c = 'CD';

		return hdProduct;
	}

	public static Set_Product__c getNewSetProduct(Id hdProductId){
		Set_Product__c setProduct = new Set_Product__c();		
		setProduct.Set_Product__c = hdProductId;
		
		return setProduct;
	}

	public static Teacher_Qualification__c getNewTeacherQualification(Id theacherId, Id baseCurseId){
		Teacher_Qualification__c teacherQ = new Teacher_Qualification__c();
		teacherQ.Teacher__c = theacherId;
		teacherQ.Base_Course__c = baseCurseId;
		return teacherQ;
	}
	
	public static LG_Student__c getNewLGStudent(Id studentContactId, Id lgId){
		LG_Student__c student = new LG_Student__c();
		student.Student__c = studentContactId;
		student.LG__c = lgId;
        student.Billing_Type__c = 'Price per Month';
		student.Lesson_Type__c = 'Standard';
		student.Student_Course_Start_Date__c = system.today();
		student.Student_Course_End_Date__c = System.today().addDays(5);
		student.Student_Start_Paying_Date__c = system.today();
	    student.Student_End_Paying_Date__c = System.today().addDays(5);
		student.LG_Student_Old_ID__c = String.valueOf(math.random()*10000);

		return student;
	}

	public static LG_Student_Attendance__c getNewStudentAttendance( Id lessonId, Id studentId){
		LG_Student_Attendance__c studentAtt = new LG_Student_Attendance__c();
		studentAtt.LG_Lesson__c 	= lessonId;
		studentAtt.Lesson_Type__c 	= 'Regular';
		studentAtt.LG_Student__c 	= studentId;
		studentAtt.Attended__c 		= 'Yes'; 
		
		return studentAtt;
	}

	public static LG_Discount__c getNewLGDiscount(Id studentId, Id lgId){
		LG_Discount__c lgDisc = new LG_Discount__c();
		lgDisc.LG__c = lgId;
		lgDisc.Discount_Reason__c = 'test';
		lgDisc.Discount_Type__c = 'One Time (Month)';
		lgDisc.Month__c = 'February';
		lgDisc.Year__c = '2017';
		lgDisc.Requested_Course_Price__c = 3;
		lgDisc.Approved_Course_Price__c = 1;
		//lgDisc.Requested_Price_per_Session__c = 1;
		//lgDisc.Approved_Price_per_Session__c = 1;
		lgDisc.LG_Student__c = studentId;

		return lgDisc;
	}

	public static Seminar__c getNewSeminar(){
		//String name = 'Test ' + String.valueOf(Math.random());
		Seminar__c seminar = new Seminar__c();
		seminar.Venue_City__c = 'Test venue';
		seminar.Start_Date__c = System.today();
		seminar.End_Date__c = System.today().addDays(7);
		seminar.Status__c = 'Application';
		seminar.CurrencyIsoCode = 'EUR';

		Seminar_Type__c seminarType = getNewSeminarType();
		insert seminarType;
		
		seminar.Seminar_Type__c = seminarType.Id;

		return seminar;
	}

	public static Seminar_Teachers__c getNewSeminarTeacher(Id seminarId, Id teacherId){
		Seminar_Teachers__c st = new Seminar_Teachers__c();
        st.Teacher__c = teacherId;
        st.Seminar__c = seminarId;

        return st;
	}

	public static Campaign getNewCampaign(){
		Campaign camp = new Campaign();
		camp.Name = 'Test ' + String.valueOf(Math.random());

        return camp;
	}
	
	public static LC_Class_Room__c getNewLCClassRoom( Id acc ){
		LC_Class_Room__c lcClassRoom = new LC_Class_Room__c();
		lcClassRoom.Name = 'Test ' + String.valueOf(Math.random());
		lcClassRoom.Franchisee_Name__c = acc;
		
        return lcClassRoom;
	}
	
	public static User getNewUser(Id contactId){
		Id profileId = [SELECT Id FROM Profile WHERE Name LIKE '%HDC TT%' LIMIT 1].Id;

    	User user = new User(ContactId = contactId, Username = 'testuser@' + String.valueOf(Math.random()) + '.com');
    	user.LastName = 'testuser_' + String.valueOf(Math.random());
    	user.Email = 'testuser@' + String.valueOf(Math.random()) + '.com';
    	user.Alias = String.valueOf(Math.random()).substring(0,5);
    	user.ProfileId = profileId;
    	user.EmailEncodingKey='UTF-8';
    	user.LanguageLocaleKey='en_US';
    	user.LocaleSidKey='en_US';
    	user.TimeZoneSidKey='America/Los_Angeles';   	

        return user;
	}

	public static void initializeCustomSetting(){
		Map<String, HD_Settings_List__c> cs = HD_Settings_List__c.getAll();
		User thisUser = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
			if(!cs.containskey('Helen Doron HQ')){
			    insert new HD_Settings_List__c(Name = 'Helen Doron HQ', Value__c = null);
			}
		}
	}

	public class TestEnviroment{
		public Id accId{get;set;}
		public Id lcId{get;set;}
		public Id teacherContactId{get;set;}
		public Id agreeId{get;set;}		
		public Id baseCurseId{get;set;}
		public Id curseSubTypeId{get;set;}
		public Id lgId{get;set;}
		public Id studentContactId{get;set;}
		public Id staffContactId{get;set;}		
		public Id studentId{get;set;}
		public Id lgDHId{get;set;}
		public Id lcClassRoomId{get;set;}
        public Id lgLessonId{get;set;}
        public Id orderId{get;set;}
        public Id orderProductId{get;set;}      
        public Id hdproductId{get;set;} 
        public Id productPriceId{get;set;} 
        public Id priceListTitleId{get;set;}
        public Id priceListTitleRecordTypeId{get;set;} 
		
		public TestEnviroment(){
			DisableSharingMethods();
			initializeCustomSetting();

			Account acc = getNewAccount();
	        insert acc;
	        accId = acc.Id;

	        Account lc = getNewAccount();
	        insert lc;
	        lcId = lc.Id;

	        Contact staffContact 	= getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId());              
	        insert staffContact;
	        staffContactId 		= staffContact.Id;

	        Contact teacherContact 	= getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
	        insert teacherContact;
	        teacherContactId 		= teacherContact.Id;

	        Contact studentContact 	= getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        	insert studentContact;
        	studentContactId 	= studentContact.Id;

	        Agreement__c agree 	= getNewAgreement(acc.Id);             
	        insert agree;
	        agreeId 			= agree.Id;

	        Base_Course__c baseCurse = getNewBaseCourse();                
	        insert baseCurse;
	        baseCurseId 		= baseCurse.Id;

	        Course_Sub_Type__c curseSubType = getNewCourseSubType(acc.Id, baseCurse.Id);
	        curseSubType.Course_Price__c = 9; 
	        curseSubType.Gap_between_Payments__c = 2;
	        curseSubType.Number_of_Payments__c = 2;
        	curseSubType.Price_per_Session__c = 10;
            curseSubType.Preffered_billing_type__c ='Price per Session';
	        insert curseSubType;
	        curseSubTypeId 		= curseSubType.Id;

	        LG__c lg 			= getNewLG(acc.Id, curseSubType.Id, agree.Id);
	        lg.Franchisee__c 	= lc.Id;    
	        insert lg;
	        lgId 				= lg.Id;

	        LG_Days_Hours__c lgDH = getNewLG_Days_Hours(lgId);
	        insert lgDH;
	        lgDHId 				= lgDH.Id;

	        LG_Student__c student = getNewLGStudent(studentContact.Id, lg.Id);
	        student.Approved_Price__c = 22;
	        student.Lesson_Type__c = 'Standard';
	        student.Student_Start_Paying_Date__c = System.today();
	        student.Status_in_LG__c = 'Potential';
	        insert student;
	        studentId 			= student.Id;
	        
	        LC_Class_Room__c lcClassRoom = getNewLCClassRoom(lc.Id);
	        insert lcClassRoom;
	        lcClassRoomId = lcClassRoom.Id;
            
            LG_Lesson__c lg_lesson = getNewLG_Lesson(lgId, studentContactId, lgDHId);
            lg_lesson.Lesson_Teacher__c = teacherContactId;
            insert lg_lesson;
            lgLessonId = lg_lesson.Id;   
            
            HD_Product__c hdproduct = getNewHDProduct();
            insert hdproduct;
            hdproductId = hdproduct.Id;
            
            Price_List_Title__c priceListTitle = getNewPriceListTitle();
            insert priceListTitle;
            priceListTitleId = priceListTitle.Id;
                     
            Product_Price__c productPrice = getNewProductPrice(priceListTitleId);
            productPrice.HD_Product__c = hdproductId;
            insert productPrice;
            productPriceId = productPrice.Id;
            
            FR_Order__c order = getNewOrder(priceListTitleId, Schema.SObjectType.FR_Order__c.getRecordTypeInfosByName().get('MF Order after Submit').getRecordTypeId());
            order.CurrencyIsoCode = 'USD';
            insert order;
            //orderId = order.Id;
            /*
            //priceListTitleRecordTypeId = priceListTitle.RecordTypeId;
            priceListTitleRecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
            FR_Order_Product__c orderProduct = getNewOrderProduct(orderId, hdproductId, priceListTitleRecordTypeId);
            insert orderProduct;
            orderProductId = orderProduct.Id;*/
		}
	}
	
	private static Set<String> sharingMethodsNames = new Set<String>{
                'teacherAgreement_CreateSharingRules', 'SeminarType_CreateSharingRules', 'seminarCreateSharingRules',
                'SeminarDeleteManualSharing', 'SeminarTeachersSharingRules', 'pltAssignmentCreateSharingRules',
                'oppCreateSharingRules', 'lgCreateSharingRules', 'lgStudentCreateSharingRules', 'lgDHCreateSharingRules', 
                'PriceListTitleSharingRules', 'AgreementCreateSharingRules', 'lead_CreateSharingRules', 
                'holydayVacationCreateSharingRules', 'HDC_Order_CreateSharingRules', 'familyCreateSharingRules',
                'DocumentShareRuleCreation', 'courseSubTypeCreateSharingRules', 'ContactCreateSharingRules', 
                'campaignCreateSharingRules', 'baseCourseCreateSharingRules', 'accCreateSharingRules', 'deactivateAccountUsers',
                'HandleNcOrManagerChange','dlrs_ContactTrigger','dlrs_AccountTrigger','ContactUpdateMFID',
                'AccContRelation_CreateSharingRules','MainFranchiseDelete','dlrs_LG_StudentTrigger','setRecordTypeOnConvert',
                'Default_Price_List_Title','createLGPaymentToLG','LG_CreateGroupIncomePerMonth','LG_checkTeacherQualifications',
                'updateCompletedLGStudentWhenCompletedLGIsBeingActivatedAgain','deleteLGPaymentToLG',
                'maintenaceLGStudents','maintenanceLGPaymentsAndGIMRecordsOnDeclaredNroChanged','recreateLGPayment2LGBillingTypeChange',
                'updateRelatedRecordsOnChangeLGTeacher','maintenaceLGLesson','createLGPaymentToLG','maintenanceLGPaymentToLGStudents',
                'LG_DeleteGroupIncomePerMonth','reCallTheDiscountLogic','reCreateLGPaymentToLGStudent','LG_RecalcGroup',
                'recreateLGPayment2LGStudentBillingTypeChange'
        	};
    
    public static void DisableSharingMethods(){
    	if(HD_TriggerSettings.disableTriggersFromTest == null){
    		HD_TriggerSettings.disableTriggersFromTest = new Set<String>();
    	}
        HD_TriggerSettings.disableTriggersFromTest.addAll( sharingMethodsNames );
    }
    
    public static void EnableSharingMethods(){
    	if(HD_TriggerSettings.disableTriggersFromTest != null){
        	HD_TriggerSettings.disableTriggersFromTest.removeAll( sharingMethodsNames );
    	}
    }
}