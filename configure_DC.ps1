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

# Cambiar el hostname (SIN REINICIAR)
Rename-Computer -NewName $Hostname -Force

# Instalar los roles necesarios
Install-WindowsFeature -Name AD-Domain-Services,DNS,DHCP -IncludeManagementTools

# Promover el servidor a controlador de dominio (SIN REINICIAR AUTOMÁTICO)
Import-Module ADDSDeployment
Install-ADDSForest -DomainName $DomainName -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode 7 -ForestMode 7 -InstallDns:$true -LogPath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL" -NoRebootOnCompletion:$true -Force:$true

# Configuración de DHCP (se ejecutará después del reinicio para asegurar que AD y DNS están operativos)
$DhcpConfigScript = @'
netsh dhcp add securitygroups
Restart-Service DHCPServer
Add-DhcpServerv4Scope -Name "MainScope" -StartRange 192.168.1.100 -EndRange 192.168.1.200 -SubnetMask 255.255.255.0 -LeaseDuration (New-TimeSpan -Days 8)
Set-DhcpServerv4OptionValue -DnsDomain UFV.org -DnsServer 192.168.1.253 -Router 192.168.1.1
Set-DhcpServerv4DnsSetting -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $true -UpdateConflicts $true
'@
$DhcpConfigScript | Out-File -FilePath C:\PostReboot_DHCP.ps1

# Configurar NTP
w32tm /config /manualpeerlist:"es.pool.ntp.org" /syncfromflags:manual /update
Set-TimeZone -Id "Romance Standard Time"
Restart-Service w32time

# Agregar script post-reinicio al programador de tareas (se ejecutará tras el reinicio)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\PostReboot_DHCP.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "PostReboot_DHCP_Config" -Action $action -Trigger $trigger -RunLevel Highest -User "SYSTEM"

Write-Host "Configuración completada. El sistema se reiniciará ahora."
Restart-Computer -Force

# (Después del reinicio, DHCP se configurará automáticamente mediante el script agendado)
