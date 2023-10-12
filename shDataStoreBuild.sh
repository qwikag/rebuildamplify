#!/bin/bash
appName=$1
profileName=$2
nextRebuildVersion="13.5.3"


currentFolder=$(pwd | sed 's#.*/##')
if [ $currentFolder != "rebuildamplify" ]; then
  echo "You must run this from the rebuildamplify folder which should be a siblings folder to your project app folder!!!!"
  exit 1
fi

cd ..
if [ -d "$appName" ]; then
  echo "$appName FOLDER ALREADY EXISTS"
else
    npx create-next-app@$nextRebuildVersion $appName --app --js --tailwind --eslint --src-dir --import-alias "@/*"
    if [ $? -ne 0 ]; then
    echo "FAILED TO CREATE NEXT.JS APP"
    exit 1
    fi
fi

#AMPLIFY INIT
cd "$appName"
if [ -d "amplify" ]; then
  echo "AMPLIFY FOLDER ALREADY EXISTS"
else
  amplifyJson='{
    "projectName": "'"$appName"'",
    "envName": "dev",
    "defaultEditor": "code"
  }'
  frontendJson='{
    "frontend": "javascript",
    "framework": "react",
    "config": {
      "SourceDir": "src",
      "DistributionDir": "build",
      "BuildCommand": "npm run-script build",
      "StartCommand": "npm run-script start"
    }
  }'
  providersJson='{
    "awscloudformation": {
      "configLevel": "project",
      "useProfile": true,
      "profileName": "'"$profileName"'"
    }
  }'

  # Output the JSON strings for verification
  echo "amplifyjson = $amplifyJson"
  echo "frontend = $frontendJson"
  echo "providers = $providersJson"

  # Run amplify init with the JSON strings as parameters
  echo "INIT AMPLIFY..."
  amplify init --amplify "$amplifyJson" --frontend "$frontendJson" --providers "$providersJson" --yes
  if [ $? -ne 0 ]; then
    echo "FAILED TO AMPLIFY INIT"
    exit 1
  fi
fi

#AMPLIFY AUTH
if [ -d "amplify/backend/auth" ]; then
  echo "AUTH FOLDER ALREADY EXISTS"
else
  # Construct the JSON structure manually
  resourceName="${appName}Cognito"
  userPoolName="${appName}UserPool"
  identityPoolName="${appName}IdentityPool"
  addAuth='{
    "version": 2,
    "resourceName": "'"$resourceName"'",
    "serviceConfiguration": {
      "serviceName": "Cognito",
      "includeIdentityPool": true,
      "identityPoolConfiguration": {
        "identityPoolName": "'"$identityPoolName"'"
      },
      "userPoolConfiguration": {
        "signinMethod": "EMAIL",
        "requiredSignupAttributes": ["EMAIL"],
        "userPoolName": "'"$userPoolName"'",
        "mfa": {
          "mode": "ON",
          "mfaTypes": ["TOTP"],
          "smsMessage": "Your authentication code is {####}"
        },
        "userPoolGroups": [
          {
            "groupName": "admin"
          },
          {
            "groupName": "superuser"
          },
          {
            "groupName": "user"
          }
        ]
      }
    }
  }'

  # Output the JSON for verification
  echo "$addAuth"

  # Run amplify add auth with the JSON string as a parameter
  echo "$addAuth" | jq -c | amplify add auth --headless
  if [ $? -ne 0 ]; then
    echo "FAILED TO AMPLIFY ADD AUTH"
    exit 1
  fi
fi

# Check if a "function" directory already exists within "amplify/backend"
if [ -d "amplify/backend/function" ]; then
  echo "FUNCTION FOLDER ALREADY EXISTS"
else
  read -p "Hit your F5 macro to update amplify Auth with Cognito triggers, or press enter to manually add your Cognito triggers..."
  # F5 equals these key strokes  e\/\/eeee\/eeeeeee""eee\/ee\/\/\/\/se\/sene
  # \/ = down arrow
  # s = space
  # e = enter
  # n = n
  # "" = string of text "Your Verification Code {####}" and "365" rspectively

  # Run amplify update auth
  echo "AMPLIFY UPDATE AUTH..."
  amplify update auth
  if [ $? -ne 0 ]; then
    echo "FAILED TO AMPLIFY UPDATE AUTH"
    exit 1
  fi

  echo "AMPLIFY PUSH --yes..."
  amplify push --yes
fi

# Check if a "@aws-amplify" directory already exists within "node_modules"
if [ -d "node_modules/@aws-amplify" ]; then
  echo "@aws-amplify FOLDER ALREADY EXISTS"
else
  npm install aws-amplify @aws-amplify/ui-react
fi

# Check if a "@headlessui" directory already exists within "node_modules"
if [ -d "node_modules/@headlessui" ]; then
  echo "@headlessui FOLDER ALREADY EXISTS"
else
  npm install @headlessui/react
fi

# Check if a "@heroicons" directory already exists within "node_modules"
if [ -d "node_modules/@heroicons" ]; then
  echo "@heroicons FOLDER ALREADY EXISTS"
else
  npm install @heroicons/react
fi

# Check if a "@aws-sdk" directory already exists within "node_modules"
if [ -d "node_modules/@aws-sdk" ]; then
  echo "@aws-sdk FOLDER ALREADY EXISTS"
else
  npm install aws-sdk
  npm add -D encoding
fi