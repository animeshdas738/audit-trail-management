/**
 * @description Test class for DeploymentPackageTriggerHandler
 */
@IsTest
private class DeploymentPackageTriggerHandlerTest {
    
    @IsTest
    static void testBeforeInsert() {
        Deployment_Package__c pkg = new Deployment_Package__c(
            Package_Name__c = 'Test Package',
            Package_XML__c = '<?xml version="1.0" encoding="UTF-8"?><Package xmlns="http://soap.sforce.com/2006/04/metadata"><version>65.0</version></Package>'
        );
        
        Test.startTest();
        insert pkg;
        Test.stopTest();
        
        pkg = [SELECT Version__c FROM Deployment_Package__c WHERE Id = :pkg.Id];
        System.assertEquals('1.0', pkg.Version__c, 'Version should be set to 1.0');
    }
    
    @IsTest
    static void testStatusTransitionValidation() {
        Deployment_Package__c pkg = new Deployment_Package__c(
            Package_Name__c = 'Test Package',
            Status__c = 'Draft'
        );
        insert pkg;
        
        // Valid transition: Draft to Ready
        Test.startTest();
        pkg.Status__c = 'Ready';
        update pkg;
        
        pkg = [SELECT Status__c FROM Deployment_Package__c WHERE Id = :pkg.Id];
        System.assertEquals('Ready', pkg.Status__c, 'Status should be Ready');
        Test.stopTest();
    }
    
    @IsTest
    static void testVersionIncrement() {
        Deployment_Package__c pkg = new Deployment_Package__c(
            Package_Name__c = 'Test Package',
            Status__c = 'Ready',
            Version__c = '1.0'
        );
        insert pkg;
        
        Test.startTest();
        pkg.Status__c = 'Deployed';
        update pkg;
        Test.stopTest();
        
        pkg = [SELECT Version__c FROM Deployment_Package__c WHERE Id = :pkg.Id];
        System.assertEquals('1.1', pkg.Version__c, 'Version should be incremented');
    }
}
