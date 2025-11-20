/**
 * @description Data wrapper for Salesforce component metadata
 */
public class ComponentMetadata {
    public String componentType { get; set; }
    public String componentName { get; set; }
    public String memberName { get; set; }
    public String sourceOrg { get; set; }
    public List<String> dependencies { get; set; }
    public DateTime lastModified { get; set; }
    public String modifiedBy { get; set; }
    
    /**
     * @description Constructor
     */
    public ComponentMetadata() {
        this.dependencies = new List<String>();
    }
    
    /**
     * @description Gets unique key for component
     * @return String unique key
     */
    public String getKey() {
        return this.componentType + ':' + this.componentName;
    }
    
    /**
     * @description Compares two components
     * @param other Component to compare with
     * @return Boolean indicating if components are equal
     */
    public Boolean equals(ComponentMetadata other) {
        return this.getKey() == other.getKey();
    }
}
