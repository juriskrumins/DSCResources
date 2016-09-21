function Get-TargetResource
{
    [OutputType([Hashtable])]
	param
	(
        [parameter(Mandatory)]
        [string]$CA,
        [parameter(Mandatory)]
        [string]$CertStoreLocation
  	)

    $returnValue = @{}
    try
    {
        $returnValue.Add('CA',$CA)
        if(Get-Item -Path $CertStoreLocation -ErrorAction SilentlyContinue)
        {
            $returnValue.Add('CertStoreLocation',$CertStoreLocation)
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
        [string]$CA,
        [parameter(Mandatory)]
        [string]$CertStoreLocation
  	)

    try
    {
        $CAAdmin = New-Object -COM "CertificateAuthority.Admin.1" -ErrorAction Stop
        $NumberOfCACerts=$CAAdmin.GetCAProperty("$CA",0xb,0,1,0)

        for($index=0;$index -le $NumberOfCACerts-1;$index++){
            $CACert=$CAAdmin.GetCAProperty("$CA",0xc,$index,3,0)
            $TempFile=New-TemporaryFile -ErrorAction Stop
            $CACert | Out-File -FilePath "$TempFile" -Force -Encoding utf8 -ErrorAction Stop
            $CACertObj = Get-PfxCertificate -FilePath "$TempFile"
            Write-Verbose -Message "Going to import CA's certificate from $($TempFile.Fullname) file."
            Write-Verbose -Message "CA's certificate subject $($CACertObj.Subject)"
            Write-Verbose -Message "CA's certificate thumbprint $($CACertObj.Thumbprint)"
            Import-Certificate -FilePath $TempFile -CertStoreLocation $CertStoreLocation -ErrorAction Stop
            Write-Verbose -Message "Removing temporary file $TempFile"
            Remove-Item -Path $TempFile -ErrorAction Stop
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($_)"
    }
    finally
    {
    }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
	param
	(
        [parameter(Mandatory)]
        [string]$CA,
        [parameter(Mandatory)]
        [string]$CertStoreLocation
  	)

    $retValue = $true
    try{
        $CAAdmin = New-Object -COM "CertificateAuthority.Admin.1" -ErrorAction Stop
        $NumberOfCACerts=$CAAdmin.GetCAProperty("$CA",0xb,0,1,0)

        for($index=0;$index -le $NumberOfCACerts-1;$index++){
            $CACert=$CAAdmin.GetCAProperty("$CA",0xc,$index,3,0)
            $TempFile=New-TemporaryFile -ErrorAction Stop
            $CACert | Out-File -FilePath "$TempFile" -Force -Encoding utf8 -ErrorAction Stop
            $CACertObj = Get-PfxCertificate -FilePath "$TempFile"
            Remove-Item -Path $TempFile -ErrorAction Stop
            if($CACertObj.Thumbprint -notin (Get-ChildItem -Path  $CertStoreLocation).Thumbprint)
            {
                Write-Verbose -Message "Can't find CA's certificate with subject $($CACertObj.Subject) and thumbprint $($CACertObj.Thumbprint) in $CertStoreLocation"
                $retValue = $false
                break
            }
            else
            {
                Write-Verbose -Message "CA's certificate with subject $($CACertObj.Subject) and thumbprint $($CACertObj.Thumbprint) found in $CertStoreLocation"
            }
        }
    }
    catch
    {
        Write-Verbose -Message  "Error occured. $($_)"
    }
    return $retValue
}

Export-ModuleMember -Function *-TargetResource