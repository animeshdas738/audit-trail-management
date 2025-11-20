/**
 * @description Service for managing connections to multiple Salesforce orgs
 * Retrieves audit trail data from connected orgs
 */
public class MultiOrgConnectionService extends BaseService {
    private ConfigurationManager configManager;
    
    /**
     * @description Constructor
     */
    public MultiOrgConnectionService() {
        super('MultiOrgConnectionService');
    }
    
    /**
     * @description Initialize service
     */
    protected override void initialize() {
        this.configManager = ConfigurationManager.getInstance();
        super.initialize();
    }
    
    /**
     * @description Gets all configured org connections
     * @return List of org connection metadata
     */
    public List<Org_Connection__mdt> getOrgConnections() {
        return this.configManager.getActiveOrgConnections();
    }
    
    /**
     * @description Tests connection to a specific org
     * @param orgDeveloperName Developer name of org connection
     * @return Boolean indicating successful connection
     */
    public Boolean testConnection(String orgDeveloperName) {
        try {
            Org_Connection__mdt orgConn = this.configManager.getOrgConnection(orgDeveloperName);
            
            if (orgConn == null) {
                this.logError('Org connection not found: ' + orgDeveloperName, null);
                return false;
            }
            
            // Make a simple API call to test connection
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + orgConn.Named_Credential__c + '/services/data/v65.0/limits');
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                this.logInfo('Successfully connected to org: ' + orgConn.Org_Name__c);
                return true;
            } else {
                this.logError('Connection failed with status: ' + res.getStatusCode(), null);
                return false;
            }
            
        } catch (Exception ex) {
            this.logError('Error testing connection', ex);
            return false;
        }
    }
    
    /**
     * @description Retrieves audit trail data from a specific org
     * @param orgDeveloperName Developer name of org connection
     * @param startDate Start date for audit trail query
     * @param endDate End date for audit trail query
     * @return List of audit trail entries
     */
    public List<AuditTrailEntry> getAuditTrail(String orgDeveloperName, DateTime startDate, DateTime endDate) {
        List<AuditTrailEntry> entries = new List<AuditTrailEntry>();
        
        try {
            Org_Connection__mdt orgConn = this.configManager.getOrgConnection(orgDeveloperName);
            
            if (orgConn == null) {
                this.logError('Org connection not found: ' + orgDeveloperName, null);
                return entries;
            }
            
            // Build SOQL query for SetupAuditTrail
            String query = 'SELECT Id, Action, Section, CreatedDate, CreatedBy.Name, Display ' +
                          'FROM SetupAuditTrail ' +
                          'WHERE CreatedDate >= ' + startDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' ' +
                          'AND CreatedDate <= ' + endDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' ' +
                          'ORDER BY CreatedDate DESC ' +
                          'LIMIT 2000';
            
            // Make API call to retrieve audit trail
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + orgConn.Named_Credential__c + 
                          '/services/data/v65.0/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>)responseMap.get('records');
                
                for (Object record : records) {
                    Map<String, Object> recordMap = (Map<String, Object>)record;
                    
                    AuditTrailEntry entry = new AuditTrailEntry();
                    entry.id = (String)recordMap.get('Id');
                    entry.action = (String)recordMap.get('Action');
                    entry.section = (String)recordMap.get('Section');
                    entry.createdDate = DateTime.valueOf(((String)recordMap.get('CreatedDate')).replace('T', ' ').replace('.000+0000', ''));
                    entry.display = (String)recordMap.get('Display');
                    entry.orgName = orgConn.Org_Name__c;
                    entry.environmentType = orgConn.Environment_Type__c;
                    
                    // Get CreatedBy name
                    Map<String, Object> createdByMap = (Map<String, Object>)recordMap.get('CreatedBy');
                    if (createdByMap != null) {
                        entry.createdBy = (String)createdByMap.get('Name');
                    }
                    
                    entries.add(entry);
                }
                
                this.logInfo('Retrieved ' + entries.size() + ' audit trail entries from ' + orgConn.Org_Name__c);
            } else {
                this.logError('Failed to retrieve audit trail. Status: ' + res.getStatusCode(), null);
            }
            
        } catch (Exception ex) {
            this.logError('Error retrieving audit trail', ex);
        }
        
        return entries;
    }
    
    /**
     * @description Retrieves audit trail data from all configured orgs
     * @param startDate Start date for audit trail query
     * @param endDate End date for audit trail query
     * @return Map of org name to audit trail entries
     */
    public Map<String, List<AuditTrailEntry>> getAuditTrailFromAllOrgs(DateTime startDate, DateTime endDate) {
        Map<String, List<AuditTrailEntry>> allEntries = new Map<String, List<AuditTrailEntry>>();
        
        List<Org_Connection__mdt> orgs = this.getOrgConnections();
        
        for (Org_Connection__mdt org : orgs) {
            List<AuditTrailEntry> entries = this.getAuditTrail(org.DeveloperName, startDate, endDate);
            allEntries.put(org.Org_Name__c, entries);
        }
        
        return allEntries;
    }
    
    /**
     * @description Compare audit trail entries across orgs
     * @param entries Map of org name to audit trail entries
     * @return Map categorizing common vs environment-specific changes
     */
    public Map<String, Object> compareAcrossOrgs(Map<String, List<AuditTrailEntry>> entries) {
        Map<String, Object> comparison = new Map<String, Object>();
        Map<String, Set<String>> componentsByAction = new Map<String, Set<String>>();
        Map<String, Integer> actionCounts = new Map<String, Integer>();
        
        // Aggregate all actions across orgs
        for (String orgName : entries.keySet()) {
            for (AuditTrailEntry entry : entries.get(orgName)) {
                String actionKey = entry.action + ':' + entry.section;
                
                if (!componentsByAction.containsKey(actionKey)) {
                    componentsByAction.put(actionKey, new Set<String>());
                    actionCounts.put(actionKey, 0);
                }
                
                componentsByAction.get(actionKey).add(orgName);
                actionCounts.put(actionKey, actionCounts.get(actionKey) + 1);
            }
        }
        
        // Identify common vs org-specific changes
        List<String> commonChanges = new List<String>();
        Map<String, List<String>> orgSpecificChanges = new Map<String, List<String>>();
        
        Integer totalOrgs = entries.keySet().size();
        
        for (String actionKey : componentsByAction.keySet()) {
            Set<String> orgsWithAction = componentsByAction.get(actionKey);
            
            if (orgsWithAction.size() == totalOrgs) {
                commonChanges.add(actionKey);
            } else {
                for (String orgName : orgsWithAction) {
                    if (!orgSpecificChanges.containsKey(orgName)) {
                        orgSpecificChanges.put(orgName, new List<String>());
                    }
                    orgSpecificChanges.get(orgName).add(actionKey);
                }
            }
        }
        
        comparison.put('commonChanges', commonChanges);
        comparison.put('orgSpecificChanges', orgSpecificChanges);
        comparison.put('actionCounts', actionCounts);
        
        return comparison;
    }
}
