


function Go {  
    # $data = $(Get-Content -Path /Users/jpd/Downloads/data.json | ConvertFrom-Json -depth 100) | Where-Object { $null -ne $_.servingCell.Cells };

    $dataPath = "/Users/jpd/Downloads/data.json";
    $outPath = "/Users/jpd/Downloads/datafix2.json";
    Clear-Content -Path $outPath;
    $i = 0;
    $j = 0;
    foreach ($line in $(Get-Content -Path $dataPath)) {
        $i++;
        $data = ConvertFrom-Json $line;
        if ($null -eq $data.servingCell.Cells) {
            $j++;
            continue;
            # $data.servingCell.Cells = [Array]@();
        }
        if ($null -eq $data.caInfo) {
            $data.caInfo = [Array]@();
        }
        if ($data.servingCell.Cells -isnot [array]) {
            $data.servingCell.Cells = $data.servingCell.Cells | ToArray;
        }
        if ($data.caInfo -isnot [array]) {
            $data.caInfo = $data.caInfo | ToArray;
        }
        $data | ConvertTo-Json -depth 100 -Compress | Add-Content -Path $outPath ;
    }
    Write-Host $i total lines, $j thrown out;

    # Write-Host $data.Length total rows

    # $nullCaInfoData = $($data | Where-Object { $null -eq $_.caInfo });
    # write-host $nullCaInfoData.Length null caInfo;
    # $nullCaInfoData |  ForEach-Object { $_.caInfo = @() };

    # $badCaData = $($data | Where-Object { $_.caInfo -isnot [array] });
    # write-host $badCaData.Length broken caInfo;
    # $badCaData |  ForEach-Object { $_.caInfo = $($_.caInfo | ToArray) };

    # $nullCellData = $($data | Where-Object { $null -eq $_.servingCell.Cells });
    # write-host $nullCellData.Length null cells;
    # $nullCellData |  ForEach-Object { $_.servingCell.Cells = @() };

    # $badCellData = $($data | Where-Object { $_.servingCell.Cells -isnot [array] } );
    # write-host $badCellData.Length cells not arrays ;
    # $badCellData | ForEach-Object { $_.servingCell.Cells = $($_.servingCell.Cells | ToArray) };

    # # save back to the file
    # $data | ConvertTo-Json -depth 100 -Compress | Set-Content -Path /Users/jpd/Downloads/datafix.json;
}

# function GoCells {  
#     $data = $(Get-Content -Path /Users/jpd/Downloads/data4.json | ConvertFrom-Json -depth 100);
#     Write-Host $data.Length

#     $badCaData = $($data | Where-Object ($null -eq $_.Cells -or $_.Cells -isnot [array]));
#     write-host $badCaData.Length broken ;

#     # update each null or missing array to be an empty array
#     $badCaData |  foreach { $_.Cells = ConvertTo-Array $_.Cells };

#     # save back to the file
#     $data | ConvertTo-Json -depth 100 | Set-Content -Path /Users/jpd/Downloads/data5.json
# }

function ConvertTo-Array {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject
    )
    process {
        foreach ($item in $InputObject) {
            if ($item -is [array]) {
                $item
            }
            else {
                , $item
            }
        }
    }
}

function ToArray {
    begin {
        $output = @();
    }
    process {
        $output += $_;
    }
    end {
        return , $output;
    }
}

Go