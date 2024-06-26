/**
* Page : ContentSearch
* Description : This class called from ContentSearch to display all contents with all filters
* Created by: Rekha Jangir @Dec/6/2016
*/
public with sharing class ContentSearchController {
    
    /**
    * Constructor
    */
    public ContentSearchController() {
        
    }
    /**
    * Method to get Libraries
    */
    @RemoteAction
    public static Map<String, String> fetchAllLibrary(){
        Map<String, String> libraries = new Map<String, String>();
        try{
            //get all the available libraries from the org
            for (ContentWorkspace cw: [select Id, name from ContentWorkspace order by Name LIMIT: limits.getLimitQueryRows()]) {
                libraries.put(cw.Id, cw.Name);
            }
        }
        catch(Exception e){
            
        }
        return libraries;
    }
    /**
    * Method to get all records count
    */
    @RemoteAction
    public static Integer fetchAllRecordCount(){
        Integer totalRecordCount;
        try{
            //get all all records count from the org
            AggregateResult ar = [select COUNT(Id)totalCount from ContentVersion];
            totalRecordCount = (integer)ar.get('totalcount');
        }
        catch(Exception e){
            
        }
        return totalRecordCount;
    }
    /**
    * Method to get all language
    */
    @RemoteAction
    public static Map<String, String> fetchAllLanguage(){
        Map<String, String> languageMap = new Map<String, String>();
        try{
            Map<String, Schema.SObjectField> M = Schema.SObjectType.ContentVersion.fields.getMap();
            //check for the multi-lanaguage is enabled or not
            if(M != null && M.containsKey('language')){
                //get all available values of language
                Schema.DescribeFieldResult obj = M.get('language').getDescribe();
                for (Schema.PicklistEntry pe : obj.getPickListValues()) {
                    languageMap.put(pe.getValue(), pe.getLabel());
                }
            }
        }
        catch(Exception e){
            
        }
        return languageMap;
    }
    
    /**
    * Method to get content list
    */
    @RemoteAction
    public static ContainerWrapper contents(string libId, string langId, string inputTextValue, Integer offset){
        List<ContentWrapper> contentWrappers = new List<ContentWrapper>();
        ContainerWrapper contWrapper = new ContainerWrapper();
        try{
            Set<String> contentIds = new Set<String>();
            String searchText = '';
            Content_Search__c cs = Content_Search__c.getOrgDefaults();
            decimal limitSize = (cs != null && cs.Records_Limit__c != null ? cs.Records_Limit__c : 500);
            searchText = string.escapeSingleQuotes(inputTextValue);
            if (searchText.trim() != ''){
                //check if text string is date
                if(searchText.contains('/')) {
                    List<string> dateStr = searchText.split('/');
                    string dateText = '';
                    if(dateStr.size() == 3){
                        
                        try {
                            dateText = integer.valueOf(dateStr[2])+'-'+
                                        (string.valueOf(integer.valueOf(dateStr[1])).length() == 2 ? 
                                        ''+integer.valueOf(dateStr[1]) :
                                        '0'+ integer.valueOf(dateStr[1]))
                                        +'-'+(string.valueOf(integer.valueOf(dateStr[0])).length() == 2 ? 
                                        ''+integer.valueOf(dateStr[0]) :
                                        '0'+ integer.valueOf(dateStr[0]));
                        }
                        catch(Exception e){
                            dateText = '';
                        }
                    }
                    if(dateText != '')
                        searchText = dateText;
                }
                //search for string in content version in all fields and file
                String SOSLQuery = 'FIND \'' + searchText + '*\' IN ALL FIELDS RETURNING ContentVersion(Id)';
                List<List <SObject>> searchList = search.query(SOSLQuery);
                List<ContentVersion> listContentVersion = searchList[0];
                //store all ids of text search result
                for (ContentVersion cv: listContentVersion) {
                    contentIds.add(cv.id);
                }
            }
            
            //generating dynamic query for content version
            String queryString = 'SELECT Id, Title, Description, LastModifiedDate, ' +
                'TagCsv, ContentDocument.ParentId, ContentUrl, ContentDocumentId, RatingCount, ' +
                'FileType, FileExtension, ContentSize, CreatedById, CreatedBy.Name, CreatedDate '; 
            
            //describe content version to get all custom fields and language
            Map<String, Schema.SObjectField> M = Schema.SObjectType.ContentVersion.fields.getMap();
            Map<String, Schema.DescribeFieldResult> customFieldMap = new Map<String, Schema.DescribeFieldResult>();
            Map<String, String> languageMap = new Map<String, String>();
            for (String field : M.keySet()) {
                Schema.DescribeFieldResult obj = M.get(field).getDescribe();
                if (obj.isCustom() || obj.getName() == 'Language') {
                    customFieldMap.put(obj.getName(), obj);
                    queryString += ', ' + obj.getName();
                }
                //get all available languages to bind values with content
                if (obj.getName() == 'Language') {
                    
                    for (Schema.PicklistEntry pe : obj.getPickListValues()) {
                        languageMap.put(pe.getValue(), pe.getLabel());
                    }
                }
            }
            queryString += ' from ContentVersion ';
            
            //in case of text search 
            if (searchText.trim() != '') {
                queryString += ' Where Id IN: contentIds ';
            }
            //when language is searched 
            if (langId != '') {
                queryString += (queryString.contains('Where') ? ' and ' : ' Where ')+' Language = \''+langId+'\'';
            }
            //when library is selected to search
            if(libId != '') {
                if(libId == 'PERSONAL_WORKSPACE')
                    queryString += (queryString.contains('Where') ? ' and ' : ' Where ')+' ContentDocument.ParentId = null';
                else if(libId != 'ALL_WORKSPACES')
                    queryString += (queryString.contains('Where') ? ' and ' : ' Where ')+' ContentDocument.ParentId = \''+libId+'\'';
            }
            queryString += ' ORDER BY LastModifiedDate desc  LIMIT '+integer.valueOf(limitSize)+' OFFSET '+offset;
            system.debug('--------'+queryString);
            //fetch content version
            List<ContentVersion> contents = database.query(queryString);
            
            for (ContentVersion cv : contents) {
                ContentWrapper cw = new ContentWrapper(cv);
                
                for (string field : customFieldMap.keySet()) {
                    //set value and label for picklist fields
                    if (String.valueOf(customFieldMap.get(field).getType()) == 'Picklist' && field == 'Language') {
                        cw.customFields.add( new FieldWrapper(field, customFieldMap.get(field).getLabel(), (cv.get(field) != null ? languageMap.get(String.valueOf(cv.get(field))) : '')));
                    } 
                    //set list of selected values for multipicklist
                    else if(String.valueOf(customFieldMap.get(field).getType()) == 'MultiPicklist'){
                        FieldWrapper fw = new FieldWrapper(field, customFieldMap.get(field).getLabel(), String.valueOf(cv.get(field)));
                        fw.selectedEntries = (cv.get(field) != null ? String.valueOf(cv.get(field)).split(';') : new List<String>());
                        cw.customFields.add(fw);
                    }
                    //set string value for date nad datetime fields
                    else if (String.valueOf(customFieldMap.get(field).getType()) == 'Date' || String.valueOf(customFieldMap.get(field).getType()) == 'DateTime') 
                        cw.customFields.add( new FieldWrapper(field, customFieldMap.get(field).getLabel(), (cv.get(field) != null ? Date.valueOf(cv.get(field)).format() : '')));
                    //set value for other fields
                    else
                        cw.customFields.add( new FieldWrapper(field, customFieldMap.get(field).getLabel(), (cv.get(field) != null ? String.valueOf(cv.get(field)) : '')));
                }
                contWrapper.contents.add(cw);
            }
            //get all all records count from the org
            //AggregateResult ar = [select COUNT(Id)totalCount from ContentVersion];
            //contWrapper.totalRecords = (integer)ar.get('totalcount');
        }
        catch(Exception e){
            contWrapper.error = 'Error: '+e.getMessage();
        }
        return contWrapper;
    }
    public class ContainerWrapper{
        public List<ContentWrapper> contents {get;set;}
        public string error {get;set;}
        public integer totalRecords {get;set;}
        public ContainerWrapper(){
            error = '';
            totalRecords = 0;
            contents = new List<ContentWrapper>();
        }
    }
    
    /**
     * Wrapper class for Content
     */
    public class ContentWrapper {
        public Boolean isSelected {get; set;}
        public String Id {get;set;}
        public Integer rating {get; set;}
        public String fileType {get; set;}
        public String fileExt {get; set;}
        public String title {get; set;}
        public String size {get; set;}
        public decimal sizeByte {get; set;}
        public String authorId {get; set;}
        public String authorName {get; set;}
        public String lastModifiedDate {get; set;}
        public String publicationDate {get; set;}
        public String lastModifiedDateString {get; set;}
        public String publicationDateString {get; set;}
        public string iconClass {get; set;}
        public List<String> tags {get; set;}
        public String description {get; set;}
        public String libraryId {get; set;}
        public String contentDocId {get; set;}
        public List<FieldWrapper> customFields {get; set;}
        public ContentWrapper(ContentVersion cv) {
            this.isSelected = false;
            this.Id = cv.Id;
            this.rating = cv.RatingCount;
            this.fileExt = cv.fileExtension;
            this.title = cv.Title;
            this.sizeByte = cv.ContentSize;
            this.size = '';//getFileSize(cv.ContentSize);
            this.authorId = cv.CreatedById;
            this.authorName = cv.CreatedBy.Name;
            this.lastModifiedDate = cv.LastModifiedDate.format();
            this.lastModifiedDateString = getTimeDifference(cv.LastModifiedDate);
            this.publicationDate = cv.CreatedDate.format();
            this.publicationDateString = getTimeDifference(cv.CreatedDate);
            this.tags = new List<String>();
            if(cv.TagCsv != null && cv.TagCsv != '')
                this.tags = cv.TagCsv.split(',');
            this.description = cv.Description;
            if(cv.ContentDocument.ParentId != null)
                this.libraryId = cv.ContentDocument.ParentId;
            else
                this.libraryId = '';
            this.contentDocId = cv.ContentDocumentId;
            this.customFields = new List<FieldWrapper>();
            this.iconClass = '';//getStyleClass(this.fileExt,cv.FileType);
            this.fileType = cv.FileType;//formatFileType(cv.FileType);
        }
    }
    /**
     * method to format fileType
     */
    /*private static String formatFileType(string fileType){
        if(fileType == 'WORD_X')
            return 'Word 2007';
        if(fileType == 'WORD_M')
            return 'Word 2007 Macro-Enabled';
        if(fileType == 'png')
            return 'Image - png';
        if(fileType == 'gif')
            return 'Image - gif';
        if(fileType == 'jpeg')
            return 'Image - jpeg';
        if(fileType == 'jpg')
            return 'Image - jpg';
        if(fileType == 'UNKNOWN')
            return 'unknown';
        if(fileType == 'EXCEL_X')
            return 'Excel 2007';
        if(fileType == 'RTF')
            return 'Rich Text Format';
        if(fileType == 'MP4')
            return 'Video';
        if(fileType == 'TEXT')
            return 'Plain Text';
        if(fileType == 'PDF')
            return 'Adobe PDF';
        if(fileType == 'POWER_POINT')
            return 'Powerpoint';
        return fileType;
    }*/
    
    /**
     * method to get styleclass according to filetype
     */
    /*private static String getStyleClass(string fileExt, string fileType){
        string iconClass = '';
        if(fileExt == 'docm' && (fileType == 'WORD_X' || fileType == 'WORD_M'))
            iconClass = 'docIcon_16 docIcon sprite-doctype_word_16';
        else if(fileExt == 'png' || fileExt == 'jpeg' || fileExt == 'gif' || fileExt == 'jpg')
            iconClass = 'docIcon_16 docIcon sprite-doctype_image_16';
        else if(fileExt == 'pdf')
            iconClass = 'docIcon_16 docIcon sprite-doctype_pdf_16';
        else if(fileExt == 'mp3' || fileExt == 'wav')
            iconClass = 'docIcon_16 docIcon sprite-doctype_audio_16';
        else if(fileExt == 'txt')
            iconClass = 'docIcon_16 docIcon sprite-doctype_txt_16';
        else if(fileExt == 'mp4')
            iconClass = 'docIcon_16 docIcon sprite-doctype_mp4_16';
        else if(fileExt == 'csv')
            iconClass = 'docIcon_16 docIcon sprite-doctype_csv_16';
        else if(fileExt == 'zip')
            iconClass = 'docIcon_16 docIcon sprite-doctype_zip_16';
        else if(fileExt == 'xml')
            iconClass = 'docIcon_16 docIcon sprite-doctype_xml_16';
        else if(fileExt == 'rtf')
            iconClass = 'docIcon_16 docIcon sprite-doctype_rtf_16';
        else if(fileExt == 'html')
            iconClass = 'docIcon_16 docIcon sprite-doctype_html_16';
        else if(fileExt == 'ppt' && (fileType == 'POWER_POINT' || fileType == 'POWER_POINT_X'))
            iconClass = 'docIcon_16 docIcon sprite-doctype_ppt_16';
        else if(fileExt == 'xlsx' && (fileType == 'EXCEL' || fileType == 'EXCEL_X'))
            iconClass = 'docIcon_16 docIcon sprite-doctype_excel_16';
        else 
            iconClass = 'docIcon_16 docIcon sprite-doctype_unknown_16';
        return iconClass;
    }
    */
    /**
     * method to get time format
     */
    /*private static String getFileSize(decimal ContentSize){
        string size = '';
        if(ContentSize < 1024){
            size = ContentSize.setScale(0)+' B';
        }
        else if (ContentSize >= 1024 && ContentSize < 1048576) {
            size = (ContentSize/1024).setScale(0) +' KB';
        }
        else {
            size = (ContentSize/1048576).setScale(1) + ' MB';
        }
        return size;
    }*/
    
    /**
     * method to get time difference
     */
    private static String getTimeDifference(DateTime date1){
        decimal miliSec = system.now().getTime() - date1.getTime();
        Integer min = Integer.valueOf(miliSec/60000);
        Integer hrs = Integer.valueOf(min/60);
        Integer days = Integer.valueOf(hrs/24);
        String timeDif = ((min == 0 ? '< 1 minute ago' : (min == 1 ? '1 minute ago' : (min < 60 ? min+' minutes ago' : (
                        (hrs == 1 ? '1 hour ago' : (hrs < 24 ? hrs+' hours ago' : (
                        (days == 1 ? '1 day ago' : (days > 1 && days < 7 ? days+' days ago' : 
                        ((days >= 7 && days < 14) ? '1 week ago' : (days >= 14 && days < 28 ? days/7 +' weeks ago' : date1.date().format()))))
                        ))))))));
        return timeDif;
    } 
    /**
     * Wrapper class for Custom Field
     */
    public class FieldWrapper {
        public String name {get; set;}
        public String value {get; set;}
        public String label {get; set;}
        public List<string> selectedEntries{get;set;}
        public FieldWrapper(String name, String label, String value) {
            this.name = name;
            this.value = value;
            this.label = label;
            this.selectedEntries = new List<string>();
        }
    }
    
    /**
    * Method to get display option
    */
    @RemoteAction
    public static DisplayOptionWrapper displayOption() {
        //query for available display option record (not the default)
        List<Display_Option__c> displayOptions = [
            Select id,Selected_Columns__c,
            Result_per_Page__c,Display_Tags__c,Display_Description__c,Display_Location__c 
            From Display_Option__c 
            WHERE Name != 'Default'
            LIMIT 1]; 
        Display_Option__c displayOption;
        
        //set the display options if there is no record (for first time)
        if(displayOptions.size() == 0) {
            displayOption = new Display_Option__c(
                Result_per_Page__c = '20',
                Display_Tags__c = false ,
                Display_Description__c = false,
                Display_Location__c = false,
                Available_Columns__c = 'Publication Date;Rating;',
                Selected_Columns__c = 'Title;Size;Author;Last Modified;'
            );
            displayOptions.add(displayOption);
        } 
        
        DisplayOptionWrapper displayOptionWrapper = 
            new DisplayOptionWrapper(displayOptions[0].Selected_Columns__c.split(';'),
                                     Integer.valueOf(displayOptions[0].Result_per_Page__c),
                                     displayOptions[0].Display_Tags__c,
                                     displayOptions[0].Display_Description__c,
                                     displayOptions[0].Display_Location__c
                                    );
        
        return displayOptionWrapper;
    }
    
    /**
    * Wrapper class for Display Option
    */
    public class DisplayOptionWrapper {
        public List<String> displayHeader{get;set;}
        public Integer resultPerPage{get;set;}
        public Boolean isDisplayedTag{get;set;}
        public Boolean isDisplayedDescription{get;set;}
        public Boolean isDisplayedLocation{get;set;}
        public DisplayOptionWrapper(
            List<String> displayHeader, Integer resultPerPage,
            Boolean isDisplayedTag, Boolean isDisplayedDescription, Boolean isDisplayedLocation) {
                
                this.displayHeader = displayHeader;
                this.resultPerPage = resultPerPage;
                this.isDisplayedTag = isDisplayedTag;
                this.isDisplayedDescription = isDisplayedDescription;
                this.isDisplayedLocation = isDisplayedLocation;
            }
    }
}