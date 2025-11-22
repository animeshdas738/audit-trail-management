# Audit Trail Management - Setup Guide

## Quick Start

This guide will help you set up and configure the Audit Trail Management solution in your Salesforce org.

## Step 1: Deploy the Solution

### Using Salesforce CLI

```bash
# Authenticate to your org
sf org login web -a myorg

# Deploy all metadata
sf project deploy start -d force-app/main/default -o myorg

# Verify deployment
sf project deploy report
```

### Using VS Code

1. Right-click on `force-app` folder
2. Select "Deploy Source to Org"
3. Wait for deployment to complete

## Step 2: Assign Permission Sets

### For Administrators
```bash
sf org assign permset -n Audit_Trail_Admin -o myorg
```

### For Regular Users
```bash
sf org assign permset -n Audit_Trail_User -o myorg
```

## Step 3: Configure Named Credentials

To connect to other Salesforce orgs, you need to set up Named Credentials:

1. **Navigate to Setup**
   - Go to Setup > Named Credentials

2. **Create New Named Credential**
   - Click "New Named Credential"
   - Select "Named Credential" (not Legacy)

3. **Configure Settings**
   ```
   Label: Production Org Connection
   Name: Production_Org_Connection
   URL: https://your-org.my.salesforce.com
   
   Authentication:
   - Authentication Protocol: OAuth 2.0
   - Authentication Flow: User
   - Scope: full refresh_token
   - Subject Type: Per User
   ```

4. **Complete OAuth Flow**
   - Click "Save"
   - Authenticate to the target org
   - Authorize access

5. **Repeat for Each Org**
   - Create separate Named Credentials for each org you want to connect

## Step 4: Configure Org Connections

1. **Navigate to Custom Metadata**
   - Setup > Custom Metadata Types
   - Find "Org Connection"
   - Click "Manage Records"

2. **Create New Record**
   - Click "New"
   - Fill in the details:
     ```
     Label: Production Org
     Org Connection Name: Production_Org
     
     Fields:
     - Org Name: Production Org
     - Instance URL: https://your-org.my.salesforce.com
     - Named Credential: Production_Org_Connection
     - Environment Type: Production
     - Is Active: Checked
     ```

3. **Save and Test**
   - Save the record
   - Navigate to the Audit Trail Manager component
   - Test the connection

## Step 5: (Optional) Configure Component Patterns

Add custom patterns to parse specific component types from audit trails:

1. **Navigate to Component Pattern Metadata**
   - Setup > Custom Metadata Types > Component Pattern
   - Click "Manage Records"

2. **Create Pattern for Apex Classes**
   ```
   Label: Apex Class Pattern
   Component Pattern Name: Apex_Class_Pattern
   
   Fields:
   - Component Type: ApexClass
   - Regex Pattern: Created Apex (?:class|trigger): (\w+)
   - Member Name: (leave blank)
   - Priority: 10
   ```

3. **Create Pattern for Custom Objects**
   ```
   Label: Custom Object Pattern
   Component Pattern Name: Custom_Object_Pattern
   
   Fields:
   - Component Type: CustomObject
   - Regex Pattern: Created custom object: (\w+)
   - Member Name: (leave blank)
   - Priority: 20
   ```

4. **Add More Patterns as Needed**
   - CustomField
   - CustomTab
   - PermissionSet
   - ApexPage
   - etc.

## Step 6: (Optional) Create Package Templates

Define reusable templates for common deployment scenarios:

1. **Navigate to Package Template Metadata**
   - Setup > Custom Metadata Types > Package Template
   - Click "Manage Records"

2. **Create Template for Production Deployment**
   ```
   Label: Production Deployment
   Package Template Name: Production_Deployment
   
   Fields:
   - Template Name: Production Deployment Template
   - API Version: 65.0
   - Included Types: ApexClass,ApexTrigger,CustomObject
   - Excluded Types: Profile,PermissionSet
   ```

3. **Create Template for Sandbox Refresh**
   ```
   Label: Sandbox Refresh
   Package Template Name: Sandbox_Refresh
   
   Fields:
   - Template Name: Sandbox Refresh Template
   - API Version: 65.0
   - Included Types: (leave blank for all)
   - Excluded Types: ContentAsset,StaticResource
   ```

## Step 7: Add Component to Lightning App

### Create Custom App

1. **Navigate to App Manager**
   - Setup > App Manager
   - Click "New Lightning App"

2. **Configure App Details**
   ```
   App Name: Audit Trail Management
   Developer Name: Audit_Trail_Management
   Description: Manage audit trails across multiple orgs
   App Options: Leave defaults
   ```

3. **Add Navigation Items**
   - Add relevant tabs:
     - Home
     - Deployment Packages
     - Deployment Components

4. **Assign to Profiles**
   - Select profiles that should have access
   - Include System Administrator

### Add to Home Page

1. **Navigate to Lightning App Builder**
   - Setup > Lightning App Builder
   - Edit Home Page or create new page

2. **Add Component**
   - Drag "auditTrailManager" component to page
   - Configure visibility and layout
   - Save and Activate

## Step 8: Configure Remote Site Settings

If Named Credentials don't cover all external connections:

1. **Navigate to Remote Site Settings**
   - Setup > Remote Site Settings
   - Click "New Remote Site"

2. **Add Each Org**
   ```
   Remote Site Name: Production_Org
   Remote Site URL: https://your-org.my.salesforce.com
   Active: Checked
   ```

## Step 9: Test the Solution

### Test Org Connection

1. Open Audit Trail Manager component
2. Navigate to "Org Connections" tab
3. Click "Test Connection" for each configured org
4. Verify successful connection

### Test Component Analysis

1. Navigate to "Component Analysis" tab
2. Select date range (e.g., last 7 days)
3. Click "Analyze"
4. Verify components are displayed

### Test Package Generation

1. Navigate to "Package Generation" tab
2. Fill in package details
3. Click "Generate Package XML"
4. Verify XML is generated correctly
5. Save package

### Test Deployment History

1. Navigate to "Deployment History" tab
2. Verify saved packages appear
3. Click "View Details" on a package
4. Click "Download XML" to download

## Troubleshooting Common Issues

### Issue: Cannot Connect to Org

**Solution:**
1. Verify Named Credential is configured correctly
2. Check Remote Site Settings include the org URL
3. Ensure user has authorized the connection
4. Review debug logs for specific errors

### Issue: Components Not Parsing

**Solution:**
1. Check Component Pattern regex is correct
2. Test regex patterns separately
3. Verify Priority values are set correctly
4. Review audit trail Display field format

### Issue: Permission Errors

**Solution:**
1. Verify permission set is assigned
2. Check object and field-level security
3. Ensure Apex classes are accessible
4. Review sharing settings

### Issue: API Limits Exceeded

**Solution:**
1. Reduce date range for analysis
2. Process fewer orgs at once
3. Schedule analysis during off-peak hours
4. Contact Salesforce to increase limits

## Advanced Configuration

### Custom Field-Level Security

Configure FLS based on your organization's requirements:

1. Navigate to each custom object
2. Set field-level security for sensitive fields
3. Test access with different user profiles

### Custom Validation Rules

Add validation rules to enforce business logic:

1. Navigate to Deployment Package object
2. Create validation rules as needed
3. Example: Enforce package naming conventions

### Custom Workflow/Process Builder

Automate processes:

1. Create email alerts for deployment status changes
2. Notify administrators when packages are created
3. Auto-update related records

## Best Practices

1. **Regular Backups**: Export deployment packages regularly
2. **Naming Conventions**: Use consistent naming for packages and orgs
3. **Access Control**: Restrict package generation to authorized users
4. **Monitoring**: Review API usage regularly
5. **Documentation**: Document custom patterns and templates
6. **Testing**: Test in sandbox before production deployment

## Next Steps

- Review the main README.md for detailed usage instructions
- Explore additional configuration options
- Customize components to match your requirements
- Set up regular audit trail analysis schedules

## Support

For issues or questions:
1. Check debug logs
2. Review Salesforce documentation
3. Contact your Salesforce administrator

---

**Congratulations! Your Audit Trail Management solution is now configured and ready to use.**
