# Definir variables
$StaticIP = "192.168.1.253"
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.1.1"
$DNSServer = "127.0.0.1"
$Hostname = "UFVDC1"
$DomainName = "UFV.org"
$DHCPScopeStart = "192.168.1.100"
$DHCPScopeEnd = "192.168.1.200"
$DHCPSubnetMask = "255.255.255.0"
$DHCPLeaseTime = 8 

# Configurar la IP estática
$Interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
New-NetIPAddress -InterfaceIndex $Interface.ifIndex -IPAddress $StaticIP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceIndex $Interface.ifIndex -ServerAddresses $DNSServer

# Cambiar el hostname
Rename-Computer -NewName $Hostname -Force
Restart-Computer -Force

# End
