function Get-AzDevopsProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Personal Access Token created in Azure Devops.')]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = 'Name of the organization.')]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $false, HelpMessage = 'Name or ID of the project in Azure Devops.')]
        [string[]] $Project,

        [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = 'Name or ID of the project in Azure Devops.')]
        [string[]] $Id,

        [Parameter(Mandatory = $false, HelpMessage = 'Filter on team projects in a specific team project state (default: WellFormed).')]
        [ValidateSet('all', 'createPending', 'deleted', 'deleting', 'new', 'unchanged', 'wellFormed')]
        [string] $StateFilter,

        [Parameter(Mandatory = $false)]
        [int] $Top,

        [Parameter(Mandatory = $false)]
        [int] $Skip,

        [Parameter(Mandatory = $false)]
        [string] $ContinuationToken,

        [Parameter(Mandatory = $false)]
        [switch] $GetDefaultTeamImageUrl,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeCapabilities,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeHistory
    )

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = [string]::Format('Basic {0}', $token)
        }
    
        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = '79134c72-4a58-4b42-976c-04e7115f32bf'
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams

        $results = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        # If there was no pipeline input, or Id wasn't used but we do have a value for project, we'll use that as our Id input
        if (($PSBoundParameters.ContainsKey('Id')) -and (-not $PSBoundParameters.ContainsKey('Id')) -and (-not $_)) {
        # if (($PSBoundParameters.ContainsKey('Project')) -and (-not $_) -and (-not $Id)) {
            $Id = $Project
        }

        $Id | ForEach-Object {
            $idUrl = $queryUrl = $null

            if ($_) {
                $idUrl = [string]::Format('/{0}', $_)

                # Allowed
                if ($IncludeCapabilities.IsPresent) { $queryUrl += 'includeCapabilities=true&' }
                if ($IncludeHistory.IsPresent) { $queryUrl += 'includeHistory=true&' }

                # Not allowed
                if ($StateFilter) { Write-Warning -Message 'Unable to use StateFilter in combination with ID. Ignoring.' }
                if ($Top) { Write-Warning -Message 'Unable to use Top in combination with ID. Ignoring.' }
                if ($Skip) { Write-Warning -Message 'Unable to use Skip in combination with ID. Ignoring.' }
                if ($ContinuationToken) { Write-Warning -Message 'Unable to use ContinuationToken in combination with ID. Ignoring.' }
                if ($GetDefaultTeamImageUrl.IsPresent) { Write-Warning -Message 'Unable to use GetDefaultTeamImageUrl in combination with ID. Ignoring.' }
            }
            else {
                # Allowed
                if ($StateFilter) { $queryUrl += [string]::Format('stateFilter={0}&', $StateFilter) }
                if ($Top) { $queryUrl += [string]::Format('$top={0}&', $Top) }
                if ($Skip) { $queryUrl += [string]::Format('$skip={0}&', $Skip) }
                if ($ContinuationToken) { $queryUrl += [string]::Format('continuationToken={0}&', $ContinuationToken) }
                if ($GetDefaultTeamImageUrl.IsPresent) { $queryUrl += 'getDefaultTeamImageUrl=true&' }

                # Not allowed
                if ($IncludeCapabilities.IsPresent) { Write-Warning -Message 'Unable to use IncludeCapabilities without an ID. Ignoring.' }
                if ($IncludeHistory.IsPresent) { Write-Warning -Message 'Unable to use IncludeCapabilities without an ID. Ignoring.' }
            }

            $url = [string]::Format('{0}_apis/projects/{1}?{2}api-version=5.1', $areaUrl, $idUrl, $queryUrl)
            Write-Verbose "$($MyInvocation.MyCommand): Contructed url $url"

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