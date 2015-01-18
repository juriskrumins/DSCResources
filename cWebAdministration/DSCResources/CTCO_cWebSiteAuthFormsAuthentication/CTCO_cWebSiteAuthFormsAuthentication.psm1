function Get-TargetResource 
{
    [OutputType([Hashtable])]
    param 
    (   
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteName,
        [Parameter(Mandatory)]
        [ValidateSet("Windows","Forms")]
        [string]$mode,
        [Parameter(Mandatory=$false)]
        [ValidateSet("UseUri","UseCookies","AutoDetect","UseDeviceProfile")]
        [String] $Cookieless="UseDeviceProfile",
        [Parameter(Mandatory=$false)]
        [String] $defaultUrl="default.aspx",
        [Parameter(Mandatory=$false)]
        [String] $loginUrl="login.aspx",
        [Parameter(Mandatory=$false)]
        [String] $Name=".ASPXAUTH",
        [Parameter(Mandatory=$false)]
        [ValidateSet("All","None","Encryption","Validation")]
        [String] $protection="All",
        [Parameter(Mandatory=$false)]
        [boolean]$requireSSL=$false,
        [Parameter(Mandatory=$false)]
        [boolean]$slidingExpiration=$true,
        [Parameter(Mandatory=$false)]
        [int]$timeout=30
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
            Write-Verbose -Message "Collecting website's FormsAuthentication configuration"
            $formsAuthConf = Get-WebConfigurationProperty -Filter system.web/authentication -PSPath "IIS:\Sites\$SiteName" -Name *
            if($formsAuthConf.mode -eq $mode)
            {
                $returnValue.sitename=$WebSite.Name
                $returnValue.mode=$formsAuthConf.mode
                $returnValue.Cookieless = $formsAuthConf.forms.Cookieless
                $returnValue.defaultUrl = $formsAuthConf.forms.defaultUrl 
                $returnValue.loginUrl = $formsAuthConf.forms.loginUrl 
                $returnValue.Name = $formsAuthConf.forms.Name 
                $returnValue.protection = $formsAuthConf.forms.protection 
                $returnValue.requireSSL = $formsAuthConf.forms.requireSSL
                $returnValue.slidingExpiration = $formsAuthConf.forms.slidingExpiration
                $returnValue.timeout = $formsAuthConf.forms.timeout.TotalMinutes
            }
            else
            {
                Write-Verbose -Message "Forms Authentication mode for website $Sitename don't match the specified"
            }
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
        [ValidateSet("Windows","Forms")]
        [string]$mode,
        [Parameter(Mandatory=$false)]
        [ValidateSet("UseUri","UseCookies","AutoDetect","UseDeviceProfile")]
        [String] $Cookieless="UseDeviceProfile",
        [Parameter(Mandatory=$false)]
        [String] $defaultUrl="default.aspx",
        [Parameter(Mandatory=$false)]
        [String] $loginUrl="login.aspx",
        [Parameter(Mandatory=$false)]
        [String] $Name=".ASPXAUTH",
        [Parameter(Mandatory=$false)]
        [ValidateSet("All","None","Encryption","Validation")]
        [String] $protection="All",
        [Parameter(Mandatory=$false)]
        [boolean]$requireSSL=$false,
        [Parameter(Mandatory=$false)]
        [boolean]$slidingExpiration=$true,
        [Parameter(Mandatory=$false)]
        [int]$timeout=30
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
            Write-Verbose -Message "Going to update website's Forms Authentication configuration"
            $formsAuthConf = Get-WebConfiguration -Filter system.web/authentication -PSPath "IIS:\Sites\$SiteName"
            $formsAuthConf.mode=$mode
            $formsAuthConf.forms.cookieless=$Cookieless
            $formsAuthConf.forms.defaultUrl=$defaultUrl
            $formsAuthConf.forms.loginUrl=$loginUrl
            $formsAuthConf.forms.name=$Name
            $formsAuthConf.forms.protection=$protection
            $formsAuthConf.forms.requireSSL=$requireSSL
            $formsAuthConf.forms.slidingExpiration=$slidingExpiration
            $timespan=New-TimeSpan -Minutes $timeout
            $formsAuthConf.forms.timeout="$($timespan.Hours):$($timespan.Minutes):$($timespan.Seconds)"
            $formsAuthConf | Set-WebConfiguration -Filter system.web/authentication -PSPath "IIS:\Sites\$SiteName"
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
        [ValidateSet("Windows","Forms")]
        [string]$mode,
        [Parameter(Mandatory=$false)]
        [ValidateSet("UseUri","UseCookies","AutoDetect","UseDeviceProfile")]
        [String] $Cookieless="UseDeviceProfile",
        [Parameter(Mandatory=$false)]
        [String] $defaultUrl="default.aspx",
        [Parameter(Mandatory=$false)]
        [String] $loginUrl="login.aspx",
        [Parameter(Mandatory=$false)]
        [String] $Name=".ASPXAUTH",
        [Parameter(Mandatory=$false)]
        [ValidateSet("All","None","Encryption","Validation")]
        [String] $protection="All",
        [Parameter(Mandatory=$false)]
        [boolean]$requireSSL=$false,
        [Parameter(Mandatory=$false)]
        [boolean]$slidingExpiration=$true,
        [Parameter(Mandatory=$false)]
        [int]$timeout=30
    )

    $returnValue=$false
    $formsAuthConfStatus=Get-TargetResource -SiteName $SiteName -Mode $mode -Cookieless $Cookieless -defaultUrl $defaultUrl -loginUrl $loginUrl -Name $name -protection $protection -requireSSL $requireSSL -slidingExpiration $slidingExpiration -timeout $timeout
    if($formsAuthConfStatus.Count -ne 0)
    {
        if(($formsAuthConfStatus.mode -eq "$mode") `
            -and ($formsAuthConfStatus.Cookieless -eq $Cookieless) `
            -and ($formsAuthConfStatus.defaultUrl -eq "$defaultUrl") `
            -and ($formsAuthConfStatus.loginUrl -eq "$loginUrl") `
            -and ($formsAuthConfStatus.Name -eq "$Name") `
            -and ($formsAuthConfStatus.protection -eq "$protection") `
            -and ($formsAuthConfStatus.requireSSL -eq $requireSSL) `
            -and ($formsAuthConfStatus.slidingExpiration -eq $slidingExpiration) `
            -and ($formsAuthConfStatus.timeout -eq $timeout))
        {
            Write-Verbose -Message "Looks like website's forms authentication configuration is fine"
            $returnValue=$true
        }
        else
        {
            Write-Verbose -Message "Website's forms authentication configuration exists, but need to be updated"
        }
    }
    else
    {
        Write-Verbose -Message "Website's forms authentication configuration is empty. Need to update it."
    }
    return $returnValue 
}