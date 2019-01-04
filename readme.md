# BuildApp

This script is intended to queue builds in all configured branches of selected AppCenter project using latest source verion on branch.

### Prerequesites

Must first create and save value of AppCenter API Token. That can be done in AppCenter -> Account Settings -> API Tokens.

### Required Parameters

-appToken [<string>] - API authorization token used in AppCenter.

-appName [<string>] - name of your application in AppCenter. Notice that you should use actual name of application and not the display name.

-buildsLimit [<int>] - number of builds that will be queued in parallel. Default value is 2.

-queue [<switchParameter>] - confirmation that builds must be started.

-showVerbose [<switchParameter>] - shows execution status.

-showReport [<switchParameter>] - shows summarized report about latest builds in definitions.

## Build With

Microsoft Powershell

## EXAMPLES

ps> .\BuildApp.ps1 -appToken *ApiToken* -appName *ApplicationName* -queue -showReport

## Versioning & Author

VERSION
1.0

DATE MODIFIED
01/04/2019

AUTHOR
Maksim Petrov

