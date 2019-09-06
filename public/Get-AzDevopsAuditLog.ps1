function Get-AzDevopsAuditLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string] $Project
    )

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = "Basic $token"
        }
    
        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = "94ff054d-5ee1-413d-9341-3f4a7827de2e"
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams
        $areaUrl
    
        $results = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        $Id | ForEach-Object {
            $IdUrl = $response = $null

            if ($_) { $IdUrl = "/$_" }
            if ($StartTime) { $startTimeUrl = [string]::Format("startTime={0}&", $StartTime) }
            if ($EndTime) { $endTimeUrl = [string]::Format("endTime={0}&", $EndTime) }
            if ($BatchSize) { $batchSizeUrl = [string]::Format("batchSize={0}&", $BatchSize) }
            if ($ContinuationToken) { $continuationTokenUrl = [string]::Format("continuationToken={0}&", $ContinuationToken) }
            if ($SkipAggregation) { $skipAggregationUrl = [string]::Format("skipAggregation={0}&", $SkipAggregation) }

            $url = [string]::Format("{0}/_apis/audit/auditlog{1}?{2}{3}{4}{5}{6}api-version=5.1-preview.1", $areaUrl, $IdUrl, $startTimeUrl, $endTimeUrl, $batchSizeUrl, $continuationTokenUrl, $skipAggregationUrl)

            $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json" -Headers $header

            if ($response.decoratedAuditLogEntries) {
                $response.decoratedAuditLogEntries | ForEach-Object {
                    $results.Add($_) | Out-Null
                }
            }
        }
    }

    end {
        if ($results) {
            return $results 
        }
    }
}
        
