function Get-AzDevopsPolicyConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'Personal Access Token created in Azure Devops.')]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = 'Name of the organization.')]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = 'Name or ID of the project in Azure Devops.')]
        [string] $Project,

        # Parameter type is undefined because of possibility to input repository object or guid or policy object or id
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, ValueFromPipeline, HelpMessage = 'ID of the policy or repository in Azure Devops.')]
        $Id,

        [Parameter(Mandatory = $false, HelpMessage = '[Provided for legacy reasons] The scope on which a subset of policies is defined.')]
        [string] $Scope,

        [Parameter(Mandatory = $false, HelpMessage = 'Filter returned policies to only this type.')]
        [string] $PolicyType
    )

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = [string]::Format('Basic {0}', $token)
        }
    
        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = 'fb13a388-40dd-4a04-b530-013a739c72ef'
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams
    
        $results = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        $Id | ForEach-Object {
            $idUrl = $queryUrl = $null

            if ($_) {
                if ($_.id) { $_ = $_.id }

                if ($_ -match ("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$")) {
                    $script:repo = Get-AzDevopsRepository -PersonalAccessToken $PersonalAccessToken -OrganizationName $OrganizationName -Project $Project -Id $_
                }
                else {
                    $idUrl = [string]::Format('/{0}', $_)
                }
                
                # Not allowed
                if ($Scope) { Write-Warning -Message 'Unable to use Scope in combination with ID. Ignoring Scope value' }
                if ($policyType) { Write-Warning -Message 'Unable to use PolicyType in combination with ID. Ignoring PolicyType value' }
            }
            else {
                # Allowed
                if ($Scope) { $queryUrl += [string]::Format('scope={0}&', $Scope) }
                if ($policyType) { $queryUrl += [string]::Format('startTime={0}&', $PolicyType) }
            }

            $url = [string]::Format('{0}{1}/_apis/policy/configurations{2}?{3}api-version=5.1', $areaUrl, $Project, $idUrl, $queryUrl)
            Write-Verbose "Contructed url $url"

            $WRParams = @{
                Uri         = $url
                Method      = 'Get'
                Headers     = $header
                ContentType = 'application/json'
            }

            Invoke-WebRequest @WRParams | Get-ResponseObject | ForEach-Object {
                if ($script:repo) {
                    if ($_.settings.scope.repositoryId -like $repo.id) {
                        $results.Add($_) | Out-Null
                    }
                }
                else {
                    $results.Add($_) | Out-Null
                }
            }
        }
    }

    end {
        return $results
    }
}