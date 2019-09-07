function Set-AzDevopsCommentResolutionPolicy {
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

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = "Id of policy to set the policies on.")]
        [string] $Id,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = "Id of the repository to set the policies on.")]
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

        if (-not ($PSBoundParameters.ContainsKey('Id'))) {
            $policyConfigParams = @{
                PersonalAccessToken = $PersonalAccessToken
                OrganizationName    = $OrganizationName
                Project             = $Project
                RepositoryId        = $RepositoryId
            }
            $policyConfig = Get-AzDevopsPolicyConfiguration @policyConfigParams | Where-Object { $_.type.id -like "c6a1889d-b943-4856-b76f-9e46bb6b0df2" }
            $Id = $policyConfig.id
        }

        $url = [string]::Format("{0}{1}/_apis/policy/configurations/{2}?api-version=5.1", $areaUrl, $Project, $Id)
        Write-Verbose "Contructed url $url"
    }
    
    process {
        $policy = @"
{
    "isEnabled": "$Enabled",
    "isBlocking": "$Blocking",
    "type": {
        "id": "c6a1889d-b943-4856-b76f-9e46bb6b0df2"
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

        if ($PSCmdlet.ShouldProcess($Id)) {
            $result = Invoke-RestMethod -Uri $url -Method Put -Headers $header -body $policy -ContentType "application/json"
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