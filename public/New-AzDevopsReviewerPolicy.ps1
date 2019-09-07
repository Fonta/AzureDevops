function New-AzDevopsReviewerPolicy {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'Personal Access Token created in Azure Devops.')]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = 'Name of the organization.')]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = 'Name or ID of the project in Azure Devops.')]
        [string] $Project,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = 'Id of the repository to set the policies on.')]
        [string[]] $Id,

        [Parameter(Mandatory = $false, HelpMessage = 'Branch/reg to set the polcies on E.G. "refs/heads/master"')]
        [string] $Branch = 'refs/heads/master',

        [Parameter(Mandatory = $false, HelpMessage = 'Boolean if policy enabled or not.')]
        [bool] $Enabled = $true,

        [Parameter(Mandatory = $false, HelpMessage = 'Boolean if policy is blocking or not.')]
        [bool] $Blocking = $true,

        [Parameter(Mandatory = $false, HelpMessage = 'Integer.')]
        [ValidateRange(1,10)]
        [int] $minimumApproverCount = 2,

        [Parameter(Mandatory = $false, HelpMessage = 'Boolean.')]
        [bool] $CreatorVoteCounts = $true,

        [Parameter(Mandatory = $false, HelpMessage = 'Boolean.')]
        [bool] $allowDownvotes = $false,

        [Parameter(Mandatory = $false, HelpMessage = 'Boolean.')]
        [bool] $resetOnSourcePush = $true,

        [Parameter(Mandatory = $false, HelpMessage = 'Method of matching.')]
        [string] $matchKind = 'Exact'
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
            authorization = [string]::Format('Basic {0}', $token)
        }

        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = 'fb13a388-40dd-4a04-b530-013a739c72ef'
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams

        $url = [string]::Format('{0}{1}/_apis/policy/configurations?api-version=5.1', $areaUrl, $Project)
        Write-Verbose "Contructed url $url"

        $results = New-Object -TypeName System.Collections.ArrayList
    }
    
    process {
        $Id | ForEach-Object {
            $response = $null
            
            $policyString = $script:ConfigurationStrings.ReviewerPolicy
            $policy = $ExecutionContext.InvokeCommand.ExpandString($policyString)

            if ($PSCmdlet.ShouldProcess($RepositoryId)) {
                $response = Invoke-RestMethod -Uri $url -Method Post -Headers $header -body $policy -ContentType 'application/json'

                if ($response) {
                    $results.Add($response) | Out-Null
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