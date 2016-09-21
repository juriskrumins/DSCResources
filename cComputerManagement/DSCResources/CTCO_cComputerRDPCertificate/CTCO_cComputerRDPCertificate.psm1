function Get-TargetResource
{
    [OutputType([Hashtable])]
	param
	(
        [parameter(Mandatory)]
        [string]$Id,
        [parameter(Mandatory)]
        [string]$SubjectName,
        [parameter(Mandatory)]
        [string]$Issuer
  	)

    $returnValue = @{}
    try
    {
        Write-Verbose -Message "Getting RDP certificate SubjectName and Issuer."
        $TSGeneralSetting = Get-WMIObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'" -ErrorAction Stop
        $TSSSLCertificate=Get-ChildItem -Path Cert:\LocalMachine -Recurse  | Where-Object {$_.Thumbprint -eq $TSGeneralSetting.SSLCertificateSHA1Hash}
        if($TSSSLCertificate -ne $null)
        {
            Write-Verbose -Message "Certificate for RDP has been found. Subject=$($TSSSLCertificate.Subject) Issuer=$($TSSSLCertificate.Issuer) Thumbprint=$($TSSSLCertificate.Thumbprint)."
            $returnValue.Add('Id',$Id)
            $returnValue.Add('SubjectName',$TSSSLCertificate.Subject)
            $returnValue.Add('Issuer',$TSSSLCertificate.Issuer)
        }
        else
        {
            Write-Verbose -Message "No certificate for RDP has been found."
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $_"
    }
	$returnValue
}

function Test-TargetResource
{
    [OutputType([Boolean])]
	param
	(
        [parameter(Mandatory)]
        [string]$Id,
        [parameter(Mandatory)]
        [string]$SubjectName,
        [parameter(Mandatory)]
        [string]$Issuer
  	)

    $retValue = $true
    $CurrentRDPCertificate=Get-TargetResource -Id $Id -SubjectName $SubjectName -Issuer $Issuer
    if($CurrentRDPCertificate.Count -ne 0)
    {
        Write-Verbose -Message "RDP certificate has been set."
        if($CurrentRDPCertificate["SubjectName"] -ne $SubjectName -and $retValue)
        {
            Write-Verbose -Message "RDP certificate's SubjectName is not in desired state."
            $retValue=$false
        }
        if($CurrentRDPCertificate["Issuer"] -ne $Issuer -and $retValue)
        {
            Write-Verbose -Message "RDP certificate's Issuer is not in desired state."
            $retValue=$false
        }
        if($retValue)
        {
            Write-Verbose -Message "Looks like RDP certificate settings are in desired state."
        }
    }
    else
    {
        Write-Verbose -Message "RDP certificate has not been set."
        $retValue = $false
    }
    return $retValue
}

function Set-TargetResource
{
	param
	(
        [parameter(Mandatory)]
        [string]$Id,
        [parameter(Mandatory)]
        [string]$SubjectName,
        [parameter(Mandatory)]
        [string]$Issuer
  	)

    try
    {
        Write-Verbose -Message "Looking for a  certificate in LocalMachine\My certificate store for RDP service."
        $TSSSLCertificate=Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject-eq $SubjectName -and $_.Issuer -eq $Issuer}
        if($TSSSLCertificate -ne $null)
        {
            $TSSSLCertificateThumbprint = ($TSSSLCertificate | Sort-Object -Descending -Property NotAfter)[0].Thumbprint
            Write-Verbose -Message "Requested certificate for RDP has been found in LocalMachine\My certificate store. Thumbprint $TSSSLCertificateThumbprint"
            Write-Verbose -Message "Going to set RDP service certificate to certificate with the thumbprint $TSSSLCertificateThumbprint"
            $TSGeneralSettingWmiInstancePath = (Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").__path
            Set-WmiInstance -Path $TSGeneralSettingWmiInstancePath -Argument @{SSLCertificateSHA1Hash="$TSSSLCertificateThumbprint"} -ErrorAction Stop
            Write-Verbose -Message "RDP service certificate has been set to certificate from LocalMachine\My store and with thumbprint $TSSSLCertificateThumbprint"
        }
        else
        {
            Write-Verbose -Message "Requested certificate for RDP has not been found in LocalMachine\My certificate store."
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $_"
    }
}

Export-ModuleMember -Function *-TargetResource