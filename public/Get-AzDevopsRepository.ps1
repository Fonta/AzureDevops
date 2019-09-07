function Get-AzDevopsRepository {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $false, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string] $Project,

        [Parameter(Mandatory = $false, ValueFromPipeline, HelpMessage = "Name or ID of the repository.")]
        [string[]] $RepositoryId,

        [Parameter(Mandatory = $false, HelpMessage = "Name or ID of the repository.")]
        [switch] $IncludeParent,

        [Parameter(Mandatory = $false, HelpMessage = "True to include reference links. The default value is false.")]
        [switch] $IncludeLinks,

        [Parameter(Mandatory = $false, HelpMessage = "True to include all remote URLs. The default value is false.")]
        [switch] $IncludeAllUrls,

        [Parameter(Mandatory = $false, HelpMessage = "True to include hidden repositories. The default value is false.")]
        [switch] $IncludeHidden
    )

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = "Basic $token"
        }
    
        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = "4e080c62-fa21-4fbc-8fef-2a10a2b38049"
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams
    
        $results = New-Object -TypeName System.Collections.ArrayList
    
        if ($PSBoundParameters.ContainsKey('Project')) {
            $prjUrl = "$Project/"
        }
    }

    process {
        $RepositoryId | Foreach-Object {
            $urlPart = $response = $null
            if ($_) {
                $urlPart = "/$_"
                if ($IncludeParent.IsPresent) { $queryUrl = "includeParent=true&" }

                if ($IncludeLinks.IsPresent) { Write-Warning -Message "Can't use IncludeLinks in combination with ID. Ignoring." }
                if ($IncludeAllUrls.IsPresent) { Write-Warning -Message "Can't use IncludeAllUrls in combination with ID. Ignoring." }
                if ($IncludeHidden.IsPresent) { Write-Warning -Message "Can't use IncludeHidden in combination with ID. Ignoring." }
            }
            else {
                $queryUrl = ""
                if ($IncludeLinks.IsPresent) { $queryUrl += [string]"includeLinks=true&" }
                if ($IncludeAllUrls.IsPresent) { $queryUrl += [string]"includeAllUrls=true&" }
                if ($IncludeHidden.IsPresent) { $queryUrl += [string]"includeHidden=true&" }

                if ($IncludeParent.IsPresent) { Write-Warning -Message "Can't use IncludeParent without an ID. Ignoring." }
            }

            $url = [string]::Format("{0}{1}_apis/git/repositories/{2}?{3}api-version=5.1", $areaUrl, $prjUrl, $urlPart, $queryUrl)
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