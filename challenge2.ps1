Using Azure Instance Metadata Service (IMDS)
https://learn.microsoft.com/en-us/azure/virtual-machines/instance-metadata-service?tabs=windows


    Windows - Powershell commmand
    Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -NoProxy -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | ConvertTo-Json -Depth 64
    You have to install az powershell to use the above command

    Linux - shell
    curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq

**The responsee is a JSON object**