param(
	[Parameter(Mandatory)]
	[string]$oldAppName=$(throw "Old App's Name/Directory as a sibling to this rebuildamplify folder"),
	[Parameter(Mandatory)]
	[string]$newAppName=$(throw "New App's Name/Directory as a sibling to this rebuildamplify folder"),
	[Parameter(Mandatory)]
	[string]$profileName=$(throw "Profile from your ~/.aws/config file"),
	$parent="master"
)
$currentFolder = Split-Path -Path (Get-Location) -Leaf
if ($currentFolder -ne "rebuildamplify")
{
throw "You must run this from the rebuildamplify folder which should be a siblings folder to your project app folder!!!!"
}
$nodeRebuildVersion = "v20.3.1"
Write-Host "`n
rebuild was written with the latest node version    = $nodeRebuildVersion"
$currentNodeVersion = node -v
Write-Host "The current node version on your machine is         = $currentNodeVersion"

$npmRebuildVersion = "9.6.7"
Write-Host "rebuild was written with the latest npm version     = $npmRebuildVersion"
$currentNpmVersion = npm -v
Write-Host "The current node version on your machine is         = $currentNpmVersion"

$amplifyRebuildVersion = "12.5.0"
Write-Host "rebuild was written with the latest amplify version = $amplifyRebuildVersion"
$currentAmplifyVersion = amplify -v
Write-Host "The current node version on your machine is         = $currentAmplifyVersion"

Set-Location ../$oldAppName
$nextRebuildVersion = "13.5.3"
Write-Host "rebuild was written with the latest amplify version = $nextRebuildVersion"
$currentNextVersion = npm list next
Write-Host "The current node version on your machine is         = $currentNextVersion"

Write-Host "This rebuild will install the latest so update the variables within the script to run a different version..."
Write-Host "npm outdated start (should be nothing if latest):"
npm outdated
Write-Host "npm outdated end:"

Set-Location ..
Write-Host "CREATE NEXT.JS APP..."
npx create-next-app@$nextVersion $newAppName --app --js --tailwind --eslint --src-dir --import-alias "@/*"
if (-not $?) {throw "FAILED TO CREATE NEXT.JS APP"}
Set-Location .\$newAppName

# Define Amplify JSON as a PowerShell hashtable
$amplifyJson = @{
	projectName = $newAppName
	envName = "dev"
	defaultEditor = "code"
}
# Convert the Amplify JSON hashtable to a valid JSON string
$amplify = $amplifyJson | ConvertTo-Json
# Define Frontend JSON as a PowerShell hashtable
$frontendJson = @{
	frontend = "javascript"
	framework = "react"
	config = @{
			SourceDir = "src"
			DistributionDir = "build"
			BuildCommand = "npm run-script build"
			StartCommand = "npm run-script start"
	}
}
# Convert the Frontend JSON hashtable to a valid JSON string
$frontend = $frontendJson | ConvertTo-Json
# Define Providers JSON as a PowerShell hashtable
$providersJson = @{
	awscloudformation = @{
			configLevel = "project"
			useProfile = $true
			profileName = $profileName
	}
}
# Convert the Providers JSON hashtable to a valid JSON string
$providers = $providersJson | ConvertTo-Json
# Output the JSON strings for verification
Write-Host "amplifyjson = $amplify"
Write-Host "frontend = $frontend"
Write-Host "providers = $providers"
# Run amplify init with the JSON strings as parameters
Write-Host "INIT AMPLIFY..."
amplify init --amplify $amplify --frontend $frontend --providers $providers --yes
if (-not $?) {throw "FAILED TO AMPLIFY INIT"}

$addAuthJson = @{
  version = 2
  resourceName = "$newAppName Cognito"
  serviceConfiguration = @{
    serviceName = "Cognito"
    userPoolConfiguration = @{
      signinMethod = "EMAIL"
      requiredSignupAttributes = @("EMAIL")
      userPoolName = "$newAppName User Pool"
      userPoolGroups = @(
        @{
          groupName = "internal"
        },
        @{
          groupName = "partner"
        },
        @{
          groupName = "host"
        },
        @{
          groupName = "guest"
        }
			)
      refreshTokenPeriod = 60  # Refresh tokens are valid for 60 days
    }
    includeIdentityPool = $true
  }
}

$addAuth = $addAuthJson | ConvertTo-Json
Write-Host "Add AUTH..."
# Run amplify add auth with the JSON string as a parameter
$addAuth | amplify add auth --headless
if (-not $?) {throw "FAILED TO AMPLIFY ADD AUTH"}

throw "end of script"



# Define the path to your newHeadlessApi.addapi.json file
$apiConfigFile = "path\to\newHeadlessApi.addapi.json"  # Replace with the actual path
# Read the contents of the JSON file and format it as a JSON string
$apiConfigJson = Get-Content $apiConfigFile | ConvertTo-Json -Compress
Write-Host "Add API..."
# Run amplify add api with the JSON string as a parameter
amplify add api --headless --yes --config $apiConfigJson
if (-not $?) {throw "FAILED TO AMPLIFY INIT"}


Write-Host "AMPLIFY PUSH..."
amplify push 
if (-not $?) {throw "FAILED TO AMPLIFY PUSH"}

Set-Location ..\$currentFolder

#TODO:
#Copy schema.graphql across
#Copy Frontend across
#push backend
#commmit front end

Write-Host "npm outdated:"
npm outdated
