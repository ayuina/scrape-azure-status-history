<#
    .SYNOPSIS
    Scrape data from Azure Status History (https://status.azure.com/status/history/)

    .DESCRIPTION
    This script retrieved data from API which is invoked Azure Status History page and spec is not public.
    The api doesn't return convenient format like json but HTML format.
    So this script scrape and parse HTML data.

#>


function Main()
{
    Iterate-HistoryPage
}

function Iterate-HistoryPage()
{
    # page 1
    $result = Get-PageResult -page 1
    $pageCount = Get-PageCount $result
    Parse-HistoryPage -htmlContent $result.Content

    # page x
    for($page = 2; $page -le $pageCount; $page++)
    {
        $ret = Get-PageResult -page $page
        Parse-HistoryPage -htmlContent $ret.Content
    }
}

function Get-PageCount($pageResult)
{
    $pageResult.InputFields `
    | Where-Object { ($_.tagName -ieq 'input') -and ($_.type -ieq 'hidden') -and ($_.class -ieq 'wa-historyResult-count') } `
    | ForEach-Object { [int]($_.value) } `
    | Select-Object -First 1 `
    | Set-Variable count

    $countPerPage = 10
    $countLast = $count % $countPerPage
    $pageCount = ($count - $countLast)/$countPerPage + 1
    return $pageCount
}

function Get-PageResult($page)
{
    $url = "https://status.azure.com/en-us/statushistoryapi/?serviceSlug=all&regionSlug=all&startDate=all&page=$($page)&shdrefreshflag="
    Invoke-WebRequest -Method Get -Uri $url
}

function Parse-HistoryPage($htmlContent)
{
    $encoded = [System.Text.Encoding]::Unicode.GetBytes($htmlContent)
    $html = New-Object -ComObject "HTMLFile"
    $html.write($encoded)

    $month = ''
    $html.getElementsByTagName("div") | ForEach-Object {
        $div = $_

        if($div.attributes['class'].value -ieq 'row column')
        {
            $month = $div.innerText
        }
        elseif($div.attributes['class'].value -ieq 'row') 
        {
            $record = @{ month = $month }

            $header = $div.getElementsByTagName('div')[0]
            $record.date = $header.getElementsByTagName('span')[0].innerText

            $body = $div.getElementsByTagName('div')[1]
            $record.title = $body.getElementsByTagName('h3')[0].innerText
            $record.content = $body.innerText

            if($record.title -match "Tracking ID (?<tid>\w{4}-\w{3})")
            {
                $record.trackingId = $Matches['tid']
            }

            Write-Output (New-Object -TypeName PSObject -Property $record)
        }
    }

}


Main