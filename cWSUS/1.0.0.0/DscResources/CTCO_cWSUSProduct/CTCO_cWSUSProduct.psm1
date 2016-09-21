function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Id,
        [parameter(Mandatory = $true)]
        [System.String[]]
        $Product,
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $SyncProductCatagories=$true
    )
    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting WSUS product list for which updates synchronization enabled ..."
        $wsusServer = Get-WsusServer -ErrorAction Stop
        $wsusSubscription = $wsusServer.GetSubscription()
        $selectedProducts = $wsusSubscription.GetUpdateCategories().Title
        $returnValue.Add('Id',$Id)
        $returnValue.Add('Product',$selectedProducts)
        $returnValue.Add('SyncProductCatagories',$SyncProductCatagories)
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
    }
    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Id,
        [parameter(Mandatory = $true)]
        [System.String[]]
        $Product,
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $SyncProductCatagories=$true
    )
    try
    {
        if($SyncProductCatagories)
        {
            $myWsus = Get-WsusServer -ErrorAction Stop
            $mySubs = $myWsus.GetSubscription()
            $mySubs.StartSynchronizationForCategoryOnly()
            While($mySubs.GetSynchronizationStatus() -eq "Running")
            {
                Start-Sleep -Seconds 2
            }
            if($mySubs.GetLastSynchronizationInfo().Result -eq "Succeeded")
            {
                Write-Verbose -Message "Product category synchronization succeeded"
            }
            else
            {
                Write-Verbose -Message "Product category synchronization failed"
            }
        }
        Write-Verbose -Message "Collecting all product categories"
        $myProductsAll = Get-WsusProduct
        Write-Verbose -Message "Disabling all product categories"
        $myProductsAll | Set-WsusProduct -Disable -ErrorAction Stop -Confirm:$false
        Write-Verbose -Message "Enabling required product categories"
        $myProducts = Get-WsusProduct | Where-Object {$_.Product.Title -in $Product}
        $myProducts | Set-WsusProduct -ErrorAction Stop -Confirm:$false
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Id,
        [parameter(Mandatory = $true)]
        [System.String[]]
        $Product,
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $SyncProductCatagories=$true
    )
    $returnValue = $true
    try
    {
        $currentState = Get-TargetResource -Id $Id -Product $Product -SyncProductCatagories $SyncProductCatagories
        if ( $currentState.Count -ne 0 )
        {
            Write-Verbose -Message "Got selected product categories."
            if($currentState.Product -ne $null)
            {
                $diff=Compare-Object -ReferenceObject $Product -DifferenceObject $currentState.Product
                if($diff -eq $null)
                {
                    Write-Verbose -Message "All requested products are selected"
                }
                else
                {
                    Write-Verbose -Message "Not all requested products are selected. Missing products: $(($diff | Where-Object {$_.SideIndicator -eq "<="}).InputObject -join ',')"
                    Write-Verbose -Message "Not all selected products are required. Selected products: $(($diff | Where-Object {$_.SideIndicator -eq "=>"}).InputObject -join ',')"
                    $returnValue = $false
                }
            }
            else
            {
                Write-Verbose -Message "Product list currently empty"
                $returnValue = $false
            }
        }
        else
        {
            Write-Verbose -Message "Can't get selected product categories."
            $returnValue=$false
        }
    }
    catch
    {
        Write-Error -Message "Error occured. $_"
    }
    $returnValue
}

Export-ModuleMember -Function *-TargetResource