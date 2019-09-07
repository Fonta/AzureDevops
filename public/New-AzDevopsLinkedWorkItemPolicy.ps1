function New-AzDevopsLinkedWorkItemPolicy {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string] $Project,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = "Id of the repository to set the policies on.")]
        [string] $RepositoryId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = "Branch/reg to set the polcies on E.G. 'refs/heads/master'")]
        [string] $Branch = "refs/heads/master",

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = "Boolean if policy enabled or not.")]
        [bool] $Enabled = $true,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = "Boolean if policy is blocking or not.")]
        [bool] $Blocking = $false,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = "Method of matching.")]
        [string] $matchKind = "Exact"
    )
    
    begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }

        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = "Basic $token"
        }

        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = "fb13a388-40dd-4a04-b530-013a739c72ef"
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams

        $url = [string]::Format("{0}{1}/_apis/policy/configurations?api-version=5.1", $areaUrl, $Project)
        Write-Verbose "Contructed url $url"
    }
    
    process {
        $policy = @"
{
    "isEnabled": "$Enabled",
    "isBlocking": "$Blocking",
    "type": {
        "id": "40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e"
    },
    "settings": {
        "scope": [
            {
                "repositoryId": "$RepositoryId",
                "matchKind": "$matchKind",
                "refName": "$Branch"
            }
        ]
    }
}
"@

        try {
            if ($PSCmdlet.ShouldProcess($RepositoryId)) {
                $result = Invoke-RestMethod -Uri $url -Method Post -Headers $header -body $policy -ContentType "application/json"
            }
        }
        catch {
            throw $_
        }
    }
    
    end {
        if ($result) {
            return $result
        }
        else {
            return $false
        }
    }
}