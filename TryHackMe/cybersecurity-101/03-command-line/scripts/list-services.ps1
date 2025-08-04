# List all running services and export to a text file

Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object Name, DisplayName, Status | Out-File running_services.txt

Write-Host "List of running services saved to running_services.txt"
