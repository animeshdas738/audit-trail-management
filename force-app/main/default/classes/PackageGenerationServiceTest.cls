/**
 * @description Test class for PackageGenerationService
 */
@IsTest
private class PackageGenerationServiceTest {
    
    @IsTest
    static void testGeneratePackageXml() {
        PackageGenerationService service = new PackageGenerationService();
        
        List<ComponentMetadata> components = new List<ComponentMetadata>();
        
        ComponentMetadata comp1 = new ComponentMetadata();
        comp1.componentType = 'ApexClass';
        comp1.componentName = 'TestClass';
        components.add(comp1);
        
        ComponentMetadata comp2 = new ComponentMetadata();
        comp2.componentType = 'CustomObject';
        comp2.componentName = 'TestObject__c';
        components.add(comp2);
        
        String packageXml = service.generatePackageXml(components, '65.0');
        
        System.assertNotEquals(null, packageXml, 'Package XML should not be null');
        System.assert(packageXml.contains('<?xml version'), 'Should contain XML declaration');
        System.assert(packageXml.contains('<Package'), 'Should contain Package element');
        System.assert(packageXml.contains('TestClass'), 'Should contain TestClass');
        System.assert(packageXml.contains('TestObject__c'), 'Should contain TestObject__c');
    }
    
    @IsTest
    static void testCreateDeploymentPackage() {
        PackageGenerationService service = new PackageGenerationService();
        
        String packageXml = '<?xml version="1.0"?><Package></Package>';
        
        Test.startTest();
        Deployment_Package__c pkg = service.createDeploymentPackage(
            'Test Package',
            packageXml,
            'Test Org',
            'Test Description',
            '1.0'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, pkg.Id, 'Package should be created');
        System.assertEquals('Test Package', pkg.Package_Name__c, 'Package name should match');
        System.assertEquals('Draft', pkg.Status__c, 'Status should be Draft');
    }
    
    @IsTest
    static void testAddComponentsToPackage() {
        PackageGenerationService service = new PackageGenerationService();
        
        Deployment_Package__c pkg = new Deployment_Package__c(
            Package_Name__c = 'Test Package',
            Status__c = 'Draft'
        );
        insert pkg;
        
        List<ComponentMetadata> components = new List<ComponentMetadata>();
        ComponentMetadata comp1 = new ComponentMetadata();
        comp1.componentType = 'ApexClass';
        comp1.componentName = 'TestClass';
        comp1.sourceOrg = 'Test Org';
        components.add(comp1);
        
        Test.startTest();
        service.addComponentsToPackage(pkg.Id, components);
        Test.stopTest();
        
        List<Deployment_Component__c> insertedComponents = [
            SELECT Id, Component_Type__c, Component_Name__c
            FROM Deployment_Component__c
            WHERE Deployment_Package__c = :pkg.Id
        ];
        
        System.assertEquals(1, insertedComponents.size(), 'Should have 1 component');
        System.assertEquals('ApexClass', insertedComponents[0].Component_Type__c, 'Type should match');
    }
    
    @IsTest
    static void testGenerateRollbackPackage() {
        PackageGenerationService service = new PackageGenerationService();
        
        Deployment_Package__c originalPkg = new Deployment_Package__c(
            Package_Name__c = 'Original Package',
            Status__c = 'Deployed',
            Version__c = '1.0',
            Target_Org__c = 'Test Org'
        );
        insert originalPkg;
        
        Test.startTest();
        Deployment_Package__c rollbackPkg = service.generateRollbackPackage(originalPkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, rollbackPkg.Id, 'Rollback package should be created');
        System.assert(rollbackPkg.Package_Name__c.contains('Rollback'), 'Name should contain Rollback');
    }
}
