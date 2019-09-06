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

        [Parameter(Mandatory = $false, HelpMessage = "Name or ID of the repository.")]
        [string[]] $RepositoryId,

        [switch]$IncludeParent
    )

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
    $header = @{
        authorization = "Basic $token"
    }

    $areaBaseUrl = Get-AzDevopsAreaUrl -OrganizationName $OrganizationName -PersonalAccessToken $PersonalAccessToken -AreaId "4e080c62-fa21-4fbc-8fef-2a10a2b38049"

    $results = New-Object -TypeName System.Collections.ArrayList
    $apiUrls = New-Object -TypeName System.Collections.ArrayList

    if ($PSBoundParameters.ContainsKey('Project')) {
        $prjUrl = "$Project/"
    }

    if ($IncludeParent.IsPresent) {
        $parentUrl = "includeParent=true&"
    }

    if ($PSBoundParameters.ContainsKey('RepositoryId')) {
        $RepositoryId | Foreach-Object {
            $urlString = [string]::Format("{0}{1}_apis/git/repositories/{2}?{3}api-version=5.1", $areaBaseUrl, $prjUrl, $_, $parentUrl)
            $apiUrls.Add($urlString) | Out-Null
        }
    }
    else {
        $urlString = [string]::Format("{0}{1}_apis/git/repositories?api-version=5.1", $areaBaseUrl, $prjUrl)
        $apiUrls.Add($urlString) | Out-Null
    }

    $apiUrls | Foreach-Object {
        $response = Invoke-RestMethod -Uri $_ -Method Get -ContentType "application/json" -Headers $header

        if ($response.value) {
            $response.value | ForEach-Object {
                $results.Add($_) | Out-Null
            }
        }
        elseif ($response.id) {
            $results.Add($response) | Out-Null
        }
    }

    if ($results) {
        return $results 
    }

}