function Remove-AzDevopsPolicyConfiguration {
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

        # Parameter type is undefined because of possibility to input repository object or guid or policy object or id
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, ValueFromPipeline, HelpMessage = 'Id of the policy configuration to remove.')]
        $Id
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
        # Write-Verbose ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)

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
        $gatheredPolicyIds = New-Object -TypeName System.Collections.ArrayList

        $Id | ForEach-Object {
            if ($_.id) { $_ = $_.id }

            Write-Verbose "Getting policies for input ID $_"
            Get-AzDevopsPolicyConfiguration -PersonalAccessToken $PersonalAccessToken -OrganizationName $OrganizationName -Project $Project -Id $_ | ForEach-Object {
                $gatheredPolicyIds.Add($_) | Out-Null
            }
        }

        $gatheredPolicyIds | ForEach-Object {
            $WRResponse = $null

            if ($PSCmdlet.ShouldProcess("$($_.type.displayName) policy (ID $($_.id))")) {
                $url = [string]::Format('{0}{1}/_apis/policy/configurations/{2}?api-version=5.1', $areaUrl, $Project, $_.id)
                Write-Verbose "Contructed url $url"

                $WRParams = @{
                    Uri         = $url
                    Method      = Delete
                    Headers     = $header
                    ContentType = 'application/json'
                }
                $WRResponse = Invoke-WebRequest @WRParams

                $WRResponse | Get-ResponseObject | ForEach-Object {
                    $results.Add($_) | Out-Null
                }
            }
        }
    }

    end {
        return $results
    }
}