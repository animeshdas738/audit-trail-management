/**
 * @description Data wrapper for audit trail entries
 */
public class AuditTrailEntry {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String action { get; set; }
    @AuraEnabled public String section { get; set; }
    @AuraEnabled public DateTime createdDate { get; set; }
    @AuraEnabled public String createdBy { get; set; }
    @AuraEnabled public String display { get; set; }
    @AuraEnabled public String orgName { get; set; }
    @AuraEnabled public String environmentType { get; set; }
    
    /**
     * @description Constructor
     */
    public AuditTrailEntry() {
        // Default constructor
    }
    
    /**
     * @description Parse component information from display field
     * @return Map of component type to component name
     */
    public Map<String, String> parseComponents() {
        Map<String, String> components = new Map<String, String>();
        
        if (String.isNotBlank(this.display)) {
            // Basic parsing logic - can be enhanced with regex patterns
            components.put('raw', this.display);
        }
        
        return components;
    }
}
