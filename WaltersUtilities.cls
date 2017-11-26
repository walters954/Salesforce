/*
* Developer: Warren Walters
* Email: walters954@outlook.com
* Date: 11/17/2017
*/

public class WaltersUtilities {
    
    // Given a list of sobject return all the ids in a list
    // https://developer.salesforce.com/forums/?id=906F00000008oGJIAY
    public static List<id> getSObjectIds(sObject[] sList)
    {
        return new List<Id>(new Map<Id, sObject>(sList).keySet());
    }
    
    //Querying all fields on a specific object 
    //Example queryAllFields(Account.sObjectType, '', '');
    public static List<SObject> queryAllFields(Schema.SObjectType objectToken, String realtedFields, String whereClause){        
        //Describe the object token
        //Enables us to get all the field names on the object
        DescribeSObjectResult describeResult = objectToken.getDescribe();
        
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        
        //String query joining all of the fields that are on the objet
        //Along with the additional passed criteria         
        String query =
            ' SELECT ' +
            String.join( fieldNames, ',' )  + realtedFields +
            ' FROM ' +
            describeResult.getName() +
            whereClause;
        
        // return generic list of sobjects or typecast to expected type
        List<SObject> records = Database.query(query);
        return records;
        
    }
    
    //Gets all recordtypes of a specific sobject and returns that as map with developername as the key
    public static Map<String,RecordType> getRecordTypeMap(Boolean recordTypeIsActive, String sObjectType){
        Map<String,RecordType> tempMap = new Map<String,RecordType>();
        //Query record type and push to map using developer name as the key
        for (RecordType rt : [SELECT id, Name, DeveloperName, SobjectType FROM RecordType WHERE IsActive = :recordTypeIsActive and sObjectType = :sObjectType])
        {
            tempMap.put(rt.DeveloperName,rt);
        }
        return tempMap;
    }
    
    //Return the object name based on the first 3 characters in the record id
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix)
    {
        String objectName = 'No Object Found';
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
            
            //Get schema information
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe();
            
            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                //System.debug('Prefix is ' + prefix);
                
                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        return objectName;
    }
    
    //Given group id return user ids
    //This may cause recursion 
    //https://developer.salesforce.com/forums/?id=906F00000008yBGIAY
    public static Set<id> getUserIdsFromGroup(Set<Id> groupIds)
    {
        // store the results in a set so we don't get duplicates
        Set<Id> result = new Set<Id>();
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        Set<Id> groupIdProxys = new Set<Id>();
        // Loop through all group members in a group
        for(GroupMember m : [Select Id, UserOrGroupId, Group.Type, Group.RelatedId From GroupMember Where GroupId in :groupIds])
        {
            // If the user or group id is a user
            if(((String)m.UserOrGroupId).startsWith(userType))
            {
                result.add(m.UserOrGroupId);
            }
            // If the user or group id is a group
            // Note: there may be a problem with governor limits if this is called too many times
            else if (((String)m.UserOrGroupId).startsWith(groupType))
            {
                // Call this function again but pass in the group found within this group
                groupIdProxys.add(m.userOrGroupId);
                
            }
        }
        if(groupIdProxys.size() > 0)
        {
            Set<id> groupId = new set<id>();
            Set<id> roleId = new set<id>();
            Set<id> roleAndSubId = new set<Id>();
            
            for(Group g2 : [Select Id, Type, relatedId From Group Where Id = :groupIdProxys]){
                if(g2.Type == 'Role'){
                    roleId.add(g2.relatedId);
                }
                else if(g2.Type== 'RoleAndSubordinates'){
                    roleAndSubId.add(g2.relatedId);
                }
                else if(g2.Type== 'PRMOrganization'){
                    roleId.add(g2.relatedId);
                }
                else if(g2.Type== 'Regular'){
                    groupId.add(g2.id);
                }
            }
            if(roleAndSubId.size()>0){
                roleId.addAll(getAllSubRoleIds(roleAndSubId));
            }
            if(roleId.size()>0){
                for(User u: [select id from user where UserRoleId IN: roleId]){
                    result.add(u.id);
                }
            }
            if(groupId.size()>0){
                for(GroupMember gm : [select id, UserOrGroupId from GroupMember where GroupId IN: groupId]){
                    result.add(gm.UserOrGroupId);
                }
            }
        }
        return result;
    }
    
    public static Set<ID> getAllSubRoleIds(Set<ID> roleIds)
    {
        
        Set<ID> currentRoleIds = new Set<ID>();
        
        // get all of the roles underneath the passed roles
        for(UserRole userRole :[select Id from UserRole where ParentRoleId IN :roleIds AND ParentRoleID != null limit 40000])
            currentRoleIds.add(userRole.Id);
        
        // go fetch some more rolls!
        if(currentRoleIds.size() > 0)
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        
        return currentRoleIds;
    }
    
    //given a list of sobject convert that list into a map using the passed string 
    /*public static Map<String,sObject> convertListToFieldMap(String fieldThatWillBeKey, sObject[] listToMap){
        return new Map<String,sObject>();
    }*/
    
    //Given object schema type return list of all field api names
    public static String getAPILabelMap(){
        Map<String,String> fieldMapReturn = new Map<String,String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Compensation_Grid__c.fields.getMap();
        
        for (String fieldName: fieldMap.keySet()) {
            //It provides to get the object fields data type.
            system.debug(fieldMap.get(fieldName).getDescribe().getLabel() + '  ---  ' + fieldMap.get(fieldName));
            fieldMapReturn.put(''+fieldMap.get(fieldName),fieldMap.get(fieldName).getDescribe().getLabel());
        }
        return JSON.serialize(fieldMapReturn);
    }
}