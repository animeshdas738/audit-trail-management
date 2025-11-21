/**
 * @description Controller for Deployment History
 */
public with sharing class DeploymentHistoryController {
    
    /**
     * @description Gets all deployment packages
     * @return List of deployment packages
     */
    @AuraEnabled(cacheable=true)
    public static List<Deployment_Package__c> getDeploymentPackages() {
        return [
            SELECT Id, Name, Package_Name__c, Status__c, Version__c, 
                   Target_Org__c, Component_Count__c, Package_XML__c, CreatedDate
            FROM Deployment_Package__c
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }
    
    /**
     * @description Gets deployment package details
     * @param packageId Package Id
     * @return Deployment package with components
     */
    @AuraEnabled
    public static Deployment_Package__c getPackageDetails(Id packageId) {
        return [
            SELECT Id, Name, Package_Name__c, Status__c, Version__c, 
                   Target_Org__c, Description__c, Package_XML__c, Component_Count__c,
                   CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                   (SELECT Component_Type__c, Component_Name__c, Source_Org__c 
                    FROM Deployment_Components__r 
                    ORDER BY Component_Type__c, Component_Name__c)
            FROM Deployment_Package__c
            WHERE Id = :packageId
        ];
    }
}
