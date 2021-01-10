$subscriptionName = "LefeWare-Solutions"
$location = "eastus"

# Connect to Azure and Set Subscription 
Connect-AzAccount
$context = Get-AzSubscription -SubscriptionName $subscriptionName
Set-AzContext $context
New-AzResourceGroup -Name $resourceGroupName -Location $location

#############################################VNETS and Peering########################################
$hubVNetName = "HubVNet";
$hubNetworkingRGName = "HubNetworkingRG"
$project1SpokeVNetName = "Project1SpokeVNet"
$project1SpokeNetowrkingRGName = "project1SpokeNetowrkingRG";

$hubVNet = New-AzVirtualNetwork `
  -ResourceGroupName $hubNetworkingRGName `
  -Location $location `
  -Name $hubVNetName `
  -AddressPrefix 10.0.0.0/16

$project1SpokeVNet= New-AzVirtualNetwork `
  -ResourceGroupName $project1SpokeNetowrkingRGName `
  -Location $location `
  -Name $project1SpokeVNetName `
  -AddressPrefix 10.0.0.0/16

Add-AzVirtualNetworkPeering `
  -Name "$hubVNetName-$project1SpokeVNetName" `
  -VirtualNetwork $hubVNet `
  -RemoteVirtualNetworkId $project1SpokeVNet.Id
 
Add-AzVirtualNetworkPeering `
  -Name "$project1SpokeVNetName-$hubVNetName" `
  -VirtualNetwork $project1SpokeVNet `
  -RemoteVirtualNetworkId $hubVNet.Id
 
#############################################Subnet Creation########################################  
$appGWSubnetName = "AppGatewaySubnet"; 
$aksSubnetName = "AKSSubnet";
$managementSubnetName = "ManagementSubnet"

$appGWSubnetConfig = Add-AzVirtualNetworkSubnetConfig `
      -Name $appGWSubnetName `
      -AddressPrefix 10.0.0.0/24 `
      -VirtualNetwork $hubVNet `
$hubVNet | Set-AzVirtualNetwork


$aksSubnetConfig = Add-AzVirtualNetworkSubnetConfig `
      -Name $aksSubnetName `
      -AddressPrefix 10.0.0.0/24 `
      -VirtualNetwork $project1SpokeVNet `
$project1SpokeVNet | Set-AzVirtualNetwork

#############################################Application Gateway#############################################  


#############################################Azure Kubernetes Service########################################  