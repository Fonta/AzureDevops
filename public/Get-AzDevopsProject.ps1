function Get-AzDevopsProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $false, ValueFromPipeline, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string[]] $Project,

        [Parameter(Mandatory = $false, ValueFromPipeline, HelpMessage = "Filter on team projects in a specific team project state (default: WellFormed).")]
        [ValidateSet('all', 'createPending', 'deleted', 'deleting', 'new', 'unchanged', 'wellFormed')]
        [string] $StateFilter,

        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [int] $Top,

        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [int] $Skip,

        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [string] $ContinuationToken,

        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [switch] $GetDefaultTeamImageUrl,

        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [switch] $IncludeCapabilities,

        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [switch] $IncludeHistory
    )

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = "Basic $token"
        }
    
        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = "79134c72-4a58-4b42-976c-04e7115f32bf"
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams

        $results = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        $Project | ForEach-Object {
            $urlPart = $response = $null
            if ($_) {
                $urlPart = "/$_"
                if ($IncludeCapabilities.IsPresent) { $includeCapabilitiesUrl = [string]::Format('includeCapabilities={0}&', $IncludeCapabilities) }
                if ($IncludeHistory.IsPresent) { $includeHistoryUrl = [string]::Format('includeHistory={0}&', $IncludeHistory) }

                if ($StateFilter) { Write-Warning -Message "Can't use StateFilter in combination with ID. Ignoring." }
                if ($Top) { Write-Warning -Message "Can't use Top in combination with ID. Ignoring." }
                if ($Skip) { Write-Warning -Message "Can't use Skip in combination with ID. Ignoring." }
                if ($ContinuationToken) { Write-Warning -Message "Can't use ContinuationToken in combination with ID. Ignoring." }
                if ($GetDefaultTeamImageUrl.IsPresent) { Write-Warning -Message "Can't use GetDefaultTeamImageUrl in combination with ID. Ignoring." }

                $url = [string]::Format("{0}_apis/projects/{1}?{2}{3}api-version=5.1", $areaUrl, $urlPart, $includeCapabilitiesUrl, $includeHistoryUrl)
            }
            else {
                if ($StateFilter) { $stateFilterUrl = [string]::Format('stateFilter={0}&', $StateFilter) }
                if ($Top) { $topUrl = [string]::Format('$top={0}&', $Top) }
                if ($Skip) { $skipUrl = [string]::Format("$skip={0}&", $Skip) }
                if ($ContinuationToken) { $continuationTokenUrl = [string]::Format("continuationToken={0}&", $ContinuationToken) }
                if ($GetDefaultTeamImageUrl.IsPresent) { $getDefaultTeamImageUrlUrl = [string]::Format("getDefaultTeamImageUrl={0}&", $GetDefaultTeamImageUrl) }

                if ($IncludeCapabilities.IsPresent) { Write-Warning -Message "Can't use IncludeCapabilities without an ID. Ignoring." }
                if ($IncludeHistory.IsPresent) { Write-Warning -Message "Can't use IncludeCapabilities without an ID. Ignoring." }

                $url = [string]::Format("{0}_apis/projects?{1}{2}{3}{4}{5}api-version=5.1", $areaUrl, $stateFilterUrl, $topUrl, $skipUrl, $continuationTokenUrl, $getDefaultTeamImageUrlUrl)
            }
            Write-Verbose "Contructed url $url"

            $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json" -Headers $header

            if ($response.value) {
                $response.value | ForEach-Object {
                    $results.Add($_) | Out-Null
                }
            }
            elseif ($response.id) {
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