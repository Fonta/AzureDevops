function Get-AzDevopsAuditLog {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $false, HelpMessage = "Start time of download window.")]
        [string]$StartTime,

        [Parameter(Mandatory = $false, HelpMessage = "End time of download window.")]
        [string]$EndTime,

        [Parameter(Mandatory = $false, HelpMessage = "Max number of results to return.")]
        [int32]$BatchSize,

        [Parameter(Mandatory = $false, HelpMessage = "Token used for returning next set of results from previous query.")]
        [string] $ContinuationToken,

        [Parameter(Mandatory = $false, HelpMessage = "Skips aggregating events and leaves them as individual entries instead. By default events are aggregated. Event types that are aggregated: AuditLog.AccessLog.")]
        [switch]$SkipAggregation
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
    }

    process {
        if ($StartTime) { $startTimeUrl = [string]::Format("startTime={0}&", $StartTime) }
        if ($EndTime) { $endTimeUrl = [string]::Format("endTime={0}&", $EndTime) }
        if ($BatchSize) { $batchSizeUrl = [string]::Format("batchSize={0}&", $BatchSize) }
        if ($ContinuationToken) { $continuationTokenUrl = [string]::Format("continuationToken={0}&", $ContinuationToken) }
        if ($SkipAggregation.IsPresent) { $skipAggregationUrl = [string]"skipAggregation=true&" }

        $url = [string]::Format("{0}_apis/audit/auditlog?{1}{2}{3}{4}{5}api-version=5.1-preview.1", $areaUrl, $startTimeUrl, $endTimeUrl, $batchSizeUrl, $continuationTokenUrl, $skipAggregationUrl)
        Write-Verbose "Contructed url $url"

        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json" -Headers $header
    }

    end {
        if ($response) {
            return $response 
        }
    }
}
        
