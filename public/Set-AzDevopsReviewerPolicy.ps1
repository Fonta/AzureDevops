function Set-AzDevopsReviewerPolicy {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = 'Personal Access Token created in Azure Devops.')]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = 'Name of the organization.')]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = 'Name or ID of the project in Azure Devops.')]
        [string] $Project,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Id of the repository to set the policies on.')]
        [string[]] $Id,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Branch/reg to set the polcies on E.G. "refs/heads/master"')]
        [string] $Branch = 'refs/heads/master',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Boolean if policy enabled or not.')]
        [bool] $Enabled = $true,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Boolean if policy is blocking or not.')]
        [bool] $Blocking = $true,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Integer.')]
        [int] $minimumApproverCount = 2,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Boolean.')]
        [bool] $CreatorVoteCounts = $true,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Boolean.')]
        [bool] $allowDownvotes = $false,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Boolean.')]
        [bool] $resetOnSourcePush = $true,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Method of matching.')]
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

        $results = New-Object -TypeName System.Collections.ArrayList
    }
    
    process {
        $Id | ForEach-Object {
            $policyUrl = $response = $null
            $method = 'Put'

            $policyConfigParams = @{
                PersonalAccessToken = $PersonalAccessToken
                OrganizationName    = $OrganizationName
                Project             = $Project
                RepositoryId        = $_
            }
            $policyConfig = Get-AzDevopsPolicyConfiguration @policyConfigParams | Where-Object { $_.type.id -like 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }

            if ($policyConfig) {
                $policyUrl = [string]::Format('/{0}', $policyConfig.id)
            }
            else {
                Write-Verbose 'Was unable to find existing policy to update, switching method to Post to create new one.'
                $method = 'Post'
            }

            $policyString = $script:ConfigurationStrings.ReviewerPolicy
            $policy = $ExecutionContext.InvokeCommand.ExpandString($policyString)

            $url = [string]::Format('{0}{1}/_apis/policy/configurations{2}?api-version=5.1', $areaUrl, $Project, $policyUrl)
            Write-Verbose "Contructed url $url"

            if ($PSCmdlet.ShouldProcess($Id)) {
                $response = Invoke-RestMethod -Uri $url -Method $Method -Headers $header -body $policy -ContentType 'application/json'

                $results.Add($response) | Out-Null
            }
        }
    }
    
    end {
        return $results
    }
}


