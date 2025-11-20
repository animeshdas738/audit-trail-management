/**
 * @description Service for analyzing and categorizing Salesforce components
 * Uses configurable patterns from Custom Metadata
 */
public class ComponentAnalysisService extends BaseService {
    private ConfigurationManager configManager;
    private List<Component_Pattern__mdt> patterns;
    
    /**
     * @description Constructor
     */
    public ComponentAnalysisService() {
        super('ComponentAnalysisService');
    }
    
    /**
     * @description Initialize service
     */
    protected override void initialize() {
        this.configManager = ConfigurationManager.getInstance();
        this.patterns = this.configManager.getComponentPatterns();
        super.initialize();
    }
    
    /**
     * @description Parses audit trail entry to extract component metadata
     * @param entry Audit trail entry
     * @return ComponentMetadata extracted from entry
     */
    public ComponentMetadata parseAuditTrailEntry(AuditTrailEntry entry) {
        if (entry == null || String.isBlank(entry.display)) {
            return null;
        }
        
        ComponentMetadata component = new ComponentMetadata();
        component.sourceOrg = entry.orgName;
        component.lastModified = entry.createdDate;
        component.modifiedBy = entry.createdBy;
        
        // Try to match against configured patterns
        for (Component_Pattern__mdt pattern : this.patterns) {
            if (this.matchesPattern(entry, pattern)) {
                component.componentType = pattern.Component_Type__c;
                component.componentName = this.extractComponentName(entry.display, pattern);
                component.memberName = pattern.Member_Name__c;
                break;
            }
        }
        
        // Fallback: use section and action if no pattern matched
        if (String.isBlank(component.componentType)) {
            component.componentType = entry.section;
            component.componentName = entry.display;
        }
        
        return component;
    }
    
    /**
     * @description Checks if audit trail entry matches a pattern
     * @param entry Audit trail entry
     * @param pattern Component pattern
     * @return Boolean indicating match
     */
    private Boolean matchesPattern(AuditTrailEntry entry, Component_Pattern__mdt pattern) {
        try {
            System.Pattern p = System.Pattern.compile(pattern.Regex_Pattern__c);
            System.Matcher m = p.matcher(entry.display);
            return m.find();
        } catch (Exception ex) {
            this.logError('Error matching pattern: ' + pattern.DeveloperName, ex);
            return false;
        }
    }
    
    /**
     * @description Extracts component name from display field
     * @param display Display field from audit trail
     * @param pattern Component pattern
     * @return String component name
     */
    private String extractComponentName(String display, Component_Pattern__mdt pattern) {
        try {
            System.Pattern p = System.Pattern.compile(pattern.Regex_Pattern__c);
            System.Matcher m = p.matcher(display);
            
            if (m.find() && m.groupCount() > 0) {
                return m.group(1);
            }
            
            return display;
        } catch (Exception ex) {
            this.logError('Error extracting component name', ex);
            return display;
        }
    }
    
    /**
     * @description Analyzes list of audit trail entries
     * @param entries List of audit trail entries
     * @return List of component metadata
     */
    public List<ComponentMetadata> analyzeAuditTrail(List<AuditTrailEntry> entries) {
        List<ComponentMetadata> components = new List<ComponentMetadata>();
        
        for (AuditTrailEntry entry : entries) {
            ComponentMetadata component = this.parseAuditTrailEntry(entry);
            if (component != null) {
                components.add(component);
            }
        }
        
        this.logInfo('Analyzed ' + entries.size() + ' entries, extracted ' + components.size() + ' components');
        return components;
    }
    
    /**
     * @description Categorizes components by type
     * @param components List of components
     * @return Map of component type to list of components
     */
    public Map<String, List<ComponentMetadata>> categorizeComponents(List<ComponentMetadata> components) {
        Map<String, List<ComponentMetadata>> categorized = new Map<String, List<ComponentMetadata>>();
        
        for (ComponentMetadata component : components) {
            if (!categorized.containsKey(component.componentType)) {
                categorized.put(component.componentType, new List<ComponentMetadata>());
            }
            categorized.get(component.componentType).add(component);
        }
        
        return categorized;
    }
    
    /**
     * @description Identifies dependencies between components
     * @param components List of components to analyze
     * @return Map of component key to list of dependency keys
     */
    public Map<String, List<String>> analyzeDependencies(List<ComponentMetadata> components) {
        Map<String, List<String>> dependencies = new Map<String, List<String>>();
        
        // Build component index
        Map<String, ComponentMetadata> componentIndex = new Map<String, ComponentMetadata>();
        for (ComponentMetadata component : components) {
            componentIndex.put(component.getKey(), component);
        }
        
        // Analyze dependencies based on component types
        for (ComponentMetadata component : components) {
            List<String> deps = new List<String>();
            
            // Add known dependency patterns
            if (component.componentType == 'ApexClass') {
                // Apex classes might depend on other classes, triggers, objects
                deps.addAll(this.findApexDependencies(component, componentIndex));
            } else if (component.componentType == 'CustomObject') {
                // Custom objects might be referenced by fields, classes, etc.
                deps.addAll(this.findObjectDependencies(component, componentIndex));
            } else if (component.componentType == 'CustomField') {
                // Fields depend on their parent object
                deps.addAll(this.findFieldDependencies(component, componentIndex));
            }
            
            component.dependencies = deps;
            dependencies.put(component.getKey(), deps);
        }
        
        return dependencies;
    }
    
    /**
     * @description Finds dependencies for Apex classes
     * @param component Component to analyze
     * @param componentIndex Index of all components
     * @return List of dependency keys
     */
    private List<String> findApexDependencies(ComponentMetadata component, Map<String, ComponentMetadata> componentIndex) {
        List<String> deps = new List<String>();
        
        // Check for related triggers, objects, etc.
        // This is a simplified version - can be enhanced with actual code parsing
        for (String key : componentIndex.keySet()) {
            if (key.startsWith('CustomObject:') || key.startsWith('ApexTrigger:')) {
                ComponentMetadata dep = componentIndex.get(key);
                if (component.componentName.containsIgnoreCase(dep.componentName)) {
                    deps.add(key);
                }
            }
        }
        
        return deps;
    }
    
    /**
     * @description Finds dependencies for Custom Objects
     * @param component Component to analyze
     * @param componentIndex Index of all components
     * @return List of dependency keys
     */
    private List<String> findObjectDependencies(ComponentMetadata component, Map<String, ComponentMetadata> componentIndex) {
        List<String> deps = new List<String>();
        
        // Fields, triggers, and classes on this object
        for (String key : componentIndex.keySet()) {
            if (key.startsWith('CustomField:') || key.startsWith('ApexTrigger:') || key.startsWith('ApexClass:')) {
                ComponentMetadata dep = componentIndex.get(key);
                if (dep.componentName.containsIgnoreCase(component.componentName)) {
                    deps.add(key);
                }
            }
        }
        
        return deps;
    }
    
    /**
     * @description Finds dependencies for Custom Fields
     * @param component Component to analyze
     * @param componentIndex Index of all components
     * @return List of dependency keys
     */
    private List<String> findFieldDependencies(ComponentMetadata component, Map<String, ComponentMetadata> componentIndex) {
        List<String> deps = new List<String>();
        
        // Extract object name from field name (assuming format ObjectName.FieldName)
        if (component.componentName.contains('.')) {
            String objectName = component.componentName.substringBefore('.');
            String objectKey = 'CustomObject:' + objectName;
            
            if (componentIndex.containsKey(objectKey)) {
                deps.add(objectKey);
            }
        }
        
        return deps;
    }
    
    /**
     * @description Performs impact analysis for a component
     * @param componentKey Key of component to analyze
     * @param dependencies Dependency map
     * @return List of impacted component keys
     */
    public List<String> performImpactAnalysis(String componentKey, Map<String, List<String>> dependencies) {
        Set<String> impacted = new Set<String>();
        
        // Find all components that depend on this component
        for (String key : dependencies.keySet()) {
            List<String> deps = dependencies.get(key);
            if (deps.contains(componentKey)) {
                impacted.add(key);
            }
        }
        
        return new List<String>(impacted);
    }
}
