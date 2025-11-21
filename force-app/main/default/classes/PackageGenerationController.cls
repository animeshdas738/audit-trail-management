/**
 * @description Controller for Package Generation
 */
public with sharing class PackageGenerationController {
    
    /**
     * @description Generates package XML
     * @param componentsJson Components JSON
     * @param apiVersion API version
     * @return String package XML
     */
    @AuraEnabled
    public static String generatePackageXml(String componentsJson, String apiVersion) {
        List<ComponentMetadata> components = (List<ComponentMetadata>)JSON.deserialize(componentsJson, List<ComponentMetadata>.class);
        PackageGenerationService service = new PackageGenerationService();
        return service.generatePackageXml(components, apiVersion);
    }
    
    /**
     * @description Creates deployment package
     * @param packageName Package name
     * @param packageXml Package XML content
     * @param targetOrg Target org
     * @param description Description
     * @param version Version
     * @param componentsJson Components JSON
     * @return Id of created package
     */
    @AuraEnabled
    public static Id createDeploymentPackage(
        String packageName,
        String packageXml,
        String targetOrg,
        String description,
        String version,
        String componentsJson
    ) {
        PackageGenerationService service = new PackageGenerationService();
        
        Deployment_Package__c pkg = service.createDeploymentPackage(
            packageName,
            packageXml,
            targetOrg,
            description,
            version
        );
        
        // Add components
        List<ComponentMetadata> components = (List<ComponentMetadata>)JSON.deserialize(componentsJson, List<ComponentMetadata>.class);
        service.addComponentsToPackage(pkg.Id, components);
        
        return pkg.Id;
    }
    
    /**
     * @description Gets package templates
     * @return List of package templates
     */
    @AuraEnabled(cacheable=true)
    public static List<Package_Template__mdt> getPackageTemplates() {
        return [
            SELECT Id, DeveloperName, MasterLabel, Template_Name__c, 
                   API_Version__c, Included_Types__c, Excluded_Types__c
            FROM Package_Template__mdt
        ];
    }
}
