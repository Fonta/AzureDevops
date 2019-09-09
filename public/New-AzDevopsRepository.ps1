function New-AzDevopsRepository {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName='ID')]
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'Name you want to give to the repository.')]
        [string] $Name,

        [Parameter(Mandatory = $true, HelpMessage = 'Personal Access Token created in Azure Devops.')]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = 'Name of the organization.')]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, ParameterSetName='Project', HelpMessage = 'Name or ID of the project in Azure Devops in which the repository should be created.')]
        [string[]] $Project,

        # Id is mandatory unless Project is given. In which case we'll use the input from Project as ID.
        [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName='Project', HelpMessage = 'Name or ID of the project in Azure Devops in which the repository should be created.')]
        [Parameter(Mandatory = $true, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName='ID', HelpMessage = 'Name or ID of the project in Azure Devops in which the repository should be created.')]
        [string[]] $Id
    )
    
    begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }

        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = [string]::Format('Basic {0}', $token)
        }

        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = '4e080c62-fa21-4fbc-8fef-2a10a2b38049'
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams

        $results = New-Object -TypeName System.Collections.ArrayList
    }
    
    process {
        # If there was no pipeline input, or Id wasn't used but we do have a value for project, we'll use that as our Id input
        if (($PSBoundParameters.ContainsKey('Project')) -and (-not $PSBoundParameters.ContainsKey('Id')) -and (-not $_)) {
            $Id = $Project
        }

        $Id | ForEach-Object {
            $url = [string]::Format('{0}{1}/_apis/git/repositories?api-version=5.1', $areaUrl, $_)
            Write-Verbose "$($MyInvocation.MyCommand): Contructed url $url"

            $prjObject = Get-AzDevopsProject -OrganizationName $OrganizationName -PersonalAccessToken $PersonalAccessToken -Id $_

            if (-not $prjObject) {
                Write-Error "$($MyInvocation.MyCommand): Unable to find project $_ to create the repository in!"
                return
            }
    
            $newRepoArgs = @{
                name    = $Name
                project = @{
                    id = $prjObject.Id
                }
            }
            
            if ($PSCmdlet.ShouldProcess($newRepoArgs.name)) {
                $body = ($newRepoArgs | ConvertTo-Json)
    
                $WRParams = @{
                    Uri         = $url
                    Method      = 'Post'
                    Headers     = $header
                    Body        = $body
                    ContentType = 'application/json'
                }
                
                Invoke-WebRequest @WRParams | Get-ResponseObject | ForEach-Object {
                    $results.Add($_) | Out-Null
                }
            }
        }
    }
    
    end {
        return $results
    }
}