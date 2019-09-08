function Get-AzDevopsPolicyTypes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Personal Access Token created in Azure Devops.')]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = 'Name of the organization.')]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = 'Name or ID of the project in Azure Devops.')]
        [string] $Project,

        [Parameter(Mandatory = $false, ValueFromPipeline, HelpMessage = 'ID of the policy.')]
        [string[]] $Id
    )

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = [string]::Format('Basic {0}', $token)
        }
    
        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = '5d6898bb-45ec-463f-95f9-54d49c71752e'
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams
    
        $results = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        $Id | ForEach-Object {
            $idUrl = $WRResponse = $null

            if ($_) {
                $idUrl = [string]::Format('/{0}', $_)
            }

            $url = [string]::Format('{0}{1}/_apis/policy/types{2}?api-version=5.1', $areaUrl, $Project, $idUrl)
            Write-Verbose "Contructed url $url"

            $WRParams = @{
                Uri         = $url
                Method      = Get
                Headers     = $header
                ContentType = 'application/json'
            }
            $WRResponse = Invoke-WebRequest @WRParams

            $WRResponse | Get-ResponseObject | ForEach-Object {
                $results.Add($_) | Out-Null
            }
        }
    }

    end {
        if ($results) {
            return $results 
        }
    }
}
        
