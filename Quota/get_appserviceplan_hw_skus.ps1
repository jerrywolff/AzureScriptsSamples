<#











Other uris 
 #$uri = "https://management.azure.com/subscriptions/$($sub.id)/providers/Microsoft.Web/skus?api-version=2022-03-01"

#$uri = "https://management.azure.com/subscriptions/$($sub.id)/resourceGroups/wolffappserviceplanrg/providers/Microsoft.Web/serverfarms/wolffappserviceplan01?api-version=2022-09-01"
#$uri = "https://management.azure.com/subscriptions/$($sub.id)/resourceGroups/wolffappserviceplanrg/providers/Microsoft.Web/serverfarms/wolffappserviceplan01/capabilities?api-version=2022-03-01"




#>

















 connect-azaccount 

 
 $sub = get-azsubscription | ogv -title " Select subscription to check on App Sku HW options:" -PassThru




   set-azcontext -Subscription $sub.Name
 

          Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
            try
            {
                $AzureLogin = Get-AzSubscription -SubscriptionId $($sub.id)
                $currentContext = Get-AzContext
                $token = Get-AzAccessToken -TenantId $($sub.TenantId)
                if($Token.ExpiresOn -lt $(get-date))
                {
                    "Logging you out due to cached token is expired for REST AUTH.  Re-run script"
                    #$null = Disconnect-AzAccount        
                } 
             
                
 
            }
            catch
            {

                $AzureLogin = Get-AzSubscription  -SubscriptionId $($sub.id)
                $currentContext = Get-AzContext
                $token = Get-AzAccessToken -TenantId $($sub.TenantId)
             }
                   
 

 function BuildBody
(
    [parameter(mandatory=$True)]
    [string]$method
)
{
    $BuildBody = @{
    Headers = @{
        Authorization = "Bearer $($token.token)"
        'Content-Type' = 'application/json'
    }
    Method = $Method
    UseBasicParsing = $true
    }
    $BuildBody
}  
 
  $body = BuildBody GET

 $sub = get-azsubscription -SubscriptionName "wolffentpsub"
  set-azcontext -Subscription $sub.Name

    
 $skulist = ''


$uri = "https://management.azure.com/subscriptions/$($sub.id)/resourceGroups/wolffappserviceplanrg/providers/Microsoft.Web/serverfarms/wolffappserviceplan01/skus?api-version=2022-03-01"

$response = Invoke-RestMethod -Uri $uri -Headers $authHeader -Method GET



$response | gm
($response.value).GetEnumerator() | foreach-object {

            write-host "Name : $($_.sku.name)  : Tier $($_.sku.tier) " -ForegroundColor green 
            write-host "Capacity:  Min $($_.capacity.Minimum) Max: $($_.capacity.Maximum) ScaleType : $($_.scaletype)  elasticMaximum :$($_.capacity.elasticMaximum) elasticScalingAllowed : $($_.capacity.elasticScalingAllowed) " -ForegroundColor Cyan 
            write-host "" -ForegroundColor green 
 
             $Skuobj = new-object PSObject 

             $skuobj | Add-Member -MemberType NoteProperty -Name name -Value $($_.sku.name)
              $skuobj | Add-Member -MemberType NoteProperty -Name tier -Value $($_.sku.tier)
             $skuobj | Add-Member -MemberType NoteProperty -Name capacityMin -Value $($_.capacity.Minimum)
             $skuobj | Add-Member -MemberType NoteProperty -Name capacityMax -Value $($_.capacity.Maximum)
             $skuobj | Add-Member -MemberType NoteProperty -Name scaletype -Value $($_.capacity.scaletype)
             $skuobj | Add-Member -MemberType NoteProperty -Name elasticMaximum -Value $($_.capacity.elasticMaximum)
             $skuobj | Add-Member -MemberType NoteProperty -Name elasticScalingAllowed -Value $($_.capacity.elasticScalingAllowed)
             [array]$skulist += $skuobj



 }






$CSS = @"

<Title>Azure App Service Plan Skus : $(Get-Date -Format 'dd MMMM yyyy') </Title>

 <H2>Azure App Service Plan Skus:$(Get-Date -Format 'dd MMMM yyyy')  </H2>

<Style>


th {
	font: bold 11px "Trebuchet MS", Verdana, Arial, Helvetica,
	sans-serif;
	color: #FFFFFF;
	border-right: 1px solid #C1DAD7;
	border-bottom: 1px solid #C1DAD7;
	border-top: 1px solid #C1DAD7;
	letter-spacing: 2px;
	text-transform: uppercase;
	text-align: left;
	padding: 6px 6px 6px 12px;
	background: #5F9EA0;
}
td {
	font: 11px "Trebuchet MS", Verdana, Arial, Helvetica,
	sans-serif;
	border-right: 1px solid #C1DAD7;
	border-bottom: 1px solid #C1DAD7;
	background: #fff;
	padding: 6px 6px 6px 12px;
	color: #6D929B;
}
</Style>


"@




($skulist | select name ,tier,capacityMin, capacityMax, scaletype, elasticMaximum, elasticScalingAllowed `
| ConvertTo-Html -Head $CSS ) `
|  Out-File "c:\temp\appserviceplan_hwSkus.html"


invoke-item "c:\temp\appserviceplan_hwSkus.html"

#######################################################################

$Region = "West US"

 $subscriptionselected = 'wolffentpsub'





 $resultsfilename = 'appserviceplan_hw_skus.csv'


 $skulist | select name ,tier,capacityMin, capacityMax, scaletype, elasticMaximum, elasticScalingAllowed `
 | export-csv $resultsfilename 




$resourcegroupname = 'wolffautomationrg'
$subscriptioninfo = get-azsubscription -SubscriptionName $subscriptionselected 
$TenantID = $subscriptioninfo | Select-Object tenantid
$storageaccountname = 'wolffautosa'
$storagecontainer = 'appserviceskus'
### end storagesub info

set-azcontext -Subscription $($subscriptioninfo.Name)  -Tenant $($TenantID.TenantId)


#BEGIN Create Storage Accounts
 
 
 
 try
 {
     if (!(Get-AzStorageAccount -ResourceGroupName $resourcegroupname -Name $storageaccountname ))
    {  
        Write-Host "Storage Account Does Not Exist, Creating Storage Account: $storageAccount Now"

        # b. Provision storage account
        New-AzStorageAccount -ResourceGroupName $resourcegroupname  -Name $storageaccountname -Location $region -AccessTier Hot -SkuName Standard_LRS -Kind BlobStorage -Tag @{"owner" = "Jerry wolff"; "purpose" = "Az Automation storage write" } -Verbose
 
     
        Get-AzStorageAccount -Name   $storageaccountname  -ResourceGroupName  $resourcegroupname  -verbose
     }
   }
   Catch
   {
         WRITE-DEBUG "Storage Account Aleady Exists, SKipping Creation of $storageAccount"
   
   } 
        $StorageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourcegroupname  –StorageAccountName $storageaccountname).value | select -first 1
        $destContext = New-azStorageContext  –StorageAccountName $storageaccountname `
                                        -StorageAccountKey $StorageKey


             #Upload user.csv to storage account

        try
            {
                  if (!(get-azstoragecontainer -Name $storagecontainer -Context $destContext))
                     { 
                         New-azStorageContainer $storagecontainer -Context $destContext
                        }
             }
        catch
             {
                Write-Warning " $storagecontainer container already exists" 
             }
       

         Set-azStorageBlobContent -Container $storagecontainer -Blob $resultsfilename  -File $resultsfilename -Context $destContext -force
        
 
 
 