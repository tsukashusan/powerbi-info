Import-Module -Name MicrosoftPowerBIMgmt 

#サインイン
Connect-PowerBIServiceAccount

#ワークスペース一覧を取得
$apiUrl = "https://api.powerbi.com/v1.0/myorg/admin/workspaces/modified"
$workspaces = Invoke-PowerBIRestMethod -Url $apiUrl -Method GET | ConvertFrom-Json

$allWorkSpaces = @()
foreach ($workspaceid in $workspaces) {
  $id = $workspaceid[0].id
  $body = @"
{
  "workspaces": [
    "${id}"
  ]
}
"@
  #Workspace の Admin - WorkspaceInfo PostWorkspaceInfo https://learn.microsoft.com/ja-jp/rest/api/power-bi/admin/workspace-info-post-workspace-info
  $apiUrl = "https://api.powerbi.com/v1.0/myorg/admin/workspaces/getInfo" 
  $response = Invoke-PowerBIRestMethod -Url $apiUrl -Method Post -Body $body | ConvertFrom-Json
  $id = $response.id
  #Workspace の Admin - WorkspaceInfo GetScanResult  WorkspaceInfo PostWorkspaceInfoで取得したScan ID をパラメータとする　https://learn.microsoft.com/ja-jp/rest/api/power-bi/admin/workspace-info-get-scan-result
  $apiUrl = "https://api.powerbi.com/v1.0/myorg/admin/workspaces/scanResult/${id}"
  #Write-Output $apiUrl
  $response = Invoke-PowerBIRestMethod -Url $apiUrl -Method Get | ConvertFrom-Json
  $workspaceInfo = $response
  #Write-Output $workspaceInfo.workspaces.reports
  
  foreach ($report in $workspaceInfo.workspaces.reports) {
    $reportId = $report.id
    Write-Output $report.id
    Write-Output $report.name
    $apiUrl = "https://api.powerbi.com/v1.0/myorg/admin/reports/${reportId}/users"
    $response = Invoke-PowerBIRestMethod -Url $apiUrl -Method Get | ConvertFrom-Json
    Write-Output $response.value
    $customObject = New-Object -TypeName PSObject -Property @{
      WorkspaceId           = $workspaceInfo.workspaces.id
      WorkspacesName        = $workspaceInfo.workspaces.name
      WorkspaceType         = $workspaceInfo.workspaces.type
      reportName            = $report.name
      reportUserAccessRight = $response.value.reportUserAccessRight
      emailAddress          = $response.value.emailAddress
      displayName           = $response.value.displayName
      identifier            = $response.value.identifier
      principalType         = $response.value.principalType
      userType              = $response.value.userType
    }
    $allWorkSpaces += $customObject
  }
  
}
#CSV ファイルに出力
$csvFilePath = './AllWorkspaces.csv'
$allWorkSpaces | Export-Csv -Path $csvFilePath -NoTypeInformation -Encoding UTF8
