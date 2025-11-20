/**
 * @description Service factory for creating and managing service instances
 * Implements Singleton and Factory patterns
 */
public class ServiceFactory {
    private static ServiceFactory instance;
    private Map<String, IService> serviceCache;
    
    /**
     * @description Private constructor for Singleton
     */
    private ServiceFactory() {
        this.serviceCache = new Map<String, IService>();
    }
    
    /**
     * @description Gets singleton instance
     * @return ServiceFactory instance
     */
    public static ServiceFactory getInstance() {
        if (instance == null) {
            instance = new ServiceFactory();
        }
        return instance;
    }
    
    /**
     * @description Gets or creates service instance
     * @param serviceType Type of service to create
     * @return IService instance
     */
    public IService getService(Type serviceType) {
        String typeName = serviceType.getName();
        
        if (!this.serviceCache.containsKey(typeName)) {
            IService service = (IService)serviceType.newInstance();
            this.serviceCache.put(typeName, service);
        }
        
        return this.serviceCache.get(typeName);
    }
    
    /**
     * @description Clears service cache (useful for testing)
     */
    @TestVisible
    private void clearCache() {
        this.serviceCache.clear();
    }
}
