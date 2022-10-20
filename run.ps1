function Set-Profile {
    $profile_name = Read-Host "Set Profile"
    if($profile_name -eq "q" -Or $profile_name -eq "Q") {
        exit
    } elseif($profile_name) {
        Write-Output $profile_name
        return
    } else {
        Set-Profile
    }
}
function MakeZippedLambda {

    Push-Location "$current_dir/root/lambda_function/AppLogSSEEventForPutObject"
    $compress = @{
        Path= "./*"
        CompressionLevel = "Fastest"
        DestinationPath = "../AppLogSSEEventForPutObject.zip"
    }
    Compress-Archive @compress -Force

    Write-host "Compress zip -" $compress.DestinationPath
    Pop-Location

    Push-Location "$current_dir/root/lambda_function/CloudWatchLogsToLogS3Export"
    $compress = @{
        Path= "./*"
        CompressionLevel = "Fastest"
        DestinationPath = "../CloudWatchLogsToLogS3Export.zip"
    }
    Compress-Archive @compress -Force
    Write-host "Compress zip -" $compress.DestinationPath
    Pop-Location

    Push-Location "$current_dir/root/lambda_function/Consumer/lambda_function"
    $compress = @{
        Path= "./*"
        CompressionLevel = "Fastest"
        DestinationPath = "../lambda_function.zip"
    }
    Compress-Archive @compress -Force
    Write-host "Compress zip -" $compress.DestinationPath
    Pop-Location

    Push-Location "$current_dir/root/lambda_function/layer"
    $compress = @{
        Path= "./python"
        CompressionLevel = "Fastest"
        DestinationPath = "./python.zip"
    }
    Compress-Archive @compress -Force
    Write-host "Compress zip -" $compress.DestinationPath
    Pop-Location
}


$scriptpath = $MyInvocation.MyCommand.Path
$current_dir = Split-Path $scriptpath
Write-host "Script directory is $current_dir"

$profile_name = Set-Profile
Write-Output "profile is $profile_name"

$tfvars = "../conf/$profile_name.tfvars"
$tfstate = "../state/$profile_name.terraform.tfstate"
Write-Output "tfvars file is located at $tfvars"
Write-Output "tfstate file is located at $tfstate"

MakeZippedLambda

Push-Location "$current_dir/root"

terraform init
terraform apply -var-file="$tfvars" -state="$tfstate"

Pop-Location