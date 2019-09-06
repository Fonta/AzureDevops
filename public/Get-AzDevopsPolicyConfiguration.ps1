function Get-AzDevopsPolicyConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string] $Project,

        [string[]] $Id
    )
    

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
    $header = @{
        authorization = "Basic $token"
    }

    $configsBaseUrl = Get-AzDevopsAreaUrl -OrganizationName $OrganizationName -PersonalAccessToken $PersonalAccessToken -AreaId "fb13a388-40dd-4a04-b530-013a739c72ef"

    $results = New-Object -TypeName System.Collections.ArrayList
    $configsApiUrls = New-Object -TypeName System.Collections.ArrayList
    
    if ($PSBoundParameters.ContainsKey('Id')) {
        $Id | Foreach-Object {
            $urlString = [string]::Format("{0}{1}/_apis/policy/configurations/{2}?api-version=5.1", $configsBaseUrl, $Project, $_)
            $configsApiUrls.Add($urlString) | Out-Null
        }
    }
    else {
        $urlString = [string]::Format("{0}{1}/_apis/policy/configurations?api-version=5.1", $configsBaseUrl, $Project)
        $configsApiUrls.Add($urlString) | Out-Null
    }

    $configsApiUrls | Foreach-Object {
        $configurations = Invoke-RestMethod -Uri $_ -Method Get -ContentType "application/json" -Headers $header

        if ($configurations.value) {
            foreach ($config in $configurations.value) {
                $results.Add($config) | Out-Null
            }
        }
        elseif ($configurations.id) {
            $results.Add($configurations) | Out-Null
        }
       
    }

    if ($results) {
        return $results
    }
}