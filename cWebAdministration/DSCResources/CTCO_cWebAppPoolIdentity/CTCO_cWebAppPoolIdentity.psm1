function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $AppPoolName,
        [parameter(Mandatory = $true)]
        [ValidateSet("ApplicationPoolIdentity", "LocalService", "LocalSystem", "NetworkService","SpecificUser")]
        [System.String]
        $IdentityType,
        [parameter(Mandatory = $false)]
        [System.String]
        $Username,
        [parameter(Mandatory = $false)]
        [System.String]
        $Password
    )

    $returnValue = @{}
    #need to import explicitly to run for IIS:\AppPools
    Import-Module WebAdministration

    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw "Please ensure that WebAdministration module is installed."
    }

    Write-Verbose -Message "Getting Application Pool Identity info ..."
    $AppPool = Get-Item "IIS:\AppPools\*" | Where-Object {$_.Name -eq $AppPoolName}
    Write-Verbose -Message "Application Pool collected."
    if($AppPool -ne $null)
    {
        $returnValue = @{
            AppPoolName   = $AppPool.Name
            IdentityType = $AppPool.processModel.identityType
            Username = $AppPool.processModel.Username
            Password = $AppPool.processModel.Password
        }
    }
    else
    {
        Write-Verbose -Message "Can't find application pool $AppPoolName ."
    }

    return $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $AppPoolName,
        [parameter(Mandatory = $true)]
        [ValidateSet("ApplicationPoolIdentity", "LocalService", "LocalSystem", "NetworkService","SpecificUser")]
        [System.String]
        $IdentityType,
        [parameter(Mandatory = $false)]
        [System.String]
        $Username,
        [parameter(Mandatory = $false)]
        [System.String]
        $Password
    )


    $AppPool = Get-TargetResource -AppPoolName $AppPoolName -IdentityType $IdentityType -Username $Username -Password $Password
    if($AppPool.Count -ne 0)
    {
        Write-Verbose -Message "Setting up App Pool $AppPoolName IdentityType to $IdentityType ..."
        $AppPool = Get-Item "IIS:\AppPools\$AppPoolName"
        $AppPool.processModel.identityType = $IdentityType
        Write-Verbose -Message "Setting up App Pool $AppPoolName IdentityType's username and password ..."
        $AppPool.processModel.Username = $Username
        $AppPool.processModel.Password = $Password
        $AppPool | Set-Item
        Write-Verbose -Message "App Pool $AppPoolName Identity have been set succesfully."
    }
    else
    {
        Write-Verbose -Message "Can't find application pool $AppPoolName ."
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $AppPoolName,
        [parameter(Mandatory = $true)]
        [ValidateSet("ApplicationPoolIdentity", "LocalService", "LocalSystem", "NetworkService","SpecificUser")]
        [System.String]
        $IdentityType,
        [parameter(Mandatory = $false)]
        [System.String]
        $Username,
        [parameter(Mandatory = $false)]
        [System.String]
        $Password
    )

    $retValue=$false
    $AppPool = Get-TargetResource -AppPoolName $AppPoolName -IdentityType $IdentityType -Username $Username -Password $Password
    if($AppPool.Count -ne 0)
    {
        if($AppPool.IdentityType -eq $IdentityType)
        {
            Write-Verbose -Message "Application pool $AppPoolName exists and IdentityType set correctly."
            if($IdentityType -ne "SpecificUser")
            {
                $retValue=$true
            }
            else
            {
                if($AppPool.Username -eq "$Username" -and $AppPool.Password -eq "$Password")
                {
                    Write-Verbose -Message "Username and password for the specified IdentityType set correctly."
                    $retValue=$true
                }
                else
                {
                    Write-Verbose -Message "Username and password for the specified IdentityType set incorrectly. We'll adjust it."
                }
            }
        }
        else
        {
            Write-Verbose -Message "Application pool $AppPoolName exists, but IdentityType set incorrectly. We'll adjust it."
        }
    }
    else
    {
        Write-Verbose -Message "Can't find application pool $AppPoolName ."
    }

    return $retValue
}

    
Export-ModuleMember -Function *-TargetResource