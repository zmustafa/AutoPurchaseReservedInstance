# Automatically Purchase Reserved Instance in Azure

# 1. Introduction
This utility allows to automatically purchase Azure Reserved Instances via simplified PowerShell script.


# 2. Components
## 2.1 Server Side
There is one managed identity, one storage account, and 3 logic apps

### 2.1.1 Managed Identity
The user-assigned managed identity (MI) is used across the utility to grant access to Azure. The MI is granted access as Reader on the Tenant Root Group level (to be able to find approved subscriptions), granted Storage Table Data Contributor to the storage account (to read and write approved subscriptions), granted 'Reservations Contributor' to the 'Reserveations' to be able to make RI purchases. On the other hand, the three logic apps have the 'Identities' set to use this MI so that they can impersonate the access the MI has.

### 2.1.2 Storage Account
The Azure Storage Account uses Azure Tables only. The storage account is used to keep a list of approved Azure Subscriptions that can be used by the client when providing billing scope. The Azure Storage Table has empty schema (with no data) and only the Partition Key and Row ID are used as the Subscription ID for each of the approved subscription.

### 2.1.3  Logic Apps
####  2.1.3.1 LogicApp-Approved-Subscriptions-Updater
####  2.1.3.2 LogicApp-RI-Calculate
####  2.1.3.3 LogicApp-RI-Purchase

The utility can be restricted to allow purchase of RIs under a specific billing scope only. 

The list of approved subscriptions that can be used as an approved billing scope can be automatically maintained using another provided logic app, which takes argument of a parent Management Group and all subscriptions underneath are automatically added to the approved list of subscriptions where an RI purchase can be made.


## 2.2 Client Side
The HTTP calls to the Logic App to invoke calculate/purchase API can be made using the provided PowerShell script.

# 3. Steps to setup 
1. Create a managed identity ManagedIdentity-RIPurchasherAccess
2. Assign 'ManagedIdentity-RIPurchasherAccess' reader on tenant root group
3. Assign 'ManagedIdentity-RIPurchasherAccess' RBAC of 'Reservations Contributor' under IAM of 'Reservations' blade
4. Create a blank logic app call it 'LogicApp-Approved-Subscriptions-Updater'
5. Modify logic app 'LogicApp-Approved-Subscriptions-Updater' to use the user generated managed identity 'ManagedIdentity-RIPurchasherAccess'
6. Clone the logic app 'LogicApp-Approved-Subscriptions-Updater' to two more logic apps 'LogicApp-RI-Calculate' and 'LogicApp-RI-Purchase' (in total they become 3)
7. Add storage connector to each of the logic apps.
8. Paste the code, except the connection part at the bottom.
9. Take note of the two URLs of each of the logic apps  'LogicApp-RI-Calculate' and 'LogicApp-RI-Purchase' and to use them via PowerShell script.

# 4 Make a Reserved Instance purchase
## 4.1 Create Reservation Order
```powershell
.\AzureReservation.ps1 -Operation CreateReservation -SkuName "Standard_B1s" -Location "eastus" -Term "P1Y" -Quantity 1 -BillingScopeId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -AppliedScopeType "Shared" -AppliedScopes "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -logicAppUrl "https://xxxxxx.azure.com:443/workflows/xxxxxxxxxxxxxxxxxx2/triggers/When_a_HTTP_request_is_received/..." -Verbose 
```
Output is the Order ID. Take note of this and use it in the next command
```powershell
Reservation Order ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## 4.2 Purchase the Reservation Order
```powershell
.\AzureReservation.ps1 -Operation PurchaseReservation -ReservationOrderId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -SkuName "Standard_B1s" -Location "eastus" -Term "P1Y" -Quantity 1 -BillingScopeId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -AppliedScopeType "Shared" -AppliedScopes "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -logicAppUrl "https://xxxxxx.azure.com:443/workflows/xxxxxxxxxxxxxxxxxx2/triggers/When_a_HTTP_request_is_received/..." -Verbose
```

Confirm purchase
```powershell
Are you sure you want to purchase the reservation? (Y/N) y
```
# 5 Deploy
In order to deploy, you can deploy using the ARM template using the button below then open each of the 3 logic app and update the HTTP Request object to create the newly created managed identity


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fzmustafa%2FAutoPurchaseReservedInstance%2Frefs%2Fheads%2Fmain%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
 
