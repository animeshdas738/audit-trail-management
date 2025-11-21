/**
 * @description Controller for Org Connection management
 */
public with sharing class OrgConnectionController {
    
    /**
     * @description Gets all active org connections
     * @return List of Org_Connection__mdt records
     */
    @AuraEnabled(cacheable=true)
    public static List<Org_Connection__mdt> getOrgConnections() {
        ConfigurationManager configMgr = ConfigurationManager.getInstance();
        return configMgr.getActiveOrgConnections();
    }
    
    /**
     * @description Tests connection to an org
     * @param orgDeveloperName Developer name of org connection
     * @return Boolean indicating successful connection
     */
    @AuraEnabled
    public static Boolean testConnection(String orgDeveloperName) {
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        return service.testConnection(orgDeveloperName);
    }
    
    /**
     * @description Gets audit trail for an org
     * @param orgDeveloperName Developer name of org connection
     * @param startDate Start date
     * @param endDate End date
     * @return List of audit trail entries
     */
    @AuraEnabled
    public static List<AuditTrailEntry> getAuditTrail(String orgDeveloperName, DateTime startDate, DateTime endDate) {
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        return service.getAuditTrail(orgDeveloperName, startDate, endDate);
    }
    
    /**
     * @description Gets audit trail from all orgs
     * @param startDate Start date
     * @param endDate End date
     * @return Map of org name to audit trail entries
     */
    @AuraEnabled
    public static Map<String, List<AuditTrailEntry>> getAuditTrailFromAllOrgs(DateTime startDate, DateTime endDate) {
        MultiOrgConnectionService service = new MultiOrgConnectionService();
        return service.getAuditTrailFromAllOrgs(startDate, endDate);
    }
}
