/**
 * @description Service for generating package.xml files
 * Supports versioning, templates, and selective component inclusion
 */
public class PackageGenerationService extends BaseService {
    private ConfigurationManager configManager;
    private static final String DEFAULT_API_VERSION = '65.0';
    
    /**
     * @description Constructor
     */
    public PackageGenerationService() {
        super('PackageGenerationService');
    }
    
    /**
     * @description Initialize service
     */
    protected override void initialize() {
        this.configManager = ConfigurationManager.getInstance();
        super.initialize();
    }
    
    /**
     * @description Generates package.xml from component list
     * @param components List of components to include
     * @param apiVersion API version (optional)
     * @return String package.xml content
     */
    public String generatePackageXml(List<ComponentMetadata> components, String apiVersion) {
        if (String.isBlank(apiVersion)) {
            apiVersion = DEFAULT_API_VERSION;
        }
        
        // Group components by type
        Map<String, List<String>> componentsByType = new Map<String, List<String>>();
        
        for (ComponentMetadata component : components) {
            if (!componentsByType.containsKey(component.componentType)) {
                componentsByType.put(component.componentType, new List<String>());
            }
            
            // Add unique component names
            List<String> names = componentsByType.get(component.componentType);
            if (!names.contains(component.componentName)) {
                names.add(component.componentName);
            }
        }
        
        // Generate XML
        return this.buildPackageXml(componentsByType, apiVersion);
    }
    
    /**
     * @description Builds package.xml content
     * @param componentsByType Map of component type to names
     * @param apiVersion API version
     * @return String package.xml content
     */
    private String buildPackageXml(Map<String, List<String>> componentsByType, String apiVersion) {
        List<String> xmlLines = new List<String>();
        
        xmlLines.add('<?xml version="1.0" encoding="UTF-8"?>');
        xmlLines.add('<Package xmlns="http://soap.sforce.com/2006/04/metadata">');
        
        // Sort types alphabetically for consistency
        List<String> sortedTypes = new List<String>(componentsByType.keySet());
        sortedTypes.sort();
        
        for (String componentType : sortedTypes) {
            xmlLines.add('    <types>');
            
            List<String> members = componentsByType.get(componentType);
            members.sort();
            
            for (String member : members) {
                xmlLines.add('        <members>' + this.escapeXml(member) + '</members>');
            }
            
            xmlLines.add('        <name>' + this.escapeXml(componentType) + '</name>');
            xmlLines.add('    </types>');
        }
        
        xmlLines.add('    <version>' + apiVersion + '</version>');
        xmlLines.add('</Package>');
        
        return String.join(xmlLines, '\n');
    }
    
    /**
     * @description Escapes XML special characters
     * @param text Text to escape
     * @return String escaped text
     */
    private String escapeXml(String text) {
        if (String.isBlank(text)) {
            return text;
        }
        
        return text.replace('&', '&amp;')
                   .replace('<', '&lt;')
                   .replace('>', '&gt;')
                   .replace('"', '&quot;')
                   .replace('\'', '&apos;');
    }
    
    /**
     * @description Generates package.xml using a template
     * @param templateName Template developer name
     * @param components List of components
     * @return String package.xml content
     */
    public String generateFromTemplate(String templateName, List<ComponentMetadata> components) {
        Package_Template__mdt template = this.configManager.getPackageTemplate(templateName);
        
        if (template == null) {
            this.logError('Template not found: ' + templateName, null);
            return this.generatePackageXml(components, DEFAULT_API_VERSION);
        }
        
        // Filter components based on template
        List<ComponentMetadata> filteredComponents = this.filterComponents(components, template);
        
        return this.generatePackageXml(filteredComponents, template.API_Version__c);
    }
    
    /**
     * @description Filters components based on template configuration
     * @param components List of components
     * @param template Package template
     * @return List of filtered components
     */
    private List<ComponentMetadata> filterComponents(List<ComponentMetadata> components, Package_Template__mdt template) {
        Set<String> includedTypes = this.parseTypeList(template.Included_Types__c);
        Set<String> excludedTypes = this.parseTypeList(template.Excluded_Types__c);
        
        List<ComponentMetadata> filtered = new List<ComponentMetadata>();
        
        for (ComponentMetadata component : components) {
            Boolean shouldInclude = true;
            
            // Check inclusion list (if specified)
            if (!includedTypes.isEmpty() && !includedTypes.contains(component.componentType)) {
                shouldInclude = false;
            }
            
            // Check exclusion list
            if (excludedTypes.contains(component.componentType)) {
                shouldInclude = false;
            }
            
            if (shouldInclude) {
                filtered.add(component);
            }
        }
        
        this.logInfo('Filtered ' + components.size() + ' components to ' + filtered.size() + ' using template');
        return filtered;
    }
    
    /**
     * @description Parses comma-separated list of types
     * @param typeList Comma-separated list
     * @return Set of types
     */
    private Set<String> parseTypeList(String typeList) {
        Set<String> types = new Set<String>();
        
        if (String.isNotBlank(typeList)) {
            for (String type : typeList.split(',')) {
                types.add(type.trim());
            }
        }
        
        return types;
    }
    
    /**
     * @description Creates deployment package record
     * @param packageName Name of package
     * @param packageXml Package.xml content
     * @param targetOrg Target org
     * @param description Description
     * @param version Version
     * @return Deployment_Package__c record
     */
    public Deployment_Package__c createDeploymentPackage(
        String packageName,
        String packageXml,
        String targetOrg,
        String description,
        String version
    ) {
        Deployment_Package__c pkg = new Deployment_Package__c(
            Package_Name__c = packageName,
            Package_XML__c = packageXml,
            Target_Org__c = targetOrg,
            Description__c = description,
            Version__c = version,
            Status__c = 'Draft'
        );
        
        insert pkg;
        
        this.logInfo('Created deployment package: ' + pkg.Name);
        return pkg;
    }
    
    /**
     * @description Adds components to deployment package
     * @param packageId Deployment package Id
     * @param components List of components
     */
    public void addComponentsToPackage(Id packageId, List<ComponentMetadata> components) {
        List<Deployment_Component__c> componentRecords = new List<Deployment_Component__c>();
        
        for (ComponentMetadata component : components) {
            // Skip components without required fields
            if (String.isBlank(component.componentType) || String.isBlank(component.componentName)) {
                this.logError('Skipping component with missing type or name: ' + JSON.serialize(component), null);
                continue;
            }
            
            componentRecords.add(new Deployment_Component__c(
                Deployment_Package__c = packageId,
                Component_Type__c = component.componentType,
                Component_Name__c = component.componentName,
                Source_Org__c = component.sourceOrg
            ));
        }
        
        if (!componentRecords.isEmpty()) {
            insert componentRecords;
            this.logInfo('Added ' + componentRecords.size() + ' components to package');
        } else {
            this.logError('No valid components to add to package', null);
        }
    }
    
    /**
     * @description Generates rollback package for a deployment
     * @param originalPackageId Original deployment package Id
     * @return Deployment_Package__c rollback package
     */
    public Deployment_Package__c generateRollbackPackage(Id originalPackageId) {
        Deployment_Package__c originalPkg = [
            SELECT Package_Name__c, Target_Org__c, Version__c
            FROM Deployment_Package__c
            WHERE Id = :originalPackageId
            LIMIT 1
        ];
        
        // Create rollback package with destructive changes
        Deployment_Package__c rollbackPkg = new Deployment_Package__c(
            Package_Name__c = originalPkg.Package_Name__c + ' - Rollback',
            Target_Org__c = originalPkg.Target_Org__c,
            Description__c = 'Rollback package for ' + originalPkg.Package_Name__c,
            Version__c = originalPkg.Version__c,
            Status__c = 'Draft',
            Package_XML__c = this.generateDestructiveChanges(originalPackageId)
        );
        
        insert rollbackPkg;
        
        this.logInfo('Created rollback package: ' + rollbackPkg.Name);
        return rollbackPkg;
    }
    
    /**
     * @description Generates destructiveChanges.xml content
     * @param packageId Package Id
     * @return String destructiveChanges.xml content
     */
    private String generateDestructiveChanges(Id packageId) {
        List<Deployment_Component__c> components = [
            SELECT Component_Type__c, Component_Name__c
            FROM Deployment_Component__c
            WHERE Deployment_Package__c = :packageId
        ];
        
        Map<String, List<String>> componentsByType = new Map<String, List<String>>();
        
        for (Deployment_Component__c component : components) {
            if (!componentsByType.containsKey(component.Component_Type__c)) {
                componentsByType.put(component.Component_Type__c, new List<String>());
            }
            componentsByType.get(component.Component_Type__c).add(component.Component_Name__c);
        }
        
        return this.buildPackageXml(componentsByType, DEFAULT_API_VERSION);
    }
}
