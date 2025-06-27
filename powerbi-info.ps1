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
    Write-Output $response.Count
    Write-Output $response.workspaces.id
    $customObject = New-Object -TypeName PSObject -Property @{
            WorkspaceId = $response.workspaces.id
            WorkspacesName = $response.workspaces.name
            WorkspaceType = $response.workspaces.type
    }
    $allWorkSpaces += $customObject
}
#CSV ファイルに出力
$csvFilePath = './AllWorkspaces.csv'
$allWorkSpaces | Export-Csv -Path $csvFilePath -NoTypeInformation -Encoding UTF8
