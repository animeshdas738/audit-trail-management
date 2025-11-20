/**
 * @description Abstract base service class implementing common functionality
 * Uses Template Method pattern for extensibility
 */
public abstract class BaseService implements IService {
    protected String serviceName;
    protected Map<String, Object> config;
    
    /**
     * @description Constructor initializing service
     */
    protected BaseService(String serviceName) {
        this.serviceName = serviceName;
        this.config = new Map<String, Object>();
        this.initialize();
    }
    
    /**
     * @description Template method for service initialization
     * Override in subclasses for custom initialization
     */
    protected virtual void initialize() {
        // Override in subclasses
    }
    
    /**
     * @description Validates service configuration
     * @return Boolean indicating if service is properly configured
     */
    public virtual Boolean isConfigured() {
        return this.config != null && !this.config.isEmpty();
    }
    
    /**
     * @description Gets service name
     * @return String service name
     */
    public String getServiceName() {
        return this.serviceName;
    }
    
    /**
     * @description Logs error with service context
     * @param message Error message
     * @param ex Exception (optional)
     */
    protected void logError(String message, Exception ex) {
        String logMessage = String.format('[{0}] {1}', 
            new List<String>{ this.serviceName, message });
        
        if (ex != null) {
            logMessage += ' - Exception: ' + ex.getMessage() + '\n' + ex.getStackTraceString();
        }
        
        System.debug(LoggingLevel.ERROR, logMessage);
    }
    
    /**
     * @description Logs info with service context
     * @param message Info message
     */
    protected void logInfo(String message) {
        System.debug(LoggingLevel.INFO, String.format('[{0}] {1}', 
            new List<String>{ this.serviceName, message }));
    }
}
