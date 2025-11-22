/**
 * @description Test class for ConfigurationManager
 */
@IsTest
private class ConfigurationManagerTest {
    
    @IsTest
    static void testGetInstance() {
        ConfigurationManager instance1 = ConfigurationManager.getInstance();
        ConfigurationManager instance2 = ConfigurationManager.getInstance();
        
        System.assertNotEquals(null, instance1, 'Instance should not be null');
        System.assertEquals(instance1, instance2, 'Should return same instance');
    }
    
    @IsTest
    static void testGetActiveOrgConnections() {
        ConfigurationManager configMgr = ConfigurationManager.getInstance();
        List<Org_Connection__mdt> connections = configMgr.getActiveOrgConnections();
        
        System.assertNotEquals(null, connections, 'Connections list should not be null');
    }
    
    @IsTest
    static void testGetComponentPatterns() {
        ConfigurationManager configMgr = ConfigurationManager.getInstance();
        List<Component_Pattern__mdt> patterns = configMgr.getComponentPatterns();
        
        System.assertNotEquals(null, patterns, 'Patterns list should not be null');
    }
}
