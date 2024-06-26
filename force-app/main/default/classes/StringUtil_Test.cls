@isTest
public with sharing class StringUtil_Test {

    @isTest
    static void RemoveDuplicatesFromStr_test(){

        string semicolonDelimitedStr = 'Sun;Moon;Stars;Sun;Sand;Flowers;Moon;Sand';
        List<String> result = StringUtil.RemoveDuplicatesFromStr(new List<String>{semicolonDelimitedStr});
        Assert.areEqual('Sun;Moon;Stars;Sand;Flowers', result[0]);

    }

}