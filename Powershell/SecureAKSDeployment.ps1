$subscriptionName = "LefeWare-Solutions"
$location = "eastus"

# Connect to Azure and Set Subscription 
Connect-AzAccount
$context = Get-AzSubscription -SubscriptionName $subscriptionName
Set-AzContext $context
New-AzResourceGroup -Name $resourceGroupName -Location $location

#############################################VNets Creation########################################
$hubVNetName = "HubVNet";
$hubNetworkingRGName = "HubNetworking-RG"
$project1SpokeVNetName = "Project1SpokeVNet"
$project1SpokeNetowrkingRGName = "project1SpokeNetowrking-RG";

#Create Hub VNet
New-AzResourceGroup -Name $hubNetworkingRGName -Location $location
$hubVNet = New-AzVirtualNetwork `
-ResourceGroupName $hubNetworkingRGName `
-Location $location `
-Name $hubVNetName `
-AddressPrefix 10.5.0.0/16

#Create Spoke1 VNet 
New-AzResourceGroup -Name $project1SpokeNetowrkingRGName -Location $location
$project1SpokeVNet= New-AzVirtualNetwork `
  -ResourceGroupName $project1SpokeNetowrkingRGName `
  -Location $location `
  -Name $project1SpokeVNetName `
  -AddressPrefix 10.6.0.0/16

#######################################VNets Peering########################################
Add-AzVirtualNetworkPeering `
  -Name "$hubVNetName-$project1SpokeVNetName" `
  -VirtualNetwork $hubVNet `
  -RemoteVirtualNetworkId $project1SpokeVNet.Id
 
Add-AzVirtualNetworkPeering `
  -Name "$project1SpokeVNetName-$hubVNetName" `
  -VirtualNetwork $project1SpokeVNet `
  -RemoteVirtualNetworkId $hubVNet.Id
 
####################################Hub Subnets Creation########################################  
$appGWHubSubnetName = "AppGatewaySubnet"; 
$managementHubSubnetName = "ManagementSubnet"

$appGWSubnetConfig = Add-AzVirtualNetworkSubnetConfig `
      -Name $appGWHubSubnetName `
      -AddressPrefix 10.5.0.0/26 `
      -VirtualNetwork $hubVNet `
$hubVNet | Set-AzVirtualNetwork

$managementSubnetConfig = Add-AzVirtualNetworkSubnetConfig `
      -Name $managementHubSubnetName `
      -AddressPrefix 10.5.0.0/26 `
      -VirtualNetwork $project1SpokeVNet `
$project1SpokeVNet | Set-AzVirtualNetwork

######################################Spoke Subnets Creation########################################  
$aksSpokeSubnetName = "AKSSubnet";
$paasSpokeSubnetName = "PaaSSubnet"

$aksSubnetConfig = Add-AzVirtualNetworkSubnetConfig `
      -Name $aksSpokeSubnetName `
      -AddressPrefix 10.6.0.0/26 `
      -VirtualNetwork $project1SpokeVNet `
$project1SpokeVNet | Set-AzVirtualNetwork

$paasSubnetConfig = Add-AzVirtualNetworkSubnetConfig `
      -Name $paasSpokeSubnetName `
      -AddressPrefix 10.6.0.0/24 `
      -VirtualNetwork $project1SpokeVNet `
$project1SpokeVNet | Set-AzVirtualNetwork

########################################AKS Deployment############################################## 
$aksRGName = "AKS-RG"
$aksClusterName = "PrivateAKSCluster"
$nodeCount = 1
New-AzResourceGroup -Name $aksRGName -Location $location

#Powershell does not support private clusters at this time: https://github.com/MicrosoftDocs/azure-docs/issues/62628#issuecomment-695898184
az aks create `
    --resource-group $aksRGName `
    --name $aksClusterName `
    --load-balancer-sku standard `
    --enable-private-cluster `
    --network-plugin azure `
    --vnet-subnet-id $aksSubnetConfig.Id `
    --docker-bridge-address 172.17.0.1/16 `
    --dns-service-ip 10.2.0.10 `
    --service-cidr 10.2.0.0/24 

######################################Application Gateway#############################################  
