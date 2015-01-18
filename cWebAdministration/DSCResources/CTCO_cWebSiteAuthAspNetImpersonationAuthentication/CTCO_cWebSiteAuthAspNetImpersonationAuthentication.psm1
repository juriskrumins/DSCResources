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
        [string]$password="",
        [Parameter(Mandatory=$false)]
        [string]$userName=""
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
            Write-Verbose -Message "Collecting website's ASP.NET Impersonation Authentication configuration"
            $aspnetAuthConf = Get-WebConfigurationProperty -Filter system.web/identity -PSPath "IIS:\Sites\$SiteName" -Name *
            $returnValue.sitename=$Sitename
            $returnValue.enabled=$aspnetAuthConf.impersonate
            $returnValue.password=$aspnetAuthConf.password
            $returnValue.userName=$aspnetAuthConf.userName
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
        [string]$password="",
        [Parameter(Mandatory=$false)]
        [string]$userName=""
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
            Write-Verbose -Message "Going to update website's ASP.NET impersonation authentication configuration"
            $aspnetAuthConf = Get-WebConfiguration -Filter system.web/identity -PSPath "IIS:\Sites\$SiteName"
            $aspnetAuthConf.impersonate=$Enabled
            $aspnetAuthConf.password=$password
            $aspnetAuthConf.userName=$userName
            $aspnetAuthConf | Set-WebConfiguration -Filter system.web/identity -PSPath "IIS:\Sites\$SiteName"
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
        [string]$password="",
        [Parameter(Mandatory=$false)]
        [string]$userName=""
    )

    $returnValue=$false
    $aspnetAuthConfStatus=Get-TargetResource -SiteName $SiteName -Enabled $Enabled -password $password -userName $userName
    if($aspnetAuthConfStatus.Count -ne 0)
    {
        if(
            ($aspnetAuthConfStatus.enabled -eq $Enabled) `
            -and ($aspnetAuthConfStatus.password -eq $password) `
            -and ($aspnetAuthConfStatus.userName -eq $userName)
          )
        {
            Write-Verbose -Message "Looks like website's ASP.NET impersonation authentication configuration is fine"
            $returnValue=$true
        }
        else
        {
            Write-Verbose -Message "Website's ASP.NET impersonation authentication configuration exists, but need to be updated"
        }
    }
    else
    {
        Write-Verbose -Message "Website's ASP.NET impersonation authentication configuration is empty. Need to update it."
    }
    return $returnValue 
}