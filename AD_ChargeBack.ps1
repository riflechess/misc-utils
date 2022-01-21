#
#	Active Directory User-level chargeback report for ZZZ, QQQ (obfuscated)
#	
#	
#	6/2017 - added back in support for both systems "ALL" so we don't double-count users in ZZZ, QQQ
#   7/2018 - added support for combined  system.
#          - report total unique user count for per/user chargeback
#          - report breakdown between ZZZ / QQQ totals as a percentage, for billing purposes (basically ignore users in both systems to get %)



               
$curDate = Get-Date

#Group whitelist - these groups will be interrogated for members
$QQQgroupWhitelist = 'name -like "A_ZZ_*_View" -or name -like "A_ZZ_*_Admin" -or name -like "A_ZZ_*_Process" -or name -like "A_ZZ_*_Add"'
$ZZZgroupWhitelist = 'name -like "A_ZZ_ZZZZZZ_*View" -or name -like "A_ZZ_ZZZZZZ_*Process" -or name -like "A_ZZ_ZZZZZZ_*Admin" -or name -like "A_ZZ_ZZZZZZ_*Add" -or name -like "A_ZZ_ZZZZZZ*View" -or name -like "A_ZZ_ZZZZZZ*Process" -or name -like "A_ZZ_ZZZZZZ*Admin" -or name -like "A_ZZ_ZZZZZZ*Add"'

#Group blacklist - these groups will be ignored (no and/or nesting in AD filter critera, so have to do this later on)
#We include groups that contain "domain users" in here, as we cannot charge all of AD
$QQQgroupBlacklist = @("A_ZZ_Blacklist_View","A_ZZ_Blacklist2_View","A_ZZ_Blacklist3_View")
$ZZZgroupBlacklist = @("")

#User blacklist - users to be ommitted from charge
$QQQuserBlacklist = @("blacklistID1","blacklistID2","blacklistID3")
$ZZZuserBlacklist = @("blacklistID1","blacklistID2","blacklistID3")


#Build group/user predicates based on system



$serviceName = "Service Name"
$serviceRate = "1.99"


#create report with users, totals
$doReport = $true
#$reportName = "C:\dev\QQQ_User_Chargeback\QQQ_User_Billing\" + $system + "__ZZ_User_Chargeback_Report_" + $(get-date -f yyyy-MM-dd) + ".txt"
$reportName = "User_Chargeback_Report_" + $(get-date -f yyyy-MM-dd) + ".txt"

#email report as attachment
$doEmailReport = $true
$emailDist = "Dylan, Bob <bob@gmail.com>", "Ness, Mike <mike@gmail.com>"



Write-Output "***************************************"
Write-Output "   User Chargeback"
Write-Output "  Report Date: $curDate"
Write-Output "  Service Name: $serviceName"
Write-Output "  Service Rate: `$$serviceRate/Month"
Write-Output "***************************************"

Write-Output "`nZZZ Group Memberships to include:"
Write-Output $ZZZgroupWhitelist
Write-Output "`nQQQ Group Memberships to include:"
Write-Output $QQQgroupWhitelist

Write-Output "`nZZZ Group Memberships to exclude:"
Write-Output $ZZZgroupBlacklist
Write-Output "`nQQQ Group Memberships to exclude:"
Write-Output $QQQgroupBlacklist

Write-Output "`nZZZ User Accounts to exclude:"
Write-Output $ZZZuserBlacklist
Write-Output "`nQQQ User Accounts to exclude:"
Write-Output $QQQuserBlacklist

#Write-Output "`nBuilding $system ZZ Group List"


$ZZZgroupList = @(Get-ADGroup -Filter $ZZZgroupWhitelist | select SamAccountName)
$QQQgroupList = @(Get-ADGroup -Filter $QQQgroupWhitelist | select SamAccountName)


Write-Output "Extracting ZZZ ZZ Group List Memberships"

foreach($group in $ZZZgroupList){
	
        #cleanup group info piped from get-adgroup
	    $group= $group -replace "@{SamAccountName="
	    $group= $group -replace "}"
    
        #blacklist groups
        if ($ZZZgroupBlacklist -notcontains $group){
                Write-Output "***Extracting $group membership"
                $ZZZaccountList += @(Get-ADGroupMember $group -recursive | select SamAccountName,name)
            }
	
    
    }
Write-Output "..."
Write-Output "Total accounts in ZZZ list is" $ZZZaccountList.Count

Write-Output "Extracting QQQ ZZ Group List Memberships"
    foreach($group in $QQQgroupList){
	
        #cleanup group info piped from get-adgroup
	    $group= $group -replace "@{SamAccountName="
	    $group= $group -replace "}"
    
        #blacklist groups
        if ($QQQgroupBlacklist -notcontains $group){
                Write-Output "***Extracting $group membership"
                $QQQaccountList += @(Get-ADGroupMember $group -recursive | select SamAccountName,name)
            }
	
    
    }
Write-Output "..."
Write-Output "Total accounts in QQQ list is" $QQQaccountList.Count



#do some clean up and remove any blacklist entries
foreach($account in $ZZZaccountList){
	$account= $account -replace "@{SamAccountName="
	$account= $account -replace "; name=", " "
    $account= $account -replace "}"

    #blacklist users here (build out as var) - pull first token since format is pwID name
    if ($ZZZuserBlacklist -notcontains $account.split(" ")[0]){
        #convert to string array so we can sort and kill dupes   
        $ZZZCleanAccountList +=@($account)
    }
    
}

foreach($account in $QQQaccountList){
	$account= $account -replace "@{SamAccountName="
	$account= $account -replace "; name=", " "
    $account= $account -replace "}"

    #blacklist users here (build out as var) - pull first token since format is pwID name
    if ($QQQuserBlacklist -notcontains $account.split(" ")[0]){
        #convert to string array so we can sort and kill dupes   
        $QQQCleanAccountList +=@($account)
    }
    
}

    #dedupe account list
    $TotalCleanAccountList = $ZZZCleanAccountList + $QQQCleanAccountList | sort | select -Unique
    $ZZZCleanAccountList = $ZZZCleanAccountList | sort | select -Unique
    $QQQCleanAccountList = $QQQCleanAccountList | sort | select -Unique

    #var these as we will write to report later
    $TotalUserCount = $TotalCleanAccountList.Count
    $ZZZtotalUserCount = $ZZZCleanAccountList.Count
    $QQQtotalUserCount = $QQQCleanAccountList.Count
    $totalChargeBack = [math]::Round(($TotalUserCount * $serviceRate),2)

    $ZZZmultiplyer = [math]::Round($($($ZZZtotalUserCount/$($ZZZtotalUserCount + $QQQtotalUserCount))),4)
    $QQQmultiplyer =  [math]::Round($($($QQQtotalUserCount/$($ZZZtotalUserCount + $QQQtotalUserCount))),4)

    $ZZZallocation = [math]::Round($($ZZZmultiplyer * $TotalUserCount),2)
    $QQQallocation = [math]::Round($($QQQmultiplyer * $TotalUserCount),2)

    $ZZZcharge = [math]::Round($($ZZZallocation * $serviceRate),2)
    $QQQcharge = [math]::Round($($QQQallocation * $serviceRate),2)


    Write-Output "Total Unique accounts count after deduplication is $totalUserCount"
    Write-Output "Total Chargeback at $serviceRate/user is $totalChargeBack"
    Write-Output "Unique ZZZ accounts count after deduplication is $ZZZtotalUserCount"
    Write-Output "Unique QQQ accounts count after deduplication is $QQQtotalUserCount"
    Write-Output "$($ZZZmultiplyer * 100)% ZZZ / $($QQQmultiplyer * 100)% QQQ"

    Write-Output "ZZZ allocation is $($ZZZmultiplyer * 100)% * $TotalUserCount = $ZZZallocation, Charge is $ZZZallocation * `$$serviceRate = `$$ZZZcharge"
    Write-Output "QQQ allocation is $($QQQmultiplyer * 100)% * $TotalUserCount = $QQQallocation, Charge is $QQQallocation * `$$serviceRate = `$$QQQcharge"




$curDate = Get-Date
#hard copy report
if($doReport){
    Write-Output "`nGenerating Report $_ZZ_User_Chargeback_Report"
    if(Test-Path $reportName){
        Clear-Content $reportName
    }
    Add-Content $reportName "***************************************`n`  User Chargeback`n`tReport Date: $curDate`n`tService Name: $serviceName`n`tService Rate: `$$serviceRate/Month`n***************************************`n`n"
    Add-Content $reportName "PWID`tName`t`t`t`t`tRate"
    Add-Content $reportName "------------------------------------------------------"
    $account = $null
    foreach($account in $TotalCleanAccountList){
        #we may want try/catch here in case output buffer stream issues
        Add-Content $reportName "$account`t`t`t`$$serviceRate"
        #Write-Output $account
    }
    Add-Content $reportName "------------------------------------------------------"
    #Add-Content $reportName "Total Accounts: $totalUserCount`t`t`tTotal Charges `$$totalChargeBack"
    Add-Content $reportName "Description`t`t`t`tUnit/Interval`tQuantity`tUnit Price`tCharge"
    Add-Content $reportName "$serviceName`t`tLogin ID/Mo`t`t$totalUserCount`t`t`$$serviceRate`t`t`$$totalChargeBack`n"

    Add-Content $reportName "ZZZ Count`t`tQQQ Count"
    Add-Content $reportName "$ZZZtotalUserCount ($($ZZZmultiplyer * 100)%)`t$QQQtotalUserCount ($($QQQmultiplyer * 100)%)"


    Add-Content $reportName "ZZZ allocation is $($ZZZmultiplyer * 100)% * $TotalUserCount = $ZZZallocation, Charge is `$$ZZZcharge"
    Add-Content $reportName "QQQ allocation is $($QQQmultiplyer * 100)% * $TotalUserCount = $QQQallocation, Charge is `$$QQQcharge"


    $curDate = Get-Date
    Write-Output "`nReport Complete $curDate"
}




if($doEmailReport){
    Write-Output "`nEmailing report to $emailDist"
    send-mailmessage -from "sender <nobody@nobody.com>" -to $emailDist -subject " Monthly Chargeback" -body "Please see the attached chargeback report for $(get-date -f yyyy-MM-dd)" -Attachments $reportName -smtpServer smtp.server.here
    $curDate = Get-Date
    Write-Output "`nEmail Sent $curDate"
}

$curDate = Get-Date
Write-Output "`nScript Complete $curDate"

#deref vars from shell otherwise they can mess up subsequent runs


$account = $null
$accountList = $null
$group = $null
$groupList = $null
$CleanAccountList = $null
$totalUserCount = $null
$totalChargeBack =$null
$serviceName =$null
$serviceRate =$null

$ZZZCleanAccountList = $null
$TotalCleanAccountList = $null
$QQQCleanAccountList = $null
$TotalUserCount = $null
$ZZZtotalUserCount = $null
$QQQtotalUserCount = $null
$totalChargeBack = $null
$QQQaccountList = $null
$ZZZaccountList = $null
$ZZZallocation = $null
$QQQallocation = $null
$ZZZmultiplyer = $null
$QQQmultiplyer = $null
$ZZZcharge = $null
$QQQcharge = $null
