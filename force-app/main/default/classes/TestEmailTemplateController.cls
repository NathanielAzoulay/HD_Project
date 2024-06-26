public without sharing class TestEmailTemplateController {

    public EmailTemplate et2 {get; set;}
    private String startTemplate;
    private String endTemplate;

    public PageReference doInit(){
    
        String template = 'test_Student_Welcome_Email';
        EmailTemplate et = [SELECT  e.TemplateType, e.TemplateStyle, e.Subject, e.OwnerId, e.NamespacePrefix, e.Name, e.Markup, e.IsActive, e.HtmlValue, e.FolderId, e.Encoding, e.DeveloperName, e.Description, e.BrandTemplateId, e.Body, e.ApiVersion FROM EmailTemplate e WHERE DeveloperName = :template];
        
        system.debug(et);
        //et.subject = 'Welcome {!Contact.Name}';
        //update et;
        
        et2 = et.clone(false, true);
        et2.DeveloperName = et2.DeveloperName + '_Clone' + system.now().second() + system.now().minute();
        et2.Name = et2.Name + 'Clone';
        insert et2;     
        
        startTemplate = et.HtmlValue.substring(0,et.HtmlValue.indexOf('<![CDATA['));
        endTemplate = et.HtmlValue.substring(et.HtmlValue.indexOf(']]>')+3);
        
        String bodydata = et.HtmlValue.substring(et.HtmlValue.indexOf('<![CDATA['),et.HtmlValue.indexOf(']]>')+3);
        et2.htmlvalue = bodydata.replace('<![CDATA[', '');
        et2.htmlvalue = bodydata.replace(']]>', '');
        
        return null;   
    }    
    
    public PageReference doSave(){
        
        system.debug('et2.htmlvalue: ' + et2.htmlvalue);
        
        et2.htmlvalue = et2.htmlvalue.replace('<remove id="startid"></remove>', '<![CDATA[');
        et2.htmlvalue = et2.htmlvalue.replace('<remove id="endid"></remove>', ']]>');

        system.debug('et2.htmlvalue: ' + et2.htmlvalue);
                
        update new EmailTemplate(id = et2.Id, htmlValue= startTemplate + '<![CDATA[' +et2.htmlvalue + ']]>' + endTemplate);
        
        return null;
    }
}