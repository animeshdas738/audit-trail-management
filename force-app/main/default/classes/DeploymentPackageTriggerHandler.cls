/**
 * @description Handler for Deployment_Package__c trigger
 * Implements deployment tracking and audit trail
 */
public class DeploymentPackageTriggerHandler {
    
    /**
     * @description Before insert handler
     * @param newRecords New deployment packages
     */
    public void beforeInsert(List<Deployment_Package__c> newRecords) {
        for (Deployment_Package__c pkg : newRecords) {
            // Set initial version if not provided
            if (String.isBlank(pkg.Version__c)) {
                pkg.Version__c = '1.0';
            }
            
            // Validate package XML if provided
            if (String.isNotBlank(pkg.Package_XML__c)) {
                this.validatePackageXml(pkg);
            }
        }
    }
    
    /**
     * @description Before update handler
     * @param newRecords New deployment packages
     * @param oldMap Old deployment package map
     */
    public void beforeUpdate(List<Deployment_Package__c> newRecords, Map<Id, Deployment_Package__c> oldMap) {
        for (Deployment_Package__c pkg : newRecords) {
            Deployment_Package__c oldPkg = oldMap.get(pkg.Id);
            
            // Increment version on status change to Deployed
            if (pkg.Status__c == 'Deployed' && oldPkg.Status__c != 'Deployed') {
                pkg.Version__c = this.incrementVersion(pkg.Version__c);
            }
            
            // Validate status transitions
            this.validateStatusTransition(pkg, oldPkg);
        }
    }
    
    /**
     * @description After insert handler
     * @param newRecords New deployment packages
     */
    public void afterInsert(List<Deployment_Package__c> newRecords) {
        // Create audit trail entries
        this.createAuditTrail(newRecords, 'Created');
    }
    
    /**
     * @description After update handler
     * @param newRecords New deployment packages
     * @param oldMap Old deployment package map
     */
    public void afterUpdate(List<Deployment_Package__c> newRecords, Map<Id, Deployment_Package__c> oldMap) {
        List<Deployment_Package__c> statusChanged = new List<Deployment_Package__c>();
        
        for (Deployment_Package__c pkg : newRecords) {
            Deployment_Package__c oldPkg = oldMap.get(pkg.Id);
            
            if (pkg.Status__c != oldPkg.Status__c) {
                statusChanged.add(pkg);
            }
        }
        
        if (!statusChanged.isEmpty()) {
            this.createAuditTrail(statusChanged, 'Status Changed');
        }
    }
    
    /**
     * @description Validates package XML format
     * @param pkg Deployment package
     */
    private void validatePackageXml(Deployment_Package__c pkg) {
        try {
            // Basic validation - check if XML is well-formed
            Dom.Document doc = new Dom.Document();
            doc.load(pkg.Package_XML__c);
            
            // Check for required elements
            Dom.XmlNode root = doc.getRootElement();
            if (root.getName() != 'Package') {
                pkg.addError('Invalid package.xml: Root element must be Package');
            }
        } catch (Exception ex) {
            pkg.addError('Invalid package.xml format: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Validates status transitions
     * @param newPkg New deployment package
     * @param oldPkg Old deployment package
     */
    private void validateStatusTransition(Deployment_Package__c newPkg, Deployment_Package__c oldPkg) {
        // Define valid transitions
        Map<String, Set<String>> validTransitions = new Map<String, Set<String>>{
            'Draft' => new Set<String>{ 'Ready', 'Failed' },
            'Ready' => new Set<String>{ 'Draft', 'Deployed', 'Failed' },
            'Deployed' => new Set<String>{ 'Rolled Back' },
            'Failed' => new Set<String>{ 'Draft', 'Ready' },
            'Rolled Back' => new Set<String>()
        };
        
        if (newPkg.Status__c != oldPkg.Status__c) {
            Set<String> allowedTransitions = validTransitions.get(oldPkg.Status__c);
            
            if (allowedTransitions == null || !allowedTransitions.contains(newPkg.Status__c)) {
                newPkg.addError('Invalid status transition from ' + oldPkg.Status__c + ' to ' + newPkg.Status__c);
            }
        }
    }
    
    /**
     * @description Increments version number
     * @param currentVersion Current version
     * @return String incremented version
     */
    private String incrementVersion(String currentVersion) {
        if (String.isBlank(currentVersion)) {
            return '1.0';
        }
        
        List<String> parts = currentVersion.split('\\.');
        if (parts.size() >= 2) {
            Integer major = Integer.valueOf(parts[0]);
            Integer minor = Integer.valueOf(parts[1]);
            minor++;
            return major + '.' + minor;
        }
        
        return currentVersion;
    }
    
    /**
     * @description Creates audit trail entries for deployment packages
     * @param packages Deployment packages
     * @param action Action performed
     */
    private void createAuditTrail(List<Deployment_Package__c> packages, String action) {
        // In a real implementation, this would create records in an audit trail object
        // For now, just log the action
        for (Deployment_Package__c pkg : packages) {
            System.debug(LoggingLevel.INFO, 
                String.format('Audit Trail: {0} - Package: {1}, Status: {2}', 
                    new List<String>{ action, pkg.Name, pkg.Status__c }));
        }
    }
}
