# Audit Trail Management - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                               │
│                    (Lightning Web Components)                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │   Audit      │  │     Org      │  │  Component   │  │   Package   │ │
│  │   Trail      │  │  Connection  │  │   Analysis   │  │  Generator  │ │
│  │   Manager    │  │   Manager    │  │              │  │             │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬──────┘ │
│         │                 │                  │                  │        │
│  ┌──────────────┐         │                  │                  │        │
│  │ Deployment   │         │                  │                  │        │
│  │   History    │         │                  │                  │        │
│  └──────┬───────┘         │                  │                  │        │
└─────────┼─────────────────┼──────────────────┼──────────────────┼────────┘
          │                 │                  │                  │
┌─────────┼─────────────────┼──────────────────┼──────────────────┼────────┐
│         │    CONTROLLER LAYER (Aura-Enabled Apex)               │        │
│         │                 │                  │                  │        │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼──────┐   │
│  │ Deployment   │  │     Org      │  │  Component   │  │  Package    │   │
│  │   History    │  │  Connection  │  │   Analysis   │  │ Generation  │   │
│  │  Controller  │  │  Controller  │  │  Controller  │  │ Controller  │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬──────┘   │
└─────────┼─────────────────┼──────────────────┼──────────────────┼────────┘
          │                 │                  │                  │
┌─────────┼─────────────────┼──────────────────┼──────────────────┼────────┐
│         │        SERVICE LAYER (Business Logic)                 │        │
│         │                 │                  │                  │        │
│  ┌──────▼───────────────────┐  ┌────────────▼──────────┐  ┌────▼──────┐  │
│  │  Service Factory         │  │  Configuration Mgr    │  │ Base      │  │
│  │  (Factory Pattern)       │  │  (Singleton Pattern)  │  │ Service   │  │
│  └───────────┬──────────────┘  └───────────────────────┘  └───────────┘  │
│              │                                                           │
│  ┌───────────▼──────────┐  ┌────────────────────┐  ┌───────────────────┐ │
│  │   Multi-Org          │  │    Component       │  │     Package       │ │
│  │   Connection         │  │     Analysis       │  │    Generation     │ │
│  │   Service            │  │     Service        │  │     Service       │ │
│  └──────────────────────┘  └────────────────────┘  └───────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
          │                            │                          │
┌─────────┼────────────────────────────┼──────────────────────────┼───────┐
│         │           DATA LAYER                                  │       │
│         │                            │                          │       │
│  ┌──────▼───────────┐  ┌─────────────▼──────────┐  ┌───────────▼──────┐ │
│  │  Custom Metadata │  │   Custom Objects       │  │   Audit Trail    │ │
│  │                  │  │                        │  │   Data (SF)      │ │
│  │  • Org Conn.     │  │  • Deployment Package  │  │                  │ │
│  │  • Comp. Pattern │  │  • Deployment Comp.    │  │  • Setup         │ │
│  │  • Pkg Template  │  │                        │  │    Audit Trail   │ │
│  └──────────────────┘  └────────────────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
          │
┌─────────┼────────────────────────────────────────────────────────────┐
│         │              EXTERNAL INTEGRATION LAYER                    │
│         │                                                            │
│  ┌──────▼───────────┐  ┌─────────────────────┐  ┌─────────────────┐  │
│  │  Named           │  │  Remote Site        │  │  Connected      │  │
│  │  Credentials     │  │  Settings           │  │  Orgs           │  │
│  └──────────────────┘  └─────────────────────┘  └─────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

## Data Model

```
┌────────────────────────────────┐
│   Deployment_Package__c        │
├────────────────────────────────┤
│  Name (Auto Number)            │
│  Package_Name__c               │
│  Package_XML__c (Long Text)    │
│  Status__c (Picklist)          │
│  Version__c                    │
│  Target_Org__c                 │
│  Description__c                │
│  Component_Count__c (Rollup)   │
└──────────────┬─────────────────┘
               │ Master-Detail
               │
┌──────────────▼─────────────────┐
│  Deployment_Component__c       │
├────────────────────────────────┤
│  Name (Auto Number)            │
│  Component_Type__c             │
│  Component_Name__c             │
│  Source_Org__c                 │
│  Deployment_Package__c (MD)    │
└────────────────────────────────┘
```

## Design Patterns

### 1. Factory Pattern
```
ServiceFactory (Singleton)
    │
    ├── Creates ──> MultiOrgConnectionService
    ├── Creates ──> ComponentAnalysisService
    └── Creates ──> PackageGenerationService
```

### 2. Template Method Pattern
```
BaseService (Abstract)
    │
    ├── initialize() [virtual]
    ├── isConfigured() [virtual]
    ├── logError() [protected]
    └── logInfo() [protected]
    
    Extended by:
    ├── MultiOrgConnectionService
    ├── ComponentAnalysisService
    └── PackageGenerationService
```

### 3. Singleton Pattern
```
ConfigurationManager (Singleton)
    │
    ├── getInstance()
    ├── getActiveOrgConnections()
    ├── getComponentPatterns()
    └── getPackageTemplate()
```

## Component Flow

### Org Connection Flow
```
1. User clicks "Test Connection"
   ↓
2. orgConnectionManager LWC calls OrgConnectionController
   ↓
3. Controller calls MultiOrgConnectionService.testConnection()
   ↓
4. Service retrieves org config from ConfigurationManager
   ↓
5. Makes HTTP callout using Named Credential
   ↓
6. Returns success/failure to UI
```

### Component Analysis Flow
```
1. User selects date range and clicks "Analyze"
   ↓
2. componentAnalysis LWC calls ComponentAnalysisController
   ↓
3. Controller calls MultiOrgConnectionService.getAuditTrailFromAllOrgs()
   ↓
4. Service retrieves audit trail from each configured org
   ↓
5. ComponentAnalysisService.analyzeAuditTrail() parses entries
   ↓
6. Matches against Component Patterns from metadata
   ↓
7. Returns categorized components to UI
```

### Package Generation Flow
```
1. User fills package details and clicks "Generate"
   ↓
2. packageGenerator LWC calls PackageGenerationController
   ↓
3. Controller calls PackageGenerationService.generatePackageXml()
   ↓
4. Service applies template filters (if template selected)
   ↓
5. Builds package.xml from component list
   ↓
6. Returns XML to UI
   ↓
7. User clicks "Save Package"
   ↓
8. Service creates Deployment_Package__c record
   ↓
9. Creates related Deployment_Component__c records
   ↓
10. Returns package Id to UI
```

## Security Model

```
┌─────────────────────────────────────────┐
│         Permission Sets                 │
├─────────────────────────────────────────┤
│                                         │
│  Audit_Trail_Admin                      │
│  ├── Full CRUD: Deployment Packages     │
│  ├── Full CRUD: Deployment Components   │
│  ├── Access: All Controllers            │
│  └── Access: All Services               │
│                                         │
│  Audit_Trail_User                       │
│  ├── Read Only: Deployment Packages     │
│  ├── Read Only: Deployment Components   │
│  └── Access: Limited Controllers        │
│                                         │
└─────────────────────────────────────────┘
```

## Integration Points

### Named Credentials
- Secure connection to external Salesforce orgs
- OAuth 2.0 authentication
- Per-user or per-org credentials
- Automatic token refresh

### Remote Site Settings
- Backup connection method
- Configure for each target org URL
- Required for HTTP callouts

### SetupAuditTrail API
- Standard Salesforce API
- Query audit trail records
- Limited to 2000 records per query
- Stores last 6 months of data

## Extensibility Points

### 1. Add New Service
```
1. Create class extending BaseService
2. Implement business logic
3. Add to ServiceFactory (optional)
4. Create controller if needed
5. Update permission sets
```

### 2. Add New Component Pattern
```
1. Navigate to Component Pattern metadata
2. Create new record with regex
3. Set priority
4. No code changes required
```

### 3. Add New Package Template
```
1. Navigate to Package Template metadata
2. Create new record with filters
3. Configure included/excluded types
4. No code changes required
```

### 4. Add New UI Component
```
1. Create new LWC component
2. Add to auditTrailManager tabs
3. Create controller if needed
4. Update permission sets
```

---

This architecture provides a solid foundation for enterprise audit trail management with clear separation of concerns, extensibility, and maintainability.
