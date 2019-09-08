function Get-AzDevopsResourceAreas {
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Personal Access Token created in Azure Devops.')]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = 'Name of the organization.')]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $false, HelpMessage = 'This param is purely in this function for compatibilty.')]
        [string] $Project
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

        $WRParams = @{
            Uri         = $url
            Method      = 'Get'
            Headers     = $header
            ContentType = 'application/json'
        }
        $WRResponse = Invoke-WebRequest @WRParams

        $WRResponse | Get-ResponseObject | ForEach-Object {
            $results.Add($_) | Out-Null
        }
    }

    end {
        return $results 
    }
}
        
