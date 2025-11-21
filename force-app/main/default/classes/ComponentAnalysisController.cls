/**
 * @description Controller for Component Analysis
 */
public with sharing class ComponentAnalysisController {
    
    /**
     * @description Analyzes audit trail entries
     * @param entries Audit trail entries JSON
     * @return List of component metadata
     */
    @AuraEnabled
    public static List<ComponentMetadata> analyzeComponents(String entriesJson) {
        List<AuditTrailEntry> entries = (List<AuditTrailEntry>)JSON.deserialize(entriesJson, List<AuditTrailEntry>.class);
        ComponentAnalysisService service = new ComponentAnalysisService();
        return service.analyzeAuditTrail(entries);
    }
    
    /**
     * @description Categorizes components by type
     * @param componentsJson Components JSON
     * @return Map of component type to components
     */
    @AuraEnabled
    public static Map<String, List<ComponentMetadata>> categorizeComponents(String componentsJson) {
        List<ComponentMetadata> components = (List<ComponentMetadata>)JSON.deserialize(componentsJson, List<ComponentMetadata>.class);
        ComponentAnalysisService service = new ComponentAnalysisService();
        return service.categorizeComponents(components);
    }
    
    /**
     * @description Analyzes component dependencies
     * @param componentsJson Components JSON
     * @return Map of component key to dependencies
     */
    @AuraEnabled
    public static Map<String, List<String>> analyzeDependencies(String componentsJson) {
        List<ComponentMetadata> components = (List<ComponentMetadata>)JSON.deserialize(componentsJson, List<ComponentMetadata>.class);
        ComponentAnalysisService service = new ComponentAnalysisService();
        return service.analyzeDependencies(components);
    }
}
