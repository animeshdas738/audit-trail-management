/**
 * @description Test class for Controllers
 */
@IsTest
private class ControllerTest {
    
    @IsTest
    static void testOrgConnectionController() {
        Test.startTest();
        List<Org_Connection__mdt> connections = OrgConnectionController.getOrgConnections();
        Test.stopTest();
        
        System.assertNotEquals(null, connections, 'Connections should not be null');
    }
    
    @IsTest
    static void testComponentAnalysisController() {
        List<AuditTrailEntry> entries = new List<AuditTrailEntry>();
        AuditTrailEntry entry = new AuditTrailEntry();
        entry.display = 'Test';
        entry.section = 'ApexClass';
        entries.add(entry);
        
        String entriesJson = JSON.serialize(entries);
        
        Test.startTest();
        List<ComponentMetadata> components = ComponentAnalysisController.analyzeComponents(entriesJson);
        Test.stopTest();
        
        System.assertNotEquals(null, components, 'Components should not be null');
    }
    
    @IsTest
    static void testPackageGenerationController() {
        List<ComponentMetadata> components = new List<ComponentMetadata>();
        ComponentMetadata comp = new ComponentMetadata();
        comp.componentType = 'ApexClass';
        comp.componentName = 'TestClass';
        components.add(comp);
        
        String componentsJson = JSON.serialize(components);
        
        Test.startTest();
        String packageXml = PackageGenerationController.generatePackageXml(componentsJson, '65.0');
        
        Id packageId = PackageGenerationController.createDeploymentPackage(
            'Test Package',
            packageXml,
            'Test Org',
            'Description',
            '1.0',
            componentsJson
        );
        Test.stopTest();
        
        System.assertNotEquals(null, packageXml, 'Package XML should not be null');
        System.assertNotEquals(null, packageId, 'Package ID should not be null');
    }
    
    @IsTest
    static void testDeploymentHistoryController() {
        Deployment_Package__c pkg = new Deployment_Package__c(
            Package_Name__c = 'Test Package',
            Status__c = 'Draft'
        );
        insert pkg;
        
        Test.startTest();
        List<Deployment_Package__c> packages = DeploymentHistoryController.getDeploymentPackages();
        Deployment_Package__c details = DeploymentHistoryController.getPackageDetails(pkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, packages, 'Packages should not be null');
        System.assertEquals(pkg.Id, details.Id, 'Package details should match');
    }
}
