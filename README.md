# rebuildamplify
To install this place the "rebuildamplify" folder along sode your other amplify projectss
This rebuild process picksup your existing build and reprocesses it into a new Amplify environment and allows you to start from scrath with a new build of your backend

Once the folder is next to your existing folder and your schema in your oldApp is ready to copy across.
run the rebuild.ps1 file in powershell like so...

rebuild.ps1 <oldAppName> <newAppName> <authProfile>

oldAppName will be the top level folder of your app
newAppName will be the name of the newly built App and the folder name of the new project.
authProfile is the name of the profile in your credentials file, which Amplify cli will use to login.

the folder structure of this app is not dynamic in anyway so the location of rebuildamplify is critical. You must run the app from the rebuildamplify folder, the script will navigate from there; or you can update the script to be more dynamic.