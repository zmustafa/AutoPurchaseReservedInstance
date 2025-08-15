<#
.SYNOPSIS
    PowerShell script to call Azure Reservation APIs Logic Apps (CreateReservation and PurchaseReservation).

.DESCRIPTION
    It supports two operations: creating a reservation and purchasing a reservation, with parameters for all required inputs.
    The appliedScopes parameter is set to null if appliedScopeType is 'Shared', otherwise it is set as an array with a single value.

.PARAMETER Operation
    Specifies the API operation to perform: 'CreateReservation' or 'PurchaseReservation'.

.PARAMETER SkuName
    The SKU name for the reservation (default: "Standard_B1s").

.PARAMETER Location
    The Azure region for the reservation (e.g., "eastus").

.PARAMETER ReservedResourceType
    The type of reserved resource (default: "VirtualMachines").

.PARAMETER BillingScopeId
    The billing scope ID (default: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").

.PARAMETER Term
    The reservation term (e.g., "P1Y", "P3Y", "P5Y"; default: "P1Y").

.PARAMETER Quantity
    The quantity of the reservation (default: 1).

.PARAMETER AppliedScopeType
    The scope type for the reservation: 'Single' or 'Shared' (default: "Single").

.PARAMETER AppliedScopes
    The applied scopes value (default: "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"). Ignored if AppliedScopeType is 'Shared'.
    Must be a valid Azure subscription path (e.g., "/subscriptions/<GUID>").

.PARAMETER DisplayName
    The display name for the reservation (default: "VM_RI_" + current date/time).

.PARAMETER InstanceFlexibility
    Instance flexibility setting (default: "On").

.PARAMETER Renew
    Whether to enable auto-renewal (default: $true).

.PARAMETER BillingPlan
    The billing plan: 'Upfront' or 'Monthly' (default: "Upfront").

.PARAMETER ReservedResourceInstanceFlexibility
    Reserved resource instance flexibility (default: "On").

.PARAMETER ReservationOrderId
    The reservation order ID (required for PurchaseReservation operation).

.EXAMPLE
    .\AzureReservation.ps1 -Operation CreateReservation -SkuName "Standard_B1s" -Location "eastus" -Term "P1Y" -Quantity 1 -AppliedScopeType "Single" -AppliedScopes "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -Verbose

    Creates a reservation with the specified parameters.

.EXAMPLE
    .\AzureReservation.ps1 -Operation PurchaseReservation -ReservationOrderId "12345" -SkuName "Standard_B1s" -Location "eastus" -Term "P1Y" -Quantity 1 -AppliedScopeType "Shared" -Verbose

    Purchases a reservation with the specified reservation order ID, setting appliedScopes to null.

.NOTES
    Requires the `Invoke-RestMethod` cmdlet for making HTTP requests.
    Compatible with Windows PowerShell 5.1 and later.
    Ensure you have the necessary permissions and API endpoints are accessible.
#>

param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("CreateReservation", "PurchaseReservation")]
    [string]$Operation,

    [string]$SkuName = "Standard_B1s",
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "eastus", "eastus2", "southcentralus", "westus2", "westus3", "australiaeast", "australiasoutheast",
        "brazilsouth", "canadacentral", "canadaeast", "centralus", "northcentralus", "westus",
        "northeurope", "westeurope", "francecentral", "francesouth", "germanynorth", "germanywestcentral",
        "norwayeast", "norwaywest", "swedencentral", "switzerlandnorth", "switzerlandwest", "ukwest", "uksouth",
        "eastasia", "southeastasia", "centralindia", "japaneast", "japanwest", "koreacentral", "koreasouth"
    )]
    [string]$Location,

    [string]$ReservedResourceType = "VirtualMachines",
    [Parameter(Mandatory = $true)]
    [string]$BillingScopeId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    [Parameter(Mandatory = $true)]
    [ValidateSet("P1Y", "P3Y", "P5Y")]
    [string]$Term = "P1Y",
    [Parameter(Mandatory = $true)]
    [int]$Quantity = 1,
    [ValidateSet("Single", "Shared")]
    [string]$AppliedScopeType = "Single",
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^/subscriptions/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$AppliedScopes = "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    [string]$DisplayName = ("VM_RI_" + (Get-Date -Format "MM-dd-yyyy_HH-mm")),
    [string]$InstanceFlexibility = "On",
    [bool]$Renew = $true,
    [ValidateSet("Upfront", "Monthly")]
    [string]$BillingPlan = "Upfront",
    [string]$ReservedResourceInstanceFlexibility = "On",
    [string]$ReservationOrderId,
    [Parameter(Mandatory = $true)]
    [string]$logicAppUrl="https://....logic.azure.com:443/workflows"
)

# Function to create the reservation
function Invoke-CreateReservation {
    param (
        [hashtable]$Body,
        [string]$uri
    )

    Write-Verbose "Constructed URI: $uri"
    Write-Verbose "Request Body: $($Body | ConvertTo-Json -Depth 10)"

    # Validate URI
    try {
        $null = [System.Uri]::new($uri)
        Write-Verbose "URI validation passed."
    }
    catch {
        Write-Error "Invalid URI format: $_"
        return $null
    }

    

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body ($Body | ConvertTo-Json -Depth 10) -ContentType "application/json" -ErrorAction Stop
       

        # Extract reservationOrderId if present
        if ($response.properties -and $response.properties.reservationOrderId) {
            return $response.properties.reservationOrderId
        }
        return $null
    }
    catch {
        Write-Error "Failed to create reservation: $_"
        return $null
    }
}

# Function to purchase the reservation
function Invoke-PurchaseReservation {
    param (
        [hashtable]$Body,
        [string]$uri
    )

    #$baseUriPurchase = "https://prod-29.eastus.logic.azure.com:443/workflows/2d7a4a705957445b88b93c5fec882e04/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=6cgLJ7BRhKPCkkW_pjnXQ6PC81zLQkRRufuFnUaaMGU"
    #$uri = "$baseUriPurchase"

    Write-Verbose "Constructed URI: $uri"
    Write-Verbose "Request Body: $($Body | ConvertTo-Json -Depth 10)"

    # Validate URI
    try {
        $null = [System.Uri]::new($uri)
        Write-Verbose "URI validation passed."
    }
    catch {
        Write-Error "Invalid URI format: $_"
        return $null
    }

    

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body ($Body | ConvertTo-Json -Depth 10) -ContentType "application/json" -ErrorAction Stop
        Write-Output "PurchaseReservation Response: $($response | ConvertTo-Json -Depth 10)"
    }
    catch {
        Write-Error "Failed to purchase reservation: $_"
    }
}

# Validate AppliedScopes if AppliedScopeType is Single
if ($AppliedScopeType -eq "Single" -and -not $AppliedScopes) {
    Write-Error "AppliedScopes is required when AppliedScopeType is 'Single'."
    exit 1
}

# Handle appliedScopes based on AppliedScopeType 

[string[]]$typedStringArray

if ($AppliedScopeType -eq "Shared" -and $Operation -eq "CreateReservation") {
[string[]]$typedStringArray = null
}
else {
[string[]]$typedStringArray = $AppliedScopes
}
 

# Create the request body
$requestBody = @{
    sku_name                                 = $SkuName
    location                                 = $Location
    properties_reservedResourceType           = $ReservedResourceType
    properties_billingScopeId                = $BillingScopeId
    properties_term                          = $Term
    properties_quantity                      = $Quantity
    properties_appliedScopeType              = $AppliedScopeType
    properties_displayName                   = $DisplayName
    properties_instanceFlexibility           = $InstanceFlexibility
    properties_renew                         = $Renew
    properties_billingPlan                   = $BillingPlan
    properties_reservedResourceProperties_instanceFlexibility = $ReservedResourceInstanceFlexibility
    properties_appliedScopes                 = $typedStringArray
}

# Add reservationOrderId for PurchaseReservation
if ($Operation -eq "PurchaseReservation") {
    if (-not $ReservationOrderId) {
        Write-Error "ReservationOrderId is required for PurchaseReservation operation."
        exit 1
    }
    $requestBody.reservationOrderId = $ReservationOrderId
}

# Execute the specified operation
switch ($Operation) {
    "CreateReservation" { 
        $orderId = Invoke-CreateReservation -Body $requestBody -uri $logicAppUrl
        if ($orderId) {
            Write-Output "Reservation Order ID: $orderId"
        }
    }
    "PurchaseReservation" {
        Write-Host "Are you sure you want to purchase the reservation? (Y/N)"
        $confirmation = Read-Host
        if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
            Invoke-PurchaseReservation -Body $requestBody -uri $logicAppUrl
        }
        else {
            Write-Output "Purchase cancelled."
        }
    }
    default {
        Write-Error "Invalid operation specified: $Operation"
    }
}