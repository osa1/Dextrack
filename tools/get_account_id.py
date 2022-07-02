#!/usr/bin/env python3

import requests
import sys

# https://github.com/StephenBlackWasAlreadyTaken/xDrip/issues/182
APPLICATION_ID = "d89443d2-327c-4a6f-89e5-496bbb0317db"

username = sys.argv[1]
password = sys.argv[2]

response = requests.request(
    "POST",
    "https://shareous1.dexcom.com/ShareWebServices/Services/General/AuthenticatePublisherAccount",
    json={
        "accountName": username,
        "password": password,
        "applicationId": APPLICATION_ID,
    },
)

print(response.json())
