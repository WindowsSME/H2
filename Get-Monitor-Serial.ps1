<#
author: james romeo gaspar
date: 26 September 2023
description: script to get serial number of all attached monitors (if available in WMI)
#>

try {

    $monitorInfo = Get-WmiObject -Namespace "root\WMI" -Class "WmiMonitorID"
    $monitors = Get-WmiObject -Namespace "root\cimv2" -Class "Win32_PnPEntity" | Where-Object { $_.Service -like "*monitor*" }
    $monitorInfoTable = @{}
    foreach ($monitor in $monitorInfo) {
        $instanceName = $monitor.InstanceName -replace "_0$"
        $monitorInfoTable[$instanceName] = $monitor
    }
    $monitorCounter = 1
    $monitorInfoArray = @()

    foreach ($monitor in $monitors) {
        $deviceID = $monitor.DeviceID
        $matchingInstance = $monitorInfoTable.Keys | Where-Object { $deviceID -like "*$_*" }

        if ($matchingInstance) {
            $wmiMonitor = $monitorInfoTable[$matchingInstance]
            $serialNumberBytes = $wmiMonitor.SerialNumberID
            $serialNumberBytes = $serialNumberBytes | Where-Object { $_ -ne 0 }

            if ($serialNumberBytes.Length -eq 0) {
                $serialNumber = "Serial Number not available."
            } else {
                $serialNumber = [System.Text.Encoding]::ASCII.GetString($serialNumberBytes)
            }
            $monitorLabel = "Monitor $monitorCounter"
            $monitorInfoArray += "${monitorLabel}: $serialNumber ($($monitor.Description))"
            $monitorCounter++
        }
    }
    $monitorInfoString = $monitorInfoArray -join " | "
    $monitorInfoString = $monitorInfoString -replace '\s*\|\s*', ' | '

    Write-Host $monitorInfoString

} catch {
    Write-Host "An error occurred: $_.Exception.Message"
}
