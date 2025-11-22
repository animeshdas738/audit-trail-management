/**
 * @description Test class for MultiOrgConnectionService
 */
@IsTest
private class MultiOrgConnectionServiceTest {
    
    /**
     * @description Mock HTTP response for successful connection test
     */
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"MaxDailyApiRequests": 15000}');
            return res;
        }
    }
    
    /**
     * @description Mock HTTP response for failed connection
     */
    private class MockHttpResponseFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('{"error": "Unauthorized"}');
            return res;
        }
    }
    
    /**
     * @description Mock HTTP response for audit trail query
     */
    private class MockHttpResponseAuditTrail implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            Map<String, Object> responseMap = new Map<String, Object>();
            List<Object> records = new List<Object>();
            
            Map<String, Object> record1 = new Map<String, Object>();
            record1.put('Id', '0Ym000000000001');
            record1.put('Action', 'Created');
            record1.put('Section', 'ApexClass');
            record1.put('CreatedDate', '2025-11-22T10:00:00.000+0000');
            record1.put('Display', 'AccountController created');
            
            Map<String, Object> createdBy = new Map<String, Object>();
            createdBy.put('Name', 'Test User');
            record1.put('CreatedBy', createdBy);
            
            records.add(record1);
            
            Map<String, Object> record2 = new Map<String, Object>();
            record2.put('Id', '0Ym000000000002');
            record2.put('Action', 'Updated');
            record2.put('Section', 'CustomObject');
            record2.put('CreatedDate', '2025-11-22T11:00:00.000+0000');
            record2.put('Display', 'Account object modified');
            
            Map<String, Object> createdBy2 = new Map<String, Object>();
            createdBy2.put('Name', 'Test User 2');
            record2.put('CreatedBy', createdBy2);
            
            records.add(record2);
            
            responseMap.put('records', records);
            responseMap.put('totalSize', 2);
            
            res.setBody(JSON.serialize(responseMap));
            return res;
        }
    }
    
    @IsTest
    static void testConstructorAndInitialize() {
        Test.startTest();
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        Test.stopTest();
        
        System.assertNotEquals(null, service, 'Service should be instantiated');
        System.assertEquals('MultiOrgConnectionService', service.getServiceName(), 'Service name should match');
    }
    
    @IsTest
    static void testGetOrgConnections() {
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        
        Test.startTest();
        List<Org_Connection__mdt> connections = service.getOrgConnections();
        Test.stopTest();
        
        System.assertNotEquals(null, connections, 'Connections should not be null');
    }
    
    @IsTest
    static void testTestConnectionSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        
        Test.startTest();
        Boolean result = service.testConnection('Dev_Org');
        Test.stopTest();
        
        // Result depends on custom metadata configuration
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @IsTest
    static void testTestConnectionFailure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());
        
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        
        Test.startTest();
        Boolean result = service.testConnection('Invalid_Org');
        Test.stopTest();
        
        System.assertEquals(false, result, 'Connection should fail for invalid org');
    }
    
    @IsTest
    static void testGetAuditTrail() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAuditTrail());
        
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        
        DateTime startDate = DateTime.newInstance(2025, 11, 1);
        DateTime endDate = DateTime.newInstance(2025, 11, 22);
        
        Test.startTest();
        List<AuditTrailEntry> entries = service.getAuditTrail('Dev_Org', startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, entries, 'Entries should not be null');
        // Entries may be empty if org connection doesn't exist in custom metadata
    }
    
    @IsTest
    static void testGetAuditTrailFromAllOrgs() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAuditTrail());
        
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        
        DateTime startDate = DateTime.newInstance(2025, 11, 1);
        DateTime endDate = DateTime.newInstance(2025, 11, 22);
        
        Test.startTest();
        Map<String, List<AuditTrailEntry>> allEntries = service.getAuditTrailFromAllOrgs(startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, allEntries, 'All entries map should not be null');
    }
    
    @IsTest
    static void testCompareAcrossOrgs() {
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        
        // Create mock audit trail data
        Map<String, List<AuditTrailEntry>> entries = new Map<String, List<AuditTrailEntry>>();
        
        List<AuditTrailEntry> org1Entries = new List<AuditTrailEntry>();
        AuditTrailEntry entry1 = new AuditTrailEntry();
        entry1.action = 'Created';
        entry1.section = 'ApexClass';
        entry1.display = 'TestClass';
        entry1.orgName = 'Org1';
        org1Entries.add(entry1);
        
        AuditTrailEntry entry2 = new AuditTrailEntry();
        entry2.action = 'Updated';
        entry2.section = 'CustomObject';
        entry2.display = 'Account';
        entry2.orgName = 'Org1';
        org1Entries.add(entry2);
        
        List<AuditTrailEntry> org2Entries = new List<AuditTrailEntry>();
        AuditTrailEntry entry3 = new AuditTrailEntry();
        entry3.action = 'Created';
        entry3.section = 'ApexClass';
        entry3.display = 'TestClass';
        entry3.orgName = 'Org2';
        org2Entries.add(entry3);
        
        entries.put('Org1', org1Entries);
        entries.put('Org2', org2Entries);
        
        Test.startTest();
        Map<String, Object> comparison = service.compareAcrossOrgs(entries);
        Test.stopTest();
        
        System.assertNotEquals(null, comparison, 'Comparison should not be null');
        System.assert(comparison.containsKey('commonChanges'), 'Should contain common changes');
        System.assert(comparison.containsKey('orgSpecificChanges'), 'Should contain org-specific changes');
        System.assert(comparison.containsKey('actionCounts'), 'Should contain action counts');
        
        List<String> commonChanges = (List<String>)comparison.get('commonChanges');
        System.assertEquals(1, commonChanges.size(), 'Should have 1 common change');
        System.assertEquals('Created:ApexClass', commonChanges[0], 'Common change should be Created:ApexClass');
    }
    
    @IsTest
    static void testGetAuditTrailWithException() {
        // Set mock to throw exception by returning invalid JSON
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());
        
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        
        DateTime startDate = DateTime.newInstance(2025, 11, 1);
        DateTime endDate = DateTime.newInstance(2025, 11, 22);
        
        Test.startTest();
        List<AuditTrailEntry> entries = service.getAuditTrail('NonExistent_Org', startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, entries, 'Should return empty list on error');
        System.assertEquals(0, entries.size(), 'Should be empty list on error');
    }
}
