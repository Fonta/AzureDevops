function New-AzDevopsRepository {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = "Name you want to give to the repository.")]
        [string] $Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string] $Project
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

        $prjObject = Get-AzDevopsProject -OrganizationName $OrganizationName -PersonalAccessToken $PersonalAccessToken | Where-Object { $_.name -like $Project -or $_.id -like $Project }

        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = "4e080c62-fa21-4fbc-8fef-2a10a2b38049"
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams

        $url = [string]::Format("{0}{1}/_apis/git/repositories?api-version=5.1", $areaUrl, $Project)
        Write-Verbose "Contructed url $url"
    }
    
    process {
        $newRepoArgs = @{
            name    = $Name
            project = @{
                id = $prjObject.Id
            }
        }
        
        try {
            if ($PSCmdlet.ShouldProcess($newRepoArgs.name)) {
                $result = Invoke-RestMethod -Uri $url -Method Post -Headers $header -body ($newRepoArgs | ConvertTo-Json) -ContentType "application/json"
            }
        }
        catch {
            throw $_
        }
    }
    
    end {
        return $result
    }
}