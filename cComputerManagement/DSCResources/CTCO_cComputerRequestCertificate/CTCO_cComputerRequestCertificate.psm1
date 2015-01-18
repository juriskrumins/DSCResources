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
        [string]$SubjectName,
        [parameter(Mandatory)]
        [string]$Template
  	)

    $returnValue = @{}
    try
    {
        Write-Verbose -Message "Checking for existance of specified certificate in the following certificate store: Cert:\$StoreLocation\$StoreName ..."
        $ErrorActionPreference = "Stop"
        $storecertlist = Get-ChildItem -Path "Cert:\$StoreLocation\$StoreName"
        Foreach ($cert in $storecertlist)
        {
            if(($cert.Subject -eq $SubjectName) -and ($cert.NotAfter -ge (Get-Date)) -and (($cert.Extensions| Where-Object {$_.Oid.Value -eq "1.3.6.1.4.1.311.20.2"}).Format(1).Trim() -eq $Template))
            {
                Write-Verbose -Message "Certificate with subjectname $SubjectName found in the following certificate store: Cert:\$StoreLocation\$StoreName and is valid"
                $returnValue.Id=$Id
                $returnValue.StoreLocation=$StoreLocation
                $returnValue.StoreName=$StoreName
                $returnValue.SubjectName=$SubjectName
                $returnValue.Template=$Template
                break
            }
            else
            {
                Write-Verbose -Message "Certificate with subjectname $SubjectName not found in the following certificate store: Cert:\$StoreLocation\$StoreName"
            }
        }

    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($Error[0].Exception.Message)"
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
        [string]$SubjectName,
        [parameter(Mandatory)]
        [string]$Template
  	)

    $enumStoreName=("My")
    try
    {
        $ErrorActionPreference = "Stop"
        $issuedcertificate=Get-Certificate -Template "$Template" -CertStoreLocation "Cert:\$StoreLocation\My" -SubjectName "$SubjectName"
        $thumbprint=$issuedcertificate.Certificate.Thumbprint
        if($StoreName -notin $enumStoreName)
        {
            Move-Item -Path "Cert:\$StoreLocation\My\$thumbprint" -Destination "Cert:\$StoreLocation\$StoreName"
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($Error[0].Exception.Message)"
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
        [string]$SubjectName,
        [parameter(Mandatory)]
        [string]$Template
  	)

    $retValue = $false
    Write-Verbose -Message "Checking certificate status ..."
    $certStatus = Get-TargetResource -Id $Id -StoreLocation $StoreLocation -StoreName $StoreName -SubjectName $SubjectName -Template $Template
    if ($certStatus.Count -ne 0)
    {
        Write-Verbose -Message "Certificate found in the following certificate store: Cert:\$StoreLocation\$StoreName"
        $retValue = $true
    }
    else
    {
        Write-Verbose -Message "Certificate not found in the following certificate store: Cert:\$StoreLocation\$StoreName"
    }
    return $retValue
}

Export-ModuleMember -Function *-TargetResource