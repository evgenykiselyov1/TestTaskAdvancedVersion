/**
 * @description       : This is an apex controller for fileuploader component. 
 *                      Parses JSON file and inserts the records to the database
 * @author            : Ievgen Kyselov
 * @group             : 
 * @last modified on  : 06-01-2023
 * @last modified by  : Ievgen Kyselov
**/
public with sharing class JsonDataUploaderController {

    @AuraEnabled
    public static List<Sobject> saveRecords(String sobjectName, String data) {
        try {
            String fileBodyAsString = EncodingUtil.base64Decode(data).toString();
            List<Sobject> records = setNewRecordsFromJSON(sobjectName, fileBodyAsString);
            Database.SaveResult[] result = Database.insert(records);
            List<String> ids = new List<String>();
            for(Database.SaveResult res: result){
                ids.add(res.getId());
            }
            String queryFields = queryFields(sobjectName, data);
            String queryString = 'SELECT ' + queryFields + ' FROM ' + sobjectName + ' WHERE id IN :ids';
            records = Database.query(queryString);
            return records;
        } catch (Exception ex) {
            String excErrorMessage = ex.getMessage() + ': ' + ex.getStackTraceString();
            throw new AuraHandledException(excErrorMessage);
        }
    }

    @AuraEnabled
    public static List<Sobject> setNewRecordsFromJSON(String sobjectName, String data){
        List<SObject> records = new List<SObject>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap();
        JSONParser parser = JSON.createParser(data);

        while (parser.nextToken() != null) {
            if(string.valueOf(parser.getCurrentToken()) == 'START_OBJECT'){
                SObject obj = Schema.getGlobalDescribe().get(sobjectName).newSObject();
                records.add(obj);
                parser.nextToken();
                while (string.valueOf(parser.getCurrentToken()) != 'END_OBJECT'){
                    parser.nextToken();
                    String field = string.valueOf(parser.getCurrentName());
                    String fieldType = string.valueOf(fieldMap.get(field).getDescribe().getType());
                    switch on fieldType {
                        when 'ID' {
                            obj.put(field, parser.getIdValue());
                        }
                        when 'STRING' {
                            obj.put(field, parser.getText());
                        }
                        when 'DATE' {
                            obj.put(field, parser.getDateValue());
                        }
                        when 'DATETIME' {
                            obj.put(field, parser.getDatetimeValue());
                        }
                        when 'DOUBLE' {
                            obj.put(field, parser.getDoubleValue());
                        }
                        when 'BOOLEAN' {
                            obj.put(field, parser.getBooleanValue());
                        }
                        when else {
                            obj.put(field, parser.getText());
                        }
                    }
                    parser.nextToken();
                }
            }
        }
        return records;
    }

    @AuraEnabled(cacheable=true)
    public static String setColumnsFromJSON(String sobjectName, String data){
        try {
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap();
            String fileBodyAsString = EncodingUtil.base64Decode(data).toString();
            JSONParser parser = JSON.createParser(fileBodyAsString);
            Map<String, Column> columns = new Map<String, Column>();
            while (parser.nextToken() != null) {
                if(string.valueOf(parser.getCurrentToken()) == 'START_OBJECT'){
                    parser.nextToken();
                    while (string.valueOf(parser.getCurrentToken()) != 'END_OBJECT'){
                        parser.nextToken();
                        Column col = new Column();
                        col.name = string.valueOf(parser.getCurrentName());
                        col.label = string.valueOf(fieldMap.get(col.name).getDescribe().getLabel());
                        col.type = string.valueOf(fieldMap.get(col.name).getDescribe().getType());
                        columns.put(col.name, col);
                        parser.nextToken();
                    }
                }
            }
            String colSet = JSON.serialize(columns.values());
            return colSet;
        } catch (Exception ex) {
            String excErrorMessage = ex.getMessage() + ': ' + ex.getStackTraceString();
            throw new AuraHandledException(excErrorMessage);
        }
    }

    public static String queryFields(String sobjectName, String data){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap();
        String fileBodyAsString = EncodingUtil.base64Decode(data).toString();
        JSONParser parser = JSON.createParser(fileBodyAsString);
        Set<String> columns = new Set<String>();
        while (parser.nextToken() != null) {
            if(string.valueOf(parser.getCurrentToken()) == 'START_OBJECT'){
                parser.nextToken();
                while (string.valueOf(parser.getCurrentToken()) != 'END_OBJECT'){
                    parser.nextToken();
                    columns.add(string.valueOf(parser.getCurrentName()));
                    parser.nextToken();
                }
            }
        }
        string allColumns = string.join(new List<String>(columns),',');
        return allColumns;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,String> getEntityDefinitions(){
        Map<String,String> availableObjects = new Map<String,String>();
        for (EntityDefinition entity : [SELECT Label, QualifiedApiName 
                                        FROM EntityDefinition 
                                        WHERE IsCustomizable = true]) {
            availableObjects.put(entity.QualifiedApiName, entity.Label);
        }
        return availableObjects;
    }

    public class Column {
        public String name;
        public String label;
        public String type;
    }

}