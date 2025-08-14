# Automatically Purchase Reserved Instance in Azure

# Introduction
This utility allows to setup logic apps which can be invoked to purchase Azure Reserved Instances.

# Components
## Server Side
There is one managed identity, one storage account, and 3 logic apps

### Managed Identity
The user-assigned managed identity (MI) is used across the utility to grant access to Azure. The MI is granted access as Reader on the Tenant Root Group level (to be able to find approved subscriptions), granted Storage Table Data Contributor to the storage account (to read and write approved subscriptions), granted 'Reservations Contributor' to the 'Reserveations' to be able to make RI purchases. On the other hand, the three logic apps have the 'Identities' set to use this MI so that they can impersonate the access the MI has.

### Storage Account
The Azure Storage Account uses Azure Tables only. The storage account is used to keep a list of approved Azure Subscriptions that can be used by the client when providing billing scope. The Azure Storage Table has empty schema (with no data) and only the Partition Key and Row ID are used as the Subscription ID for each of the approved subscription.

The utility can be restricted to allow purchase of RIs under a specific billing scope only. 

The list of approved subscriptions that can be used as an approved billing scope can be automatically maintained using another provided logic app, which takes argument of a parent Management Group and all subscriptions underneath are automatically added to the approved list of subscriptions where an RI purchase can be made.


## Client Side
The HTTP calls to the Logic App to invoke calculate/purchase API can either be made using the provided C# WinForms app or provided PowerShell script.

# Steps to setup 
1. Create a managed identity ManagedIdentity-RIPurchasherAccess
2. Assign 'ManagedIdentity-RIPurchasherAccess' reader on tenant root group
3. Assign 'ManagedIdentity-RIPurchasherAccess' RBAC of 'Reservations Contributor' under IAM of 'Reservations' blade
4. Create a blank logic app call it 'LogicApp-Approved-Subscriptions-Updater'
5. Modify logic app 'LogicApp-Approved-Subscriptions-Updater' to use the user generated managed identity 'ManagedIdentity-RIPurchasherAccess'
6. Clone the logic app 'LogicApp-Approved-Subscriptions-Updater' to two more logic apps 'LogicApp-RI-Calculate' and 'LogicApp-RI-Purchase' (in total they become 3)
