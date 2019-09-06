function Get-AzDevopsBuild {
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
        [int[]] $BuildId
    )

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
    $header = @{
        authorization = "Basic $token"
    }

    $projectsBaseUrl = Get-AzDevopsAreaUrl -OrganizationName $OrganizationName -PersonalAccessToken $PersonalAccessToken -AreaId "5d6898bb-45ec-463f-95f9-54d49c71752e"

    $results = New-Object -TypeName System.Collections.ArrayList
    $apiUrls = New-Object -TypeName System.Collections.ArrayList

    if ($PSBoundParameters.ContainsKey('BuildId')) {
        $BuildId | Foreach-Object {
            $urlString = [string]::Format("{0}{1}/_apis/build/builds/{2}?api-version=5.0", $projectsBaseUrl, $Project, $_)
            $apiUrls.Add($urlString) | Out-Null
        }
    }
    else {
        $urlString = [string]::Format("{0}{1}/_apis/build/builds?api-version=5.0", $projectsBaseUrl, $Project)
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