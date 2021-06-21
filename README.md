# scrape-azure-status-history
Scraping script for Azure Status History (https://status.azure.com/ja-jp/status/history/)

# Hot to use

Just run powershell script .

```powershell
.\Scrape-AzureStatusHistory.ps1
```

This script return PowerShell Objects for data, so you can use normal powershell pipeline.

```powershell
# filtering sample
.\Scrape-AzureStatusHistory.ps1 | where {$_.trackingId -eq 'GVD7-RDZ'}

# retrieve as json
.\Scrape-AzureStatusHistory.ps1 | ConvertTo-Json
```

