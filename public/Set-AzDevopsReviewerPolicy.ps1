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
        [ValidateRange(1, 10)]
        [int] $minimumApproverCount = 2,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Boolean.')]
        [bool] $CreatorVoteCounts = $true,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Boolean.')]
        [bool] $AllowDownvotes = $false,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Boolean.')]
        [bool] $ResetOnSourcePush = $true,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Method of matching.')]
        [string] $MatchKind = 'Exact'
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
            $policyUrl = $null
            $method = 'Put'

            $policyConfigParams = @{
                PersonalAccessToken = $PersonalAccessToken
                OrganizationName    = $OrganizationName
                Project             = $Project
                RepositoryId        = $_
            }
            $policyConfig = Get-AzDevopsPolicyConfiguration @policyConfigParams | Where-Object { $_.type.id -like 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' }

            if (($policyConfig | Measure-Object).count -gt 1) {
                Write-Error "Found multiple policies. Can't continue at this moment. If you know the ID of the policy, you can use the -PolicyId parameter."
                return
            }   

            if ($policyConfig) {
                $policyUrl = [string]::Format('/{0}', $policyConfig.id)

                if ($PSBoundParameters.ContainsKey('Enabled')) { $policyConfig.isEnabled = $Enabled }
                if ($PSBoundParameters.ContainsKey('Blocking')) { $policyConfig.isBlocking = $Blocking }
                if ($PSBoundParameters.ContainsKey('MinimumApproverCount')) { $policyConfig.settings.minimumApproverCount = $MinimumApproverCount }
                if ($PSBoundParameters.ContainsKey('CreatorVoteCounts')) { $policyConfig.settings.creatorVoteCounts = $CreatorVoteCounts }
                if ($PSBoundParameters.ContainsKey('AllowDownvotes')) { $policyConfig.settings.allowDownvotes = $AllowDownvotes }
                if ($PSBoundParameters.ContainsKey('ResetOnSourcePush')) { $policyConfig.settings.resetOnSourcePush = $ResetOnSourcePush }
                if ($PSBoundParameters.ContainsKey('Branch')) { $policyConfig.settings.scope.refName = $Branch }
                if ($PSBoundParameters.ContainsKey('MatchKind')) { $policyConfig.settings.scope.matchKind = $MatchKind }

                $policy = $policyConfig | ConvertTo-Json -Depth 5
            }
            else {
                Write-Verbose 'Was unable to find existing policy to update, switching method to Post to create new one.'
                $method = 'Post'

                $policyString = $script:ConfigurationStrings.ReviewerPolicy
                $policy = $ExecutionContext.InvokeCommand.ExpandString($policyString)
            }

            if ($PSCmdlet.ShouldProcess($Id)) {
                $url = [string]::Format('{0}{1}/_apis/policy/configurations{2}?api-version=5.1', $areaUrl, $Project, $policyUrl)
                Write-Verbose "Contructed url $url"
            
                $WRParams = @{
                    Uri         = $url
                    Method      = $Method
                    Headers     = $header
                    Body        = $policy
                    ContentType = 'application/json'
                }
                
                Invoke-WebRequest @WRParams | Get-ResponseObject | ForEach-Object {
                    $results.Add($_) | Out-Null
                }
            }
        }
    }
    
    end {
        return $results
    }
}