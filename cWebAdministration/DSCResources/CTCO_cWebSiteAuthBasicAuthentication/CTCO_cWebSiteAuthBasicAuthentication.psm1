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
        [ValidateSet("Interactive","Batch","Network","ClearText")]
        [String] $logonMethod="ClearText",
        [Parameter(Mandatory=$false)]
        [String] $defaultLogonDomain="",
        [Parameter(Mandatory=$false)]
        [String] $realm=""
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
            Write-Verbose -Message "Collecting website's basicAuthentication configuration"
            $basicAuthConf = Get-WebConfigurationProperty -Filter system.WebServer/security/authentication/BasicAuthentication -PSPath "IIS:\Sites\$SiteName" -Name *
            $returnValue.sitename=$Sitename
            $returnValue.enabled=$basicAuthConf.Enabled
            $returnValue.logonMethod=$basicAuthConf.logonMethod
            $returnValue.defaultLogonDomain=$basicAuthConf.defaultLogonDomain
            $returnValue.realm=$basicAuthConf.realm
        }
        else
        {
            Write-Verbose -Message "Website count not equal to 1."
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. Error: $($_)"
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
        [ValidateSet("Interactive","Batch","Network","ClearText")]
        [String] $logonMethod="ClearText",
        [Parameter(Mandatory=$false)]
        [String] $defaultLogonDomain="",
        [Parameter(Mandatory=$false)]
        [String] $realm=""
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
            Write-Verbose -Message "Going to update website's anonymous Authentication configuration"
            if((Get-webconfiguration -Filter //system.webServer/security/authentication/basicAuthentication -PSPath machine/webroot/apphost).overrideMode -ne  "Allow")
            {
                Write-Verbose -Message "Setting overrideMode=Allow for the machine/webroot/apphost"
                Set-WebConfiguration -Filter //system.webServer/security/authentication/basicAuthentication -PSPath machine/webroot/apphost -metadata overrideMode -value Allow
            }
            $basicAuthConf = Get-WebConfiguration -Filter system.WebServer/security/authentication/BasicAuthentication -PSPath "IIS:\Sites\$SiteName"
            $basicAuthConf.enabled = $Enabled
            $basicAuthConf.logonMethod = $logonMethod
            $basicAuthConf.defaultLogonDomain = $defaultLogonDomain
            $basicAuthConf.realm = $realm
            $basicAuthConf | Set-WebConfiguration -Filter system.WebServer/security/authentication/BasicAuthentication -PSPath "IIS:\Sites\$SiteName"
        }
        else
        {
            Write-Verbose -Message "Website count not equal to 1."
        }
    }
    catch 
    {
        Write-Verbose -Message "Error eccured. Error: $($_)"
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
        [ValidateSet("Interactive","Batch","Network","ClearText")]
        [String] $logonMethod="ClearText",
        [Parameter(Mandatory=$false)]
        [String] $defaultLogonDomain="",
        [Parameter(Mandatory=$false)]
        [String] $realm=""
    )

    $returnValue=$false
    $basicAuthConfStatus=Get-TargetResource -SiteName $SiteName -Enabled $Enabled -logonMethod $logonMethod -defaultLogonDomain $defaultLogonDomain  -realm $realm
    if($basicAuthConfStatus.Count -ne 0)
    {
        if(
            ($basicAuthConfStatus.Enabled -eq $Enabled) `
            -and ($basicAuthConfStatus.logonMethod -eq "$logonMethod") `
            -and ($basicAuthConfStatus.defaultLogonDomain -eq "$defaultLogonDomain") `
            -and ($basicAuthConfStatus.realm -eq "$realm")
          )
        {
            Write-Verbose -Message "Looks like website's basic authentication configuration is fine"
            $returnValue=$true
        }
        else
        {
            Write-Verbose -Message "Website's basic authentication configuration exists, but need to be updated"
        }
    }
    else
    {
        Write-Verbose -Message "Website's basic authentication configuration is empty. Need to update it."
    }
    return $returnValue 
}