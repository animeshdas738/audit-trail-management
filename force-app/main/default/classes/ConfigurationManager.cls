/**
 * @description Configuration manager for retrieving custom metadata
 * Implements caching for performance
 */
public class ConfigurationManager {
    private static ConfigurationManager instance;
    private Map<String, Org_Connection__mdt> orgConnectionCache;
    private Map<String, Component_Pattern__mdt> componentPatternCache;
    private Map<String, Package_Template__mdt> packageTemplateCache;
    
    /**
     * @description Private constructor for Singleton
     */
    private ConfigurationManager() {
        this.orgConnectionCache = new Map<String, Org_Connection__mdt>();
        this.componentPatternCache = new Map<String, Component_Pattern__mdt>();
        this.packageTemplateCache = new Map<String, Package_Template__mdt>();
    }
    
    /**
     * @description Gets singleton instance
     * @return ConfigurationManager instance
     */
    public static ConfigurationManager getInstance() {
        if (instance == null) {
            instance = new ConfigurationManager();
        }
        return instance;
    }
    
    /**
     * @description Gets all active org connections
     * @return List of Org_Connection__mdt records
     */
    public List<Org_Connection__mdt> getActiveOrgConnections() {
        if (this.orgConnectionCache.isEmpty()) {
            for (Org_Connection__mdt conn : [
                SELECT Id, 
                    DeveloperName, 
                    MasterLabel, 
                    Org_Name__c,
                    Instance_URL__c, 
                    Named_Credential__c, 
                    Environment_Type__c, 
                    Is_Active__c
                FROM Org_Connection__mdt
                WHERE Is_Active__c = true
            ]) {
                this.orgConnectionCache.put(conn.DeveloperName, conn);
            }
        }
        return this.orgConnectionCache.values();
    }
    
    /**
     * @description Gets org connection by developer name
     * @param developerName Developer name of org connection
     * @return Org_Connection__mdt record
     */
    public Org_Connection__mdt getOrgConnection(String developerName) {
        if (this.orgConnectionCache.isEmpty()) {
            this.getActiveOrgConnections();
        }
        return this.orgConnectionCache.get(developerName);
    }
    
    /**
     * @description Gets all component patterns ordered by priority
     * @return List of Component_Pattern__mdt records
     */
    public List<Component_Pattern__mdt> getComponentPatterns() {
        if (this.componentPatternCache.isEmpty()) {
            for (Component_Pattern__mdt pattern : [
                SELECT Id, 
                    DeveloperName, 
                    MasterLabel,
                    Component_Type__c,
                    Regex_Pattern__c, 
                    Member_Name__c, 
                    Priority__c
                FROM Component_Pattern__mdt
                ORDER BY Priority__c ASC
            ]) {
                this.componentPatternCache.put(pattern.DeveloperName, pattern);
            }
        }
        return this.componentPatternCache.values();
    }
    
    /**
     * @description Gets package template by developer name
     * @param developerName Developer name of package template
     * @return Package_Template__mdt record
     */
    public Package_Template__mdt getPackageTemplate(String developerName) {
        if (this.packageTemplateCache.isEmpty()) {
            for (Package_Template__mdt template : [
                SELECT Id, 
                    DeveloperName, 
                    MasterLabel,
                    Template_Name__c, 
                    API_Version__c,
                    Included_Types__c, 
                    Excluded_Types__c
                FROM Package_Template__mdt
            ]) {
                this.packageTemplateCache.put(template.DeveloperName, template);
            }
        }
        return this.packageTemplateCache.get(developerName);
    }
    
    /**
     * @description Clears all caches (useful for testing)
     */
    @TestVisible
    private void clearCache() {
        this.orgConnectionCache.clear();
        this.componentPatternCache.clear();
        this.packageTemplateCache.clear();
    }
}