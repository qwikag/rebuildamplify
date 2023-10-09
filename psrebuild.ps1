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
Set-Location ..
$directories = Get-ChildItem . -Directory
Write-Host "directories: $directories"
$exists = $directories.Name -like $newAppName
if ($exists) {
  Write-Host "NEXT.JS PROJECT ALREADY EXISTS"
} else {
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

  Set-Location ./$oldAppName
  $nextRebuildVersion = "13.5.3"
  Write-Host "rebuild was written with the latest amplify version = $nextRebuildVersion"
  $currentNextVersion = npm list next
  Write-Host "The current node version on your machine is         = $currentNextVersion"

  Write-Host "This rebuild will install the latest so update the variables within the script to run a different version..."
  Write-Host "npm outdated start (should be nothing if latest):"
  npm outdated
  Write-Host "npm outdated end:"


#***********************NEXT.JS***********************************
  Set-Location ..
  Write-Host "CREATE NEXT.JS APP..."
  npx create-next-app@$nextRebuildVersion $newAppName --app --js --tailwind --eslint --src-dir --import-alias "@/*"
  if (-not $?) {throw "FAILED TO CREATE NEXT.JS APP"}
}


#*************************INIT*********************************
Set-Location .\$newAppName
$directories = Get-ChildItem . -Directory
Write-Host "directories: $directories"
$exists = $directories.Name -like "amplify"
if ($exists) {
  Write-Host "AMPLIFY FOLDER ALREADY EXISTS"
} else {
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
}


#************************AUTH**********************************
#The Interface\/ \/ \/
#https://github.com/aws-amplify/amplify-cli/blob/main/packages/amplify-headless-interface/src/interface/auth/add.ts
$directories = Get-ChildItem .\amplify\backend\ -Directory
Write-Host "directories: $directories"
$exists = $directories.Name -like "auth"
if ($exists) {
  Write-Host "AUTH FOLDER ALREADY EXISTS"
} else {

# Construct the JSON structure manually
  $resourceName = $newAppName+"Cognito"
#$apiName = $newAppName+"API"
  $userPoolName = $newAppName+"UserPool"
$addAuth = @"
{
  "version": 2,
  "resourceName": "$resourceName",
  "serviceConfiguration": {
    "serviceName": "Cognito",
    "includeIdentityPool": true,
    "userPoolConfiguration": {
      "signinMethod": "EMAIL",
      "requiredSignupAttributes": ["EMAIL"],
      "userPoolName": "$userPoolName",
      "userPoolGroups": [
        {
            "groupName": "internal"
        }
      ]
    }
  }
}
"@
  Write-Host $addAuth

  # Run amplify add auth with the JSON string as a parameter
  $addAuth | jq -c | amplify add auth --headless
  if (-not $?) {throw "FAILED TO AMPLIFY ADD AUTH"}
}

#**********************Update AUTH************************************
$directories = Get-ChildItem .\amplify\backend\ -Directory
Write-Host "directories: $directories"
$exists = $directories.Name -like "function"
if ($exists) {
  Write-Host "FUNCTION FOLDER ALREADY EXISTS"
} else {

  Read-Host -Prompt "Hit your F5 macro to update amplify Auth with Cognito triggers. . ."
  Read-Host -Prompt "or hit enter to manually add your Cognito triggers. . ."
  # F5 equals these key strokes  e\/\/eeee\/eeee""eee""eee\/ee\/\/\/\/se\/sene
  # \/ = down arrow
  # s = spave
  # e = enter
  # n = n
  # "" = string of text "Your Verification Code {####}" and "365" rspectively

  # Run amplify add auth with the JSON string as a parameter
  amplify update auth
  if (-not $?) {throw "FAILED TO AMPLIFY ADD AUTH"}
  Write-Host "AMPLIFY PUSH --yes..."
  amplify push --yes
}

Read-Host -Prompt "continue to create api. . ."

#************************API**********************************
#The Interface\/ \/ \/
#https://github.com/aws-amplify/amplify-cli/blob/main/packages/amplify-headless-interface/src/interface/api/add.ts
$directories = Get-ChildItem .\amplify\backend\ -Directory
Write-Host "directories: $directories"
$exists = $directories.Name -like "api"
if ($exists) {
  Write-Host "API FOLDER ALREADY EXISTS"
} else {
  $authPoolId = "auth"+$newAppName+"Cognito"

  #Expiry Date
  $year = Get-Date -Format "yyyy"
  $month = Get-Date -Format "MM"
  $day = Get-Date -Format "dd"
  $oldYear = [int]$year
  $newYear = $oldYear+1
  $year = $newYear.ToString()
  $exipryDate = $year+"-"+$month+"-"+$day+"T23:59:59.000Z"

  # Construct the JSON structure manually
$addApi = @"
{
  "version": 1,
  "serviceConfiguration": {
    "apiName": "$newAppName",
    "transformSchema": "type Todo @model {\r\n  id: ID!\r\n  name: String!\r\n  description: String\r\n}",
    "serviceName": "AppSync",
    "defaultAuthType": {
      "mode": "AMAZON_COGNITO_USER_POOLS",
      "cognitoUserPoolId": "$authPoolId"
    },
    "conflictResolution": {},
    "additionalAuthTypes": [
      {
        "mode": "AWS_IAM"
      },
      {
        "mode": "API_KEY",
        "expirationTime": 365,
        "apiKeyExpirationDate": "$exipryDate",
        "keyDescription": "api key description"
      }
    ]
  }
}
"@

  # Read the contents of the JSON file and format it as a JSON string
  Write-Host "Add API..."
  # Run amplify add api with the JSON string as a parameter
  $addApi | jq -c | amplify add api --headless
  if (-not $?) {throw "FAILED TO AMPLIFY INIT"}


  Read-Host -Prompt "Press any key to continue to copy across schema and postconfirmation function. . ."

  #COPY IN SCHEMA
  Write-Host "COPY ACROSS SCHEMA..."
  Copy-Item "..\$oldAppName\amplify\backend\api\$oldAppName\schema.graphql" -Destination ".\amplify\backend\api\$newAppName\"
  Write-Host "COPY ACROSS LAMBDA FUNCTION..."
  #TODO:
  #Copy-Item "..\$oldAppName\amplify\backend\function\$oldAppName+CognitoPostConfirmation\src\custom.js" -Destination ".\amplify\backend\function\$newAppName+CognitoPostAuthentication\src\"
  Copy-Item "..\$oldAppName\amplify\backend\function\airmv7ced9d447ced9d44PostAuthentication\src\custom.js" -Destination ".\amplify\backend\function\$newAppName+CognitoPostAuthentication\src\"

  Write-Host "AMPLIFY PUSH..."
  amplify push --codegen --yes --force api
  if (-not $?) {throw "FAILED TO AMPLIFY PUSH"}
}

Read-Host -Prompt "Press any key to continue to copy across frontend. . ."

# Copy contents of src\app\
Copy-Item -Path "..\$oldAppName\src\app\*" -Destination "..\$newAppName\src\app\" -Recurse

# Delete contents from public
Remove-Item -Path "..\$newAppName\public\*" -Recurse -Force

# Copy contents of oldAppName\public to newAppName\public
Copy-Item -Path "..\$oldAppName\public\*" -Destination "..\$newAppName\public\" -Recurse

# Copy directory and contents of oldAppName\src\components\ to newAppName\src
Copy-Item -Path "..\$oldAppName\src\components\" -Destination "..\$newAppName\src\" -Recurse

#TODO:
#push backend
#commmit front end

Write-Host "npm outdated:"
npm outdated
Set-Location ..\$currentFolder
#throw "end of script"
