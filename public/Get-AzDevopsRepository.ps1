function Get-AzDevopsRepository {
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Personal Access Token created in Azure Devops.')]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = 'Name of the organization.')]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $false, HelpMessage = 'Name or ID of the project in Azure Devops.')]
        [string] $Project,

        [Parameter(Mandatory = $false, ValueFromPipeline, HelpMessage = 'Name or ID of the repository.')]
        [string[]] $Id,

        [Parameter(Mandatory = $false, HelpMessage = 'Name or ID of the repository.')]
        [switch] $IncludeParent,

        [Parameter(Mandatory = $false, HelpMessage = 'True to include reference links. The default value is false.')]
        [switch] $IncludeLinks,

        [Parameter(Mandatory = $false, HelpMessage = 'True to include all remote URLs. The default value is false.')]
        [switch] $IncludeAllUrls,

        [Parameter(Mandatory = $false, HelpMessage = 'True to include hidden repositories. The default value is false.')]
        [switch] $IncludeHidden
    )

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = [string]::Format('Basic {0}', $token)
        }
    
        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = '4e080c62-fa21-4fbc-8fef-2a10a2b38049'
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams
    
        $results = New-Object -TypeName System.Collections.ArrayList
    
        if ($PSBoundParameters.ContainsKey('Project')) {
            $prjUrl = "$Project/"
        }
    }

    process {
        $Id | Foreach-Object {
            $idUrl = $queryUrl = $null

            if ($_) {
                $idUrl = [string]::Format('/{0}', $_)

                # Allowed
                if ($IncludeParent.IsPresent) { $queryUrl += 'includeParent=true&' }

                # Not allowed
                if ($IncludeLinks.IsPresent) { Write-Warning -Message 'Unable to use IncludeLinks in combination with ID. Ignoring.' }
                if ($IncludeAllUrls.IsPresent) { Write-Warning -Message 'Unable to use IncludeAllUrls in combination with ID. Ignoring.' }
                if ($IncludeHidden.IsPresent) { Write-Warning -Message 'Unable to use IncludeHidden in combination with ID. Ignoring.' }
            }
            else {
                # Allowed
                if ($IncludeLinks.IsPresent) { $queryUrl += [string]'includeLinks=true&' }
                if ($IncludeAllUrls.IsPresent) { $queryUrl += [string]'includeAllUrls=true&' }
                if ($IncludeHidden.IsPresent) { $queryUrl += [string]'includeHidden=true&' }

                # Not allowed
                if ($IncludeParent.IsPresent) { Write-Warning -Message 'Unable to use IncludeParent without an ID. Ignoring.' }
            }

            $url = [string]::Format('{0}{1}_apis/git/repositories{2}?{3}api-version=5.1', $areaUrl, $prjUrl, $idUrl, $queryUrl)
            Write-Verbose "Contructed url $url"

            $WRParams = @{
                Uri         = $url
                Method      = 'Get'
                Headers     = $header
                ContentType = 'application/json'
            }

            Invoke-WebRequest @WRParams | Get-ResponseObject | ForEach-Object {
                $results.Add($_) | Out-Null
            }
        }
    }

    end {
        return $results 
    }
}