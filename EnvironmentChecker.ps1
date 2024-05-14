<#This variable will take path for csv with servers file#>
$ServerListFilePath="C:\Users\Administrator\Desktop\Projects\environment-checker\EnvCheckerList.csv"

<#Here we out a delimiter of , on our csv just to knnow diferences on each field#>
$ServerList=Import-Csv -Path $ServerListFilePath -Delimiter ','

$Export=[System.Collections.ArrayList]@()
foreach($Server in $ServerList){
    <#Remember that your computers need to be on the same 
    network, domain and have firewall rules off or ping available#>

    <#we save every last important data of our machines before 
    check the new status to compare them#>
    $ServerNameVar=$Server.ServerName
    $LastStatusVar=$Server.LastStatus
    $DownSinceVar=$Server.DownSince
    $LastDownAlertVar=$Server.LastDownAlertTime
    

    $Connection=Test-Connection $Server.ServerName -Count 1 -Quiet
    <#
    Count 1: to try connection 1 time
    Quiet: to return true or false
    #>
    $DateTime=Get-Date
    <#We use real date to check if everything it's correct#>

    if($Connection -eq "True"){
        if($LastStatusVar -ne "True"){
            $Server.DownSince=$null
            $Server.LastDownAlertTime=$null
            Write-Output "$($ServerNameVar) is now online"
        }
        else{
            Write-Output "$($ServerNameVar) is still online"
        }
    }
    else{
        if($LastStatusVar -eq "True"){
            Write-Output "$($ServerNameVar) is now offline"
            $Server.DownSince=$DateTime
            $Server.LastDownAlertTime=$DateTime
        }
        else{
            $DownFor=$((Get-Date -Date $DateTime) - (Get-Date -Date $DownSinceVar)).TotalDays
            $SinceLastDownAlert=$((Get-Date -Date $DateTime) - (Get-Date -Date $LastDownAlertVar)).TotalDays
            <#Display more details if the computers were offline more than 1 day and 
            the alert was send at least one day ago#>
            if(($DownFor -ge 1) -and ($SinceLastDownAlert -ge 1)){
                Write-Output "It has been $($SinceLastDownAlert) days since last alert"
                Write-Output "$($ServerNameVar) is still offline for $($DownFor) days"
                $Server.LastDownAlertTime=$DateTime
            }
        }
    }
    <#Updater of our server last status on our csv,
    later upload it on our array and then on our csv#>
    $Server.LastStatus=$Connection
    $Server.LastCheckTime=$DateTime
    [void]$Export.add($Server)
}

$Export | Export-Csv -Path $ServerListFilePath -Delimiter ',' -NoTypeInformation