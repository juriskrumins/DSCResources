function Get-TargetResource 
{
    [OutputType([Hashtable])]
    param 
    (   
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteName,
        [Parameter(Mandatory)]
        [boolean]$Enabled,
        [Parameter(Mandatory=$false)]
        [boolean]$authPersistNonNTLM=$True,
        [Parameter(Mandatory=$false)]
        [boolean]$authPersistSingleRequest=$False,
        [Parameter(Mandatory=$false)]
        [boolean]$useAppPoolCredentials=$False,
        [Parameter(Mandatory=$false)]
        [boolean]$useKernelMode=$True
    )

    $returnValue=@{}

    try
    {
        $ErrorActionPreference="Stop"
        # Check if WebAdministration module is present for IIS cmdlets
        Write-Verbose -Message "Checking for existance of WebAdministration module"
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw "Please ensure that WebAdministration module is installed."
        }

        Write-Verbose -Message "Checking for existance of website $SiteName"
        $Website = Get-Website -Name ($SiteName -split "\\")[0]
        if ($Website.count -eq 1) 
        {
            Write-Verbose -Message "Collecting website's WindowsAuthentication configuration"
            $windowsAuthConf = Get-WebConfigurationProperty -Filter system.WebServer/security/authentication/WindowsAuthentication -PSPath "IIS:\Sites\$SiteName" -Name *
            $returnValue.sitename=$Sitename
            $returnValue.enabled=$windowsAuthConf.Enabled
            $returnValue.authPersistNonNTLM=$windowsAuthConf.authPersistNonNTLM
            $returnValue.authPersistSingleRequest=$windowsAuthConf.authPersistSingleRequest
            $returnValue.useAppPoolCredentials=$windowsAuthConf.useAppPoolCredentials
            $returnValue.useKernelMode=$windowsAuthConf.useKernelMode
        }
        else
        {
            Write-Verbose -Message "Website count not equal to 1."
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. Error: $($Error[0].Exception.Message)"
    }
    return $returnValue

}  

# The Set-TargetResource cmdlet is used to create, delete or configuure a website on the target machine. 
function Set-TargetResource 
{
    param 
    (   
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteName,
        [Parameter(Mandatory)]
        [boolean]$Enabled,
        [Parameter(Mandatory=$false)]
        [boolean]$authPersistNonNTLM=$True,
        [Parameter(Mandatory=$false)]
        [boolean]$authPersistSingleRequest=$False,
        [Parameter(Mandatory=$false)]
        [boolean]$useAppPoolCredentials=$False,
        [Parameter(Mandatory=$false)]
        [boolean]$useKernelMode=$True
    )

    try
    {


        $ErrorActionPreference="Stop"
        # Check if WebAdministration module is present for IIS cmdlets
        Write-Verbose -Message "Checking for existance of WebAdministration module"
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw "Please ensure that WebAdministration module is installed."
        }

        Write-Verbose -Message "Checking for existance of website $SiteName"
        $Website = Get-Website -Name ($SiteName -split "\\")[0]
        if ($Website.count -eq 1) 
        {
            Write-Verbose -Message "Going to update website's windows Authentication configuration"
            if((Get-webconfiguration -Filter //system.webServer/security/authentication/WindowsAuthentication -PSPath machine/webroot/apphost).overrideMode -ne  "Allow")
            {
                Write-Verbose -Message "Setting overrideMode=Allow for the machine/webroot/apphost"
                Set-WebConfiguration -Filter //system.webServer/security/authentication/WindowsAuthentication -PSPath machine/webroot/apphost -metadata overrideMode -value Allow
            }
            $windowsAuthConf = Get-WebConfiguration -Filter system.WebServer/security/authentication/WindowsAuthentication -PSPath "IIS:\Sites\$SiteName"
            $windowsAuthConf.enabled=$Enabled
            $windowsAuthConf.authPersistNonNTLM=$authPersistNonNTLM
            $windowsAuthConf.authPersistSingleRequest=$authPersistSingleRequest
            $windowsAuthConf.useAppPoolCredentials=$useAppPoolCredentials
            $windowsAuthConf.useKernelMode=$useKernelMode
            $windowsAuthConf | Set-WebConfiguration -Filter system.WebServer/security/authentication/WindowsAuthentication -PSPath "IIS:\Sites\$SiteName"
        }
        else
        {
            Write-Verbose -Message "Website count not equal to 1."
        }
    }
    catch 
    {
        Write-Verbose -Message "Error eccured. Error: $($Error[0].Exception.Message)"
    }

}

# The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as expected in the instance document.
function Test-TargetResource 
{
    [OutputType([Boolean])]
    param 
    (   
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteName,
        [Parameter(Mandatory)]
        [boolean]$Enabled,
        [Parameter(Mandatory=$false)]
        [boolean]$authPersistNonNTLM=$True,
        [Parameter(Mandatory=$false)]
        [boolean]$authPersistSingleRequest=$False,
        [Parameter(Mandatory=$false)]
        [boolean]$useAppPoolCredentials=$False,
        [Parameter(Mandatory=$false)]
        [boolean]$useKernelMode=$True
    )

    $returnValue=$false
    $windowsAuthConfStatus=Get-TargetResource -SiteName $SiteName -Enabled $Enabled -authPersistNonNTLM $authPersistNonNTLM -authPersistSingleRequest $authPersistSingleRequest -useAppPoolCredentials $useAppPoolCredentials -useKernelMode $useKernelMode -Verbose
    if($windowsAuthConfStatus.Count -ne 0)
    {
        if(
            ($windowsAuthConfStatus.Enabled -eq $Enabled) `
            -and ($windowsAuthConfStatus.authPersistNonNTLM -eq $authPersistNonNTLM) `
            -and ($windowsAuthConfStatus.authPersistSingleRequest -eq $authPersistSingleRequest) `
            -and ($windowsAuthConfStatus.useAppPoolCredentials -eq $useAppPoolCredentials) `
            -and ($windowsAuthConfStatus.useKernelMode -eq $useKernelMode)
          )
        {
            Write-Verbose -Message "Looks like website's windows authentication configuration is fine"
            $returnValue=$true
        }
        else
        {
            Write-Verbose -Message "Website's windows authentication configuration exists, but need to be updated"
        }
    }
    else
    {
        Write-Verbose -Message "Website's windows authentication configuration is empty. Need to update it."
    }
    return $returnValue 
}