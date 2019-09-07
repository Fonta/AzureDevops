function Set-AzDevopsLinkedWorkItemPolicy {
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

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Id of policy to set the policies on.')]
        [string[]] $Id,

        [Parameter(Mandatory = $false, HelpMessage = 'Branch/reg to set the polcies on E.G. "refs/heads/master"')]
        [string] $Branch = 'refs/heads/master',

        [Parameter(Mandatory = $false, HelpMessage = 'Boolean if policy enabled or not.')]
        [bool] $Enabled = $true,

        [Parameter(Mandatory = $false, HelpMessage = 'Boolean if policy is blocking or not.')]
        [bool] $Blocking = $false,

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
            $policyConfig = Get-AzDevopsPolicyConfiguration @policyConfigParams | Where-Object { $_.type.id -like '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e' }

            if (($policyConfig | Measure-Object).count -gt 1) {
                Write-Error "Found multiple policies. Can't continue at this moment. If you know the ID of the policy, you can use the -PolicyId parameter."
                return
            }   

            if ($policyConfig) {
                $policyUrl = [string]::Format('/{0}', $policyConfig.id)

                if ($PSBoundParameters.ContainsKey('Enabled')) { $policyConfig.isEnabled = $Enabled }
                if ($PSBoundParameters.ContainsKey('Blocking')) { $policyConfig.isBlocking = $Blocking }
                if ($PSBoundParameters.ContainsKey('Branch')) { $policyConfig.settings.scope.refName = $Branch }
                if ($PSBoundParameters.ContainsKey('MatchKind')) { $policyConfig.settings.scope.matchKind = $MatchKind }
            }
            else {
                Write-Verbose 'Was unable to find existing policy to update, switching method to Post to create new one.'
                $method = 'Post'

                $policyString = $script:ConfigurationStrings.LinkedWorkItemsPolicy
                $policy = $ExecutionContext.InvokeCommand.ExpandString($policyString)
            }

            

            $url = [string]::Format('{0}{1}/_apis/policy/configurations{2}?api-version=5.1', $areaUrl, $Project, $policyUrl)
            Write-Verbose "Contructed url $url"

            if ($PSCmdlet.ShouldProcess($Id)) {
                $response = Invoke-RestMethod -Uri $url -Method $Method -Headers $header -body $policy -ContentType 'application/json'

                $results.Add($response) | Out-Null
            }
        }
    }
    
    end {
        if ($results) {
            return $results
        }
    }
}