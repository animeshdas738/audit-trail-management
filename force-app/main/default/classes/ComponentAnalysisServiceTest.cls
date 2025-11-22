/**
 * @description Test class for ComponentAnalysisService
 */
@IsTest
private class ComponentAnalysisServiceTest {
    
    @IsTest
    static void testParseAuditTrailEntry() {
        ComponentAnalysisService service = new ComponentAnalysisService();
        
        AuditTrailEntry entry = new AuditTrailEntry();
        entry.id = '001';
        entry.action = 'Created';
        entry.section = 'ApexClass';
        entry.display = 'AccountController created';
        entry.orgName = 'Test Org';
        entry.createdBy = 'Test User';
        entry.createdDate = DateTime.now();
        
        ComponentMetadata component = service.parseAuditTrailEntry(entry);
        
        System.assertNotEquals(null, component, 'Component should not be null');
        System.assertEquals('Test Org', component.sourceOrg, 'Source org should match');
    }
    
    @IsTest
    static void testAnalyzeAuditTrail() {
        ComponentAnalysisService service = new ComponentAnalysisService();
        
        List<AuditTrailEntry> entries = new List<AuditTrailEntry>();
        
        AuditTrailEntry entry1 = new AuditTrailEntry();
        entry1.id = '001';
        entry1.display = 'Test Component 1';
        entry1.section = 'ApexClass';
        entries.add(entry1);
        
        AuditTrailEntry entry2 = new AuditTrailEntry();
        entry2.id = '002';
        entry2.display = 'Test Component 2';
        entry2.section = 'CustomObject';
        entries.add(entry2);
        
        List<ComponentMetadata> components = service.analyzeAuditTrail(entries);
        
        System.assertEquals(2, components.size(), 'Should have 2 components');
    }
    
    @IsTest
    static void testCategorizeComponents() {
        ComponentAnalysisService service = new ComponentAnalysisService();
        
        List<ComponentMetadata> components = new List<ComponentMetadata>();
        
        ComponentMetadata comp1 = new ComponentMetadata();
        comp1.componentType = 'ApexClass';
        comp1.componentName = 'TestClass1';
        components.add(comp1);
        
        ComponentMetadata comp2 = new ComponentMetadata();
        comp2.componentType = 'ApexClass';
        comp2.componentName = 'TestClass2';
        components.add(comp2);
        
        ComponentMetadata comp3 = new ComponentMetadata();
        comp3.componentType = 'CustomObject';
        comp3.componentName = 'TestObject__c';
        components.add(comp3);
        
        Map<String, List<ComponentMetadata>> categorized = service.categorizeComponents(components);
        
        System.assertEquals(2, categorized.size(), 'Should have 2 categories');
        System.assertEquals(2, categorized.get('ApexClass').size(), 'ApexClass should have 2 components');
        System.assertEquals(1, categorized.get('CustomObject').size(), 'CustomObject should have 1 component');
    }
}
