function Get-TargetResource
{
    [OutputType([Hashtable])]
	param
	(
        [parameter(Mandatory)]
        [string]$Id,
        [parameter(Mandatory)]
        [string]$StoreLocation,
        [parameter(Mandatory)]
        [string]$StoreName,
        [parameter(Mandatory)]
        [string]$PfxPassword,
        [parameter(Mandatory)]
        [string]$Base64EncodedPfx
  	)

    $returnValue = @{}
    try
    {
        Write-Verbose -Message "Checeking for existance of specified certificate in the following certificate store: Cert:\$StoreLocation\$StoreName ..."
        $ErrorActionPreference = "Stop"
        $storecertlist = Get-ChildItem -Path "Cert:\$StoreLocation\$StoreName"
        $certificate=Get-CertificateFromBase64EncodedPfx -PfxPassword $PfxPassword -Base64EncodedPfx $Base64EncodedPfx
        if($storecertlist.Thumbprint -contains $certificate.Thumbprint)
        {
            Write-Verbose -Message "Specified certificate is in the following certificate store: Cert:\$StoreLocation\$StoreName"
            $returnValue.Id=$Id
            $returnValue.StoreLocation=$StoreLocation
            $returnValue.StoreName=$StoreName
            $returnValue.PfxPassword=$PfxPassword
            $returnValue.Base64EncodedPfx=$Base64EncodedPfx
        }
        else
        {
            Write-Verbose -Message "Specified certificate is not in the following certificate store: Cert:\$StoreLocation\$StoreName"
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($_)"
    }
	$returnValue
}

function Set-TargetResource
{
	param
	(
        [parameter(Mandatory)]
        [string]$Id,
        [parameter(Mandatory)]
        [string]$StoreLocation,
        [parameter(Mandatory)]
        [string]$StoreName,
        [parameter(Mandatory)]
        [string]$PfxPassword,
        [parameter(Mandatory)]
        [string]$Base64EncodedPfx
  	)

    $enumStoreName=("AddressBook","AuthRoot","CertificateAuthority","Disallowed","My","Root","TrustedPeople","TrustedPublisher")
    try
    {
        $ErrorActionPreference = "Stop"
        $pfxfilename=[System.IO.Path]::GetTempFileName()
        Add-Type -AssemblyName System.Security
        Get-PfxFromBase64EncodedPfx -Base64EncodedPfx $Base64EncodedPfx |  Set-Content -Path $pfxfilename
        Import-PfxCert -PfxCertificatePath $pfxfilename -StoreLocation $StoreLocation -StoreName $StoreName -PfxPassword $PfxPassword
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($_)"
    }
    finally
    {
        Remove-Item -Path $pfxfilename
    }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
	param
	(
        [parameter(Mandatory)]
        [string]$Id,
        [parameter(Mandatory)]
        [string]$StoreLocation,
        [parameter(Mandatory)]
        [string]$StoreName,
        [parameter(Mandatory)]
        [string]$PfxPassword,
        [parameter(Mandatory)]
        [string]$Base64EncodedPfx
  	)

    $retValue = $false
    Write-Verbose -Message "Checking certificate status ..."
    $certStatus = Get-TargetResource -Id $Id -StoreLocation $StoreLocation -StoreName $StoreName -PfxPassword $PfxPassword -Base64EncodedPfx $Base64EncodedPfx
    if ($certStatus.Count -ne 0)
    {
        Write-Verbose -Message "Specified certificate found in the following certificate store: Cert:\$StoreLocation\$StoreName"
        $retValue = $true
    }
    else
    {
        Write-Verbose -Message "Specified certificate not found in the following certificate store: Cert:\$StoreLocation\$StoreName"
    }
    return $retValue
}

function Get-CertificateFromBase64EncodedPfx
{
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
	param
	(
        [parameter(Mandatory)]
        [string]$PfxPassword,
        [parameter(Mandatory)]
        [string]$Base64EncodedPfx
  	)
    try
    {
        Add-Type -AssemblyName System.Security
        $filename=[System.IO.Path]::GetTempFileName()
        $ContentBytes = [System.Convert]::FromBase64String($Base64EncodedPfx)
        $ContentDecoded = [System.Text.Encoding]::UTF8.GetString($ContentBytes)
        $ContentDecoded | set-content ($filename)
        $securepwd=ConvertTo-SecureString -String "$PfxPassword" -AsPlainText -Force
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $filename,$securepwd
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($_)"
    }
    finally
    {
        Remove-Item $filename
    }
    return $certificate
}

function Get-PfxFromBase64EncodedPfx
{
    [OutputType([System.String])]
	param
	(
        [parameter(Mandatory)]
        [string]$Base64EncodedPfx
  	)
    try
    {
        $ContentBytes = [System.Convert]::FromBase64String($Base64EncodedPfx)
        $ContentDecoded = [System.Text.Encoding]::UTF8.GetString($ContentBytes)
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($_)"
    }
    return $ContentDecoded
}

function Import-PfxCert
{ 
    param(
        [parameter(Mandatory)]
        [String]$PfxCertificatePath,
        [parameter(Mandatory)]
        [string]$StoreLocation,
        [parameter(Mandatory)]
        [string]$StoreName,
        [parameter(Mandatory)]
        [string]$PfxPassword
    )
     
    $pfxObj = new-object System.Security.Cryptography.X509Certificates.X509Certificate2 
    $pfxObj.import($PfxCertificatePath,$PfxPassword,"Exportable,PersistKeySet")
    $store = new-object System.Security.Cryptography.X509Certificates.X509Store($StoreName,$StoreLocation)
    $store.open("MaxAllowed")
    $store.add($pfxObj)
    $store.close()
}

Export-ModuleMember -Function *-TargetResource