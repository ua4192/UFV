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
$DHCPLeaseTime = 8 # En días

# Configurar la IP estática
$Interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
New-NetIPAddress -InterfaceIndex $Interface.ifIndex -IPAddress $StaticIP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceIndex $Interface.ifIndex -ServerAddresses $DNSServer

# Cambiar el hostname
Rename-Computer -NewName $Hostname -Force
Restart-Computer -Force

# Instalar los roles necesarios
Install-WindowsFeature -Name AD-Domain-Services,DNS,DHCP -IncludeManagementTools

# Promover el servidor a controlador de dominio
Import-Module ADDSDeployment
Install-ADDSForest -DomainName $DomainName -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode 7 -ForestMode 7 -InstallDns:$true -LogPath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL" -NoRebootOnCompletion:$false -Force:$true

# Configurar DHCP
netsh dhcp add securitygroups
Restart-Service DHCPServer
Add-DhcpServerv4Scope -Name "MainScope" -StartRange $DHCPScopeStart -EndRange $DHCPScopeEnd -SubnetMask $DHCPSubnetMask -LeaseDuration (New-TimeSpan -Days $DHCPLeaseTime)
Set-DhcpServerv4OptionValue -DnsDomain $DomainName -DnsServer $StaticIP -Router $Gateway
Set-DhcpServerv4DnsSetting -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $true -UpdateConflicts $true

# Configurar NTP
w32tm /config /manualpeerlist:"es.pool.ntp.org" /syncfromflags:manual /update
Set-TimeZone -Id "Romance Standard Time"
Restart-Service w32time

Write-Host "Configuración completada. Reinicia el servidor si es necesario."

# Comprobar Active Directory (AD DS)
Get-Service NTDS
dcdiag /v
nltest /dclist:UFV.org

# Comprobar el Servidor DNS
nslookup UFVDC1
Get-Service DNS

# Comprobar el Servidor DHCP
Get-Service DHCPServer
Get-DhcpServerv4Scope

# Comprobar el Servidor NTP
w32tm /query /configuration
w32tm /query /status
#Restart-Service w32time


# Crear usuario Integrator con permisos para agregar máquinas al dominio
New-ADUser -Name "Integrator" -SamAccountName "Integrator" -UserPrincipalName "Integrator@$DomainName" -Path "CN=Users,DC=UFV,DC=org" -AccountPassword (ConvertTo-SecureString "P@ssword123" -AsPlainText -Force) -Enabled $true
Add-ADGroupMember -Identity "Domain Admins" -Members "Integrator"

# Crear usuarios normales
New-ADUser -Name "user1" -SamAccountName "user1" -UserPrincipalName "user1@$DomainName" -Path "CN=Users,DC=UFV,DC=org" -AccountPassword (ConvertTo-SecureString "P@ssword123" -AsPlainText -Force) -Enabled $true
New-ADUser -Name "user2" -SamAccountName "user2" -UserPrincipalName "user2@$DomainName" -Path "CN=Users,DC=UFV,DC=org" -AccountPassword (ConvertTo-SecureString "P@ssword123" -AsPlainText -Force) -Enabled $true

Write-Host "Configuración completada. Reinicia el servidor si es necesario."
