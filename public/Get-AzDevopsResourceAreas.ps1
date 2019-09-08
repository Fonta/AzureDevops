function Get-AzDevopsResourceAreas {
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Personal Access Token created in Azure Devops.')]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = 'Name of the organization.')]
        [Alias('OrgName')]
        [string] $OrganizationName
    )

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = [string]::Format('Basic {0}', $token)
        }
    
        $results = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        $url = [string]::Format('https://dev.azure.com/{0}/_apis/resourceAreas', $OrganizationName)
        Write-Verbose "Contructed url $url"

        $response = Invoke-WebRequest -Uri $url -Method Get -ContentType 'application/json' -Headers $header

        Get-ResponseObject -InputObject $response | ForEach-Object {
            $results.Add($_) | Out-Null
        }
    }

    end {
        return $results 
    }
}
        
