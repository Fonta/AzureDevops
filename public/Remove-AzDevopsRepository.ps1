function Remove-AzDevopsRepository {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string] $Project,

        [Parameter(Mandatory = $true, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = "Name or ID of the repository")]
        [string[]] $Id
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
    
        $areaBaseUrl = Get-AzDevopsAreaUrl -OrganizationName $OrganizationName -PersonalAccessToken $PersonalAccessToken -AreaId "4e080c62-fa21-4fbc-8fef-2a10a2b38049"
    
        $results = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        foreach ($RepositoryId in $Id) {
            # according to the docs, it should be possibel to use the name of the repo in the url but somehow doesnt work
            $repo = Get-AzDevopsRepository -PersonalAccessToken $PersonalAccessToken -OrganizationName $OrganizationName -Project $Project -RepositoryId $RepositoryId

            if ($repo) {
                $urlString = [string]::Format("{0}{1}/_apis/git/repositories/{2}?api-version=5.1", $areaBaseUrl, $Project, $repo.id)

                if ($PSCmdlet.ShouldProcess($repo.name)) {
                    $response = Invoke-RestMethod -Uri $urlString -Method Delete -ContentType "application/json" -Headers $header
                }

                $results.Add($response) | Out-Null
            }
        }
    }
    
    end {
        $results = $results | Where-Object {$_}
        if ($results) {
            return $results 
        }
    }
}