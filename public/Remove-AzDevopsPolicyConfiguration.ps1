function Remove-AzDevopsPolicyConfiguration {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string] $Project,

        [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = "Id of the policy configuration to remove.")]
        [int[]] $Id
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
            authorization = "Basic $token"
        }

        $baseAreaUrl = Get-AzDevopsAreaUrl -OrganizationName $OrganizationName -PersonalAccessToken $PersonalAccessToken -AreaId "fb13a388-40dd-4a04-b530-013a739c72ef"

        $results = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        $Id | ForEach-Object {
            $url = [string]::Format("{0}/{1}/_apis/policy/configurations/{2}?api-version=5.1", $baseAreaUrl, $Project, $_)
            Write-Verbose "Contructed url $url"

            try {
                if ($PSCmdlet.ShouldProcess($value)) {
                    $removeResult = Invoke-RestMethod -Uri $url -Method Delete -ContentType "application/json" -Headers $header
                }
            }
            catch {
                Write-Host "Failed to remove policy configuration $value. Error: $($_.Exception.Message)"
            }
    
            if ($removeResult) {
                $results.Add($removeResult) | Out-Null
            }
        }
    }

    end {
        return $results
    }
}