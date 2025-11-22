# Bootstrap Guide

**Navigation:** [🏠 Home](../README.md) | [📚 Documentation Index](README.md)

---

## 🎯 What is Bootstrap?

The **bootstrap pipeline** (`infra_bootstrap.exemplo.yaml`) is an **optional** automated setup that creates the initial Azure resources and service connections needed for the POC.

⚠️ **Important:** This file is provided as a **reference only** and is **NOT recommended for this POC**.

## 📂 File Location

The bootstrap example has been moved to:
```
docs/examples/infra_bootstrap.exemplo.yaml
```

## 🚫 Why NOT Use Bootstrap for This POC?

### Security Concerns
- Requires **highly privileged** service connection (Owner or User Access Administrator)
- Automates RBAC assignments that should be reviewed manually
- Not suitable for learning/educational purposes

### Complexity
- Adds unnecessary complexity to POC setup
- Manual steps provide better understanding of the architecture
- Easier to troubleshoot when done manually

### Best Practice
- Infrastructure bootstrap should be done once per organization/subscription
- Not meant to be repeated for every POC or environment

## ✅ Recommended Approach (Manual Setup)

Follow the **[Azure DevOps Setup Guide](03-devops-setup.md)** instead, which provides:
- Step-by-step manual instructions
- Better learning experience
- More control over each step
- Easier troubleshooting

## 📖 What's Inside the Bootstrap File?

For reference, the bootstrap pipeline typically includes:

### Stage 1: Prerequisites
- Validates Azure CLI authentication
- Checks subscription access
- Verifies required permissions

### Stage 2: Resource Group Creation
```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: 'POC-Azure-Connection-Privileged'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az group create \
        --name $(resourceGroupName) \
        --location $(location) \
        --tags environment=$(environment)
```

### Stage 3: Service Connection Setup
- Creates Azure AD App Registration
- Configures Federated Credentials
- Assigns RBAC roles
- Creates Azure DevOps service connection via API

### Stage 4: RBAC Assignments
- Reader role on Subscription
- Contributor role on Resource Group
- Other custom roles as needed

## 🔐 When WOULD You Use Bootstrap?

Bootstrap automation is appropriate for:

### Enterprise Scenarios
- **Multi-tenant** setups with many subscriptions
- **Standardized** environment provisioning
- **Governed** with approval workflows
- **Audited** with proper logging

### Requirements
- ✅ Mature DevOps practices in place
- ✅ Security team approval
- ✅ Audit trail requirements met
- ✅ Proper governance framework

### Example Use Cases
- Creating 50+ dev environments automatically
- Standardizing across multiple business units
- Regulated industries with compliance requirements

## 🛠️ How to Adapt Bootstrap (If Needed)

If you decide to use bootstrap in the future, here's how to adapt it:

### 1. Create Privileged Service Connection

Manually create a service connection with elevated permissions:
- Azure DevOps > Service connections > New
- Scope: **Subscription** (not Resource Group)
- Role: **Owner** or **User Access Administrator**
- Name: `POC-Azure-Connection-Privileged`

### 2. Update Variables

In the bootstrap YAML file, update:

```yaml
variables:
  azureSubscription: 'POC-Azure-Connection-Privileged'
  subscriptionId: 'YOUR-SUBSCRIPTION-ID'
  resourceGroupName: 'your-rg-name'
  location: 'brazilsouth'
  environment: 'dev'
  serviceConnectionName: 'POC-Azure-Connection'
```

### 3. Add Approval Gates

Configure pipeline to require approval before:
- Creating service connections
- Assigning RBAC roles
- Creating resources

### 4. Run with Caution

- Review all steps before running
- Have rollback plan ready
- Monitor Azure Activity Log
- Document what was created

## 📋 Bootstrap vs Manual Comparison

| Aspect | Bootstrap | Manual (Recommended) |
|--------|-----------|---------------------|
| **Setup Time** | ~15 minutes | ~30 minutes |
| **Learning Value** | Low | High |
| **Security Risk** | Higher | Lower |
| **Troubleshooting** | Harder | Easier |
| **Control** | Less | More |
| **Repeatability** | High | Medium |
| **Auditability** | Automated | Manual logs |
| **Best For** | Production/Scale | POC/Learning |

## 🎓 Key Takeaways

1. ✅ **For this POC:** Use manual setup (Guide 03)
2. ✅ **For learning:** Manual is better
3. ✅ **For production:** Consider bootstrap with proper governance
4. ⚠️ **Security first:** Never blindly run privileged automation
5. 📚 **Understand first:** Know what bootstrap does before using it

## ⏭️ What's Next?

Instead of using bootstrap, proceed with:

👉 **[Azure DevOps Setup (Manual)](03-devops-setup.md)** - Recommended path

## 📚 Additional Resources

- [Azure DevOps Pipeline Security](https://learn.microsoft.com/azure/devops/pipelines/security/)
- [Service Connection Security](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints#secure-a-service-connection)
- [Azure RBAC Best Practices](https://learn.microsoft.com/azure/role-based-access-control/best-practices)

---

**Navigation:** [🏠 Home](../../README.md) | [📚 Documentation Index](../README.md)