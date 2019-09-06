function Get-AzDevopsProject {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $false, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string[]] $Project
    )

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
    $header = @{
        authorization = "Basic $token"
    }

    $projectsBaseUrl = Get-AzDevopsAreaUrl -OrganizationName $OrganizationName -PersonalAccessToken $PersonalAccessToken -AreaId "79134c72-4a58-4b42-976c-04e7115f32bf"

    $results = New-Object -TypeName System.Collections.ArrayList
    $apiUrls = New-Object -TypeName System.Collections.ArrayList

    if ($PSBoundParameters.ContainsKey('Project')) {
        $Project | Foreach-Object {
            $urlString = [string]::Format("{0}_apis/projects/{1}?api-version=5.1", $projectsBaseUrl, $_)
            $apiUrls.Add($urlString) | Out-Null
        }
    }
    else {
        $urlString = [string]::Format("{0}_apis/projects?api-version=5.1", $projectsBaseUrl)
        $apiUrls.Add($urlString) | Out-Null
    }

    $apiUrls | Foreach-Object {
        $response = Invoke-RestMethod -Uri $_ -Method Get -ContentType "application/json" -Headers $header

        if ($response.value) {
            foreach ($item in $response.value) {
                $results.Add($item) | Out-Null
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