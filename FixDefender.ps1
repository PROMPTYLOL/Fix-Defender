#Requires -RunAsAdministrator

function Fix-WindowsDefender {
    Write-Host "Starting Windows Defender repair process..." -ForegroundColor Green

    try {
        # Enable Windows Defender services
        $services = @(
            "WinDefend",
            "SecurityHealthService",
            "wscsvc",
            "WdNisSvc",
            "Sense"
        )

        foreach ($service in $services) {
            Write-Host "Enabling service: $service" -ForegroundColor Yellow
            Set-Service -Name $service -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $service -ErrorAction SilentlyContinue
        }

        # Reset Windows Defender policies
        Write-Host "Resetting Windows Defender policies..." -ForegroundColor Yellow
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue

        # Try to reset Windows Security Center with multiple fallback options
        Write-Host "Attempting to reset Windows Security..." -ForegroundColor Yellow
        try {
            Get-AppxPackage Microsoft.SecHealthUI -AllUsers | Reset-AppxPackage
        }
        catch {
            Write-Host "Basic reset failed, attempting full reset..." -ForegroundColor Yellow
            try {
                Get-AppxPackage Microsoft.SecHealthUI -AllUsers | Remove-AppxPackage -ErrorAction Stop
                Get-AppxPackage Microsoft.SecHealthUI -AllUsers | Add-AppxPackage -Register "$env:SystemRoot\WindowsApps\Microsoft.SecHealthUI_*\AppxManifest.xml" -ErrorAction Stop
            }
            catch {
                Write-Host "Full reset failed, attempting reinstall..." -ForegroundColor Yellow
                try {
                    # Download and install from Microsoft Store (requires wsreset.exe and MS Store access)
                    Start-Process "ms-windows-store://pdp/?productid=9P7O5Z161RCB"
                    Write-Host "Microsoft Store opened. Please complete the Windows Security installation manually." -ForegroundColor Yellow
                }
                catch {
                    Write-Host "All reset attempts failed. Please try manual reinstallation." -ForegroundColor Red
                }
            }
        }

        # Run Windows Defender scan
        Write-Host "Starting quick scan..." -ForegroundColor Yellow
        Start-MpScan -ScanType QuickScan

        Write-Host "Windows Defender repair process completed." -ForegroundColor Green
    }
    catch {
        Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Run the function
Fix-WindowsDefender