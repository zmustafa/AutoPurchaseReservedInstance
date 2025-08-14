# AutoPurchaseReservedInstance

1. Create a managed identity ManagedIdentity-RIPurchasherAccess
2. Assign 'ManagedIdentity-RIPurchasherAccess' reader on tenant root group
3. Assign 'ManagedIdentity-RIPurchasherAccess' RBAC of 'Reservations Contributor' under IAM of 'Reservations' blade
4. Create a blank logic app call it 'LogicApp-Approved-Subscriptions-Updater'
5. Modify logic app 'LogicApp-Approved-Subscriptions-Updater' to use the user generated managed identity 'ManagedIdentity-RIPurchasherAccess'
6. Clone the logic app 'LogicApp-Approved-Subscriptions-Updater' to two more logic apps 'LogicApp-RI-Calculate' and 'LogicApp-RI-Purchase' (in total they become 3)
