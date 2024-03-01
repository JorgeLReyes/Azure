# 1. Una suscripción seleccionada y un grupo de recursos nuevo
New-AzResourceGroup -Name $resourceGroupName -Location $location

# 7. Una dirección IP pública.
$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Static -Name $publicIpName
$publicIp.IpAddress

# 5. Una red virtual asociada: deberás crearla también como código.
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name $vnetName -AddressPrefix $vnetIP
$subnetConfig = Add-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetIP -VirtualNetwork $vnet
$vnet = $vnet | Set-AzVirtualNetwork

# 6. Una dirección IP privada (la cual es obligatoria y debe estar asociada a la red anterior).
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName
$ipConfigName = "miIPConfig"
$ipConfig = New-AzNetworkInterfaceIpConfig -Name $ipConfigName -Subnet $subnet -PrivateIpAddress $privateIpAddress
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name "miNIC" -IpConfiguration $ipConfig
Get-AzNetworkInterface - Name "miNIC" -ResourceGroupName $resourceGroupName

# 8. Una regla de acceso que te permita acceder por RDP una vez que finalice la creación del equipo.
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name "RDPAccess" -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 3389 -Access Allow
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsgName -SecurityRules $nsgRuleRDP
$nic = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name "miNIC"
$nic.NetworkSecurityGroup = $nsg
$nic | Set-AzNetworkInterface

# 2. Un sistema operativo basado en Windows o Linux (el que quieras).
$nic = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name "miNIC"
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential (Get-Credential)
$vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2016-Datacenter" -Version "latest"
$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

# 3. Un disco de sistema operativo Premium.
$vmConfig = Set-AzVMOSDisk -VM $vmConfig -CreateOption FromImage -DiskName 'miOsDisk'
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
