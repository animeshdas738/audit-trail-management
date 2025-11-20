/**
 * @description Data wrapper for audit trail entries
 */
public class AuditTrailEntry {
    public String id { get; set; }
    public String action { get; set; }
    public String section { get; set; }
    public DateTime createdDate { get; set; }
    public String createdBy { get; set; }
    public String display { get; set; }
    public String orgName { get; set; }
    public String environmentType { get; set; }
    
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
