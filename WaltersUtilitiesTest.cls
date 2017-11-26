@isTest
public class WaltersUtilitiesTest {
    @isTest (SeeAllData=true)
    static void testWithAllDataAccess() {
        // Can query all data in the organization.
        Set<id> uIDSet =  WaltersUtilities.GetUserIdsFromGroup(new Set<id>{[SELECT id FROM Group
                                                                            WHERE Name = 'System Admin Email'].id});
        System.assert(uIdSet.size() > 0);
        uIDSet =  WaltersUtilities.GetUserIdsFromGroup(new Set<id>{[SELECT id FROM Group
                                                                    WHERE Name = 'All PMs'].id});
        System.assert(uIdSet.size() > 0);
        
    }
    @isTest
    static void testGetObjId(){
        Account[] acctList = new List <Account>();
        for (Integer x=0; x < 10; x ++)
        {
            acctList.add(new Account(Name = 'Test Acc'+x,Specialty_Type__c = 'Anesthesia', RecordTypeId = [SELECT id FROM RecordType WHERE sObjectType = 'Account' AND name = 'Program' LIMIT 1].id));
        }
        insert acctList;
        acctList = [SELECT id FROM Account];
        System.assert(String.join( WaltersUtilities.getSObjectIds(acctList),',').contains(acctList.get(0).id));
    }
    
    public static testmethod void testAPIMap(){
        WaltersUtilities.getAPILabelMap();
    }
    
    public static testmethod void testPrefixFind(){
        WaltersUtilities.findObjectNameFromRecordIdPrefix('001');
    }
    
    public static testmethod void testRecordTypeMap(){
        WaltersUtilities.getRecordTypeMap(TRUE, 'Account');
    }
    
    public static testmethod void testSubRole(){
        WaltersUtilities.getAllSubRoleIds(new Set<ID>{[SELECT id FROM UserRole LIMIT 1].id});
    }
    
    public static testmethod void testQueryAll(){
        WaltersUtilities.queryAllFields(Account.sObjectType, '', '');
    }
    
}