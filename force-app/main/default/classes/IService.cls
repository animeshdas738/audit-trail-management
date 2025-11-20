/**
 * @description Base interface for all service classes
 * Provides contract for common service operations
 */
public interface IService {
    /**
     * @description Validates service configuration
     * @return Boolean indicating if service is properly configured
     */
    Boolean isConfigured();
    
    /**
     * @description Gets service name for logging and identification
     * @return String service name
     */
    String getServiceName();
}
