function Set-AzDevopsCodeReviewerPolicy {
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

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'Id of the repository to set the policies on.')]
        [string] $PolicyId,

        [Parameter(Mandatory = $false, HelpMessage = 'Boolean if policy enabled or not.')]
        [bool] $Enabled = $true,

        [Parameter(Mandatory = $false, HelpMessage = 'Boolean if policy is blocking or not.')]
        [bool] $Blocking = $true,

        [Parameter(Mandatory = $false, HelpMessage = 'Comma separated list of reviewer IDs')]
        [string[]] $ReviewerIds,

        [Parameter(Mandatory = $false, HelpMessage = 'Comma separated list of filename patterns')]
        [string[]] $FilenamePatterns,  
        
        [Parameter(Mandatory = $false, HelpMessage = 'Boolean for added files only.')]
        [bool] $AddedFilesOnly = $false,

        [Parameter(Mandatory = $false, HelpMessage = 'Minimum amount of approvers.')]
        [ValidateRange(1, 10)]
        [int] $MinimumApproverCount = 1,

        [Parameter(Mandatory = $false, HelpMessage = 'Boolean if creators vote counts.')]
        [bool] $CreatorVoteCounts = $true,

        [Parameter(Mandatory = $false, HelpMessage = 'Message will appear in the activity feed of pull requests with automatically added reviewers')]
        [string] $ActivityFeedMessage,

        [Parameter(Mandatory = $false, HelpMessage = 'Method of matching.')]
        [string] $matchKind = 'Exact',

        [Parameter(Mandatory = $false, HelpMessage = 'Branch/reg to set the polcies on E.G. "refs/heads/master"')]
        [string] $Branch = 'refs/heads/master'
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

        if ($PSBoundParameters.ContainsKey('ReviewerIds')) {
            $ReviewerIds = '"{0}"' -f ($ReviewerIds -join '","')
        }

        if ($PSBoundParameters.ContainsKey('filenamePatterns')) {
            $FilenamePatterns = '"{0}"' -f ($FilenamePatterns -join '","')
        }
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
            if ($PSBoundParameters.ContainsKey('PolicyId')) {
                $policyConfigParams.Id = $PolicyId
            }
            $policyConfig = Get-AzDevopsPolicyConfiguration @policyConfigParams | Where-Object { $_.type.id -like 'fd2167ab-b0be-447a-8ec8-39368250530e' }

            if (($policyConfig | Measure-Object).count -gt 1) {
                Write-Error "Found multiple policies. Can't continue at this moment. If you know the ID of the policy, you can use the -PolicyId parameter."
                return
            }            

            if ($policyConfig) {
                $policyUrl = [string]::Format('/{0}', $policyConfig.id)

                if ($PSBoundParameters.ContainsKey('Enabled')) { $policyConfig.isEnabled = $Enabled }
                if ($PSBoundParameters.ContainsKey('Blocking')) { $policyConfig.isBlocking = $Blocking }
                if ($PSBoundParameters.ContainsKey('ReviewerIds')) { $policyConfig.settings.requiredReviewerIds = $ReviewerIds }
                if ($PSBoundParameters.ContainsKey('filenamePatterns')) { $policyConfig.settings.filenamePatterns = $ReviewerIds }
                if ($PSBoundParameters.ContainsKey('AddedFilesOnly')) { $policyConfig.settings.addedFilesOnly = $AddedFilesOnly }
                if ($PSBoundParameters.ContainsKey('MinimumApproverCount')) { $policyConfig.settings.minimumApproverCount = $MinimumApproverCount }
                if ($PSBoundParameters.ContainsKey('CreatorVoteCounts')) { $policyConfig.settings.creatorVoteCounts = $CreatorVoteCounts }
                if ($PSBoundParameters.ContainsKey('MatchKind')) { $policyConfig.settings.scope.matchKind = $MatchKind }
                if ($PSBoundParameters.ContainsKey('Branch')) { $policyConfig.settings.scope.refName = $Branch }
                if ($PSBoundParameters.ContainsKey('ActivityFeedMessage')) { 
                    if ($policyConfig.settings.message) { $policyConfig.settings.message = $ActivityFeedMessage }
                    else { $policyConfig.settings | Add-Member -NotePropertyName message -NotePropertyValue $ActivityFeedMessage }
                }

                $policy = $policyConfig | ConvertTo-Json -Depth 5
            }
            else {
                Write-Verbose 'Was unable to find existing policy to update, switching method to Post to create new one.'
                $method = 'Post'

                $policyString = $script:ConfigurationStrings.CodeReviewerPolicy
                $policy = $ExecutionContext.InvokeCommand.ExpandString($policyString)
            }

            $url = [string]::Format('{0}{1}/_apis/policy/configurations{2}?api-version=5.1', $areaUrl, $Project, $policyUrl)
            Write-Verbose "Contructed url $url"

            if ($PSCmdlet.ShouldProcess($Id)) {
                $response = Invoke-WebRequest -Uri $url -Method $Method -Headers $header -Body $policy -ContentType 'application/json'

                Get-ResponseObject -InputObject $response | ForEach-Object {
                    $results.Add($_) | Out-Null
                }
            }
        }
    }
    
    end {
        return $results
    }
}