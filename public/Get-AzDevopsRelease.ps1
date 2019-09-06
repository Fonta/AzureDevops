function Get-AzDevopsRelease {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string] $Project,

        [Parameter(Mandatory = $false, HelpMessage = "ID of the build.")]
        [int[]] $ReleaseId
    )

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
    $header = @{
        authorization = "Basic $token"
    }

    $projectsBaseUrl = Get-AzDevopsAreaUrl -OrganizationName $OrganizationName -PersonalAccessToken $PersonalAccessToken -AreaId "efc2f575-36ef-48e9-b672-0c6fb4a48ac5"

    $results = New-Object -TypeName System.Collections.ArrayList
    $apiUrls = New-Object -TypeName System.Collections.ArrayList

    if ($PSBoundParameters.ContainsKey('ReleaseId')) {
        $ReleaseId | Foreach-Object {
            $urlString = [string]::Format("{0}{1}/_apis/release/releases/{2}?api-version=5.1", $projectsBaseUrl, $Project, $_)
            $apiUrls.Add($urlString) | Out-Null
        }
    }
    else {
        $urlString = [string]::Format("{0}{1}/_apis/release/releases?api-version=5.1", $projectsBaseUrl, $Project)
        $apiUrls.Add($urlString) | Out-Null
    }

    $apiUrls | ForEach-Object {
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
        
