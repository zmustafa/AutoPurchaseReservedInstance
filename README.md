# AutoPurchaseReservedInstance

Create a managed identity ManagedIdentity-RIPurchasherAccess
Assign 'ManagedIdentity-RIPurchasherAccess' reader on tenant root group
Assign 'ManagedIdentity-RIPurchasherAccess' RBAC of 'Reservations Contributor' under IAM of 'Reservations' blade
Create a blank logic app call it 'LogicApp-Approved-Subscriptions-Updater'
Modify logic app 'LogicApp-Approved-Subscriptions-Updater' to use the user generated managed identity 'ManagedIdentity-RIPurchasherAccess'
Clone the logic app 'LogicApp-Approved-Subscriptions-Updater' to two more logic apps 'LogicApp-RI-Calculate' and 'LogicApp-RI-Purchase' (in total they become 3)
