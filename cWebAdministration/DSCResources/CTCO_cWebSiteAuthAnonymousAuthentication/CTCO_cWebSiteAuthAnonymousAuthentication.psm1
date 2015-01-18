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
        [Parameter(Mandatory)]
        [ValidateSet("Interactive","Batch","Network","ClearText")]
        [String] $logonMethod,
        [String] $Password,
        [String] $UserName
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
            Write-Verbose -Message "Collecting website's anonymousAuthentication configuration"
            $anonAuthConf = Get-WebConfigurationProperty -Filter system.WebServer/security/authentication/anonymousAuthentication -PSPath "IIS:\Sites\$SiteName" -Name *
            $returnValue.sitename=$Sitename
            $returnValue.enabled=$anonAuthConf.Enabled
            $returnValue.logonMethod=$anonAuthConf.logonMethod
            $returnValue.password=$anonAuthConf.password
            $returnValue.username=$anonAuthConf.username
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
        [Parameter(Mandatory)]
        [ValidateSet("Interactive","Batch","Network","ClearText")]
        [String] $logonMethod,
        [String] $Password,
        [String] $UserName
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
            if((Get-webconfiguration -Filter //system.webServer/security/authentication/anonymousAuthentication -PSPath machine/webroot/apphost).overrideMode -ne  "Allow")
            {
                Write-Verbose -Message "Setting overrideMode=Allow for the machine/webroot/apphost"
                Set-WebConfiguration -Filter //system.webServer/security/authentication/anonymousAuthentication -PSPath machine/webroot/apphost -metadata overrideMode -value Allow
            }
            $anonAuthConf = Get-WebConfiguration -Filter system.webServer/security/authentication/anonymousAuthentication -PSPath "IIS:\Sites\$SiteName"
            $anonAuthConf.enabled = $Enabled
            $anonAuthConf.logonMethod = $logonMethod
            $anonAuthConf.userName = $UserName
            $anonAuthConf.password = $Password
            $anonAuthConf | Set-WebConfiguration -Filter system.webServer/security/authentication/anonymousAuthentication -PSPath "IIS:\Sites\$SiteName"
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
        [Parameter(Mandatory)]
        [ValidateSet("Interactive","Batch","Network","ClearText")]
        [String] $logonMethod,
        [String] $Password,
        [String] $UserName
    )

    $returnValue=$false
    $anonAuthConfStatus=Get-TargetResource -SiteName $SiteName -Enabled $Enabled -logonMethod $logonMethod  -Password $Password -UserName $UserName
    if($anonAuthConfStatus.Count -ne 0)
    {
        if(($anonAuthConfStatus.Enabled -eq $Enabled) -and ($anonAuthConfStatus.logonMethod -eq "$logonMethod") -and ($anonAuthConfStatus.Password -eq "$Password") -and ($anonAuthConfStatus.UserName -eq "$UserName"))
        {
            Write-Verbose -Message "Looks like website's anonymous configuration is fine"
            $returnValue=$true
        }
        else
        {
            Write-Verbose -Message "Website's anonymous configuration exists, but need to be updated"
        }
    }
    else
    {
        Write-Verbose -Message "Website's anonymous configuration is empty. Need to update it."
    }
    return $returnValue 
}