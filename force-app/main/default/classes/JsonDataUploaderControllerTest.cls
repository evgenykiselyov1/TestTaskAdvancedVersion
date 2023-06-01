/**
 * @description       : This is an apex test Class for apex controller of the fileuploader component. 
 * @author            : Ievgen Kyselov
 * @group             : 
 * @last modified on  : 06-01-2023
 * @last modified by  : Ievgen Kyselov
**/
@isTest
public with sharing class JsonDataUploaderControllerTest {
    @isTest
    public static void saveRecordsTest() {
        //Given
        String testData = '['+
            '{'+
            '"Carrier_File_Code__c" : 10001,'+
            '"Insured_Name__c" : "Michael Gauss",'+
            '"LOB__c" : "AUTOP",'+
            '"Policy_Effective_Date__c" : "2023-05-22",'+
            '"Policy_Number__c" : 100000000001,'+
            '"Premium__c" : 101,'+
            '"Transaction_Code__c" : "BOE"'+
            '},'+
            '{'+
            '"Carrier_File_Code__c" : 10022,'+
            '"Insured_Name__c" : "Eric Pasqal",'+
            '"LOB__c" : "AUTOP",'+
            '"Policy_Effective_Date__c" : "2023-05-22",'+
            '"Policy_Number__c" : 100000000022,'+
            '"Premium__c" : 111,'+
            '"Transaction_Code__c" : "BRF"'+
            '}'+
        ']';
        Blob testDataBlob = Blob.valueof(testData);
        String fileBodyEncoded = EncodingUtil.base64Encode(testDataBlob);
        //When
        List<Policy_Transaction_Exception_Management__c> objects = JsonDataUploaderController.saveRecords('Policy_Transaction_Exception_Management__c', fileBodyEncoded);
        //Then
        System.assertEquals(2, objects.size());
    }

    @isTest
    public static void setColumnsFromJSONTest() {
        //Given
        String testData = '['+
            '{'+
            '"Carrier_File_Code__c" : 10001,'+
            '"Insured_Name__c" : "Michael Gauss",'+
            '"LOB__c" : "AUTOP",'+
            '"Policy_Effective_Date__c" : "2023-05-22",'+
            '"Policy_Number__c" : 100000000001,'+
            '"Premium__c" : 101,'+
            '"Transaction_Code__c" : "BOE"'+
            '},'+
            '{'+
            '"Carrier_File_Code__c" : 10022,'+
            '"Insured_Name__c" : "Eric Pasqal",'+
            '"LOB__c" : "AUTOP",'+
            '"Policy_Effective_Date__c" : "2023-05-22",'+
            '"Policy_Number__c" : 100000000022,'+
            '"Premium__c" : 111,'+
            '"Transaction_Code__c" : "BRF"'+
            '}'+
        ']';
        Blob testDataBlob = Blob.valueof(testData);
        String fileBodyEncoded = EncodingUtil.base64Encode(testDataBlob);
        //When
        String columnsAsString = JsonDataUploaderController.setColumnsFromJSON('Policy_Transaction_Exception_Management__c', fileBodyEncoded);
        List<Object> columns = (List<Object>) JSON.deserializeUntyped(columnsAsString);
        //Then
        System.assertEquals(7, columns.size());
    }    

    @isTest
    public static void getEntityDefinitionsTest() {
        //Given
        List<EntityDefinition> edefs = [SELECT Label, QualifiedApiName FROM EntityDefinition WHERE IsCustomizable = true];
        //When
        Map<String,String> availableObjects = JsonDataUploaderController.getEntityDefinitions();
        //Then
        System.assertEquals(edefs.size(), availableObjects.size());
    }
    
}