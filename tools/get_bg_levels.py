#!/usr/bin/env python3

import requests
import sys

# Example program, printing last 10 bg levels.
# Run with `python3 <program> <Dexcom username> <Dexcom password>`.

# https://github.com/StephenBlackWasAlreadyTaken/xDrip/issues/182
APPLICATION_ID = "d89443d2-327c-4a6f-89e5-496bbb0317db"

username = sys.argv[1]
password = sys.argv[2]

account_id_response = requests.request(
    "POST",
    "https://shareous1.dexcom.com/ShareWebServices/Services/General/AuthenticatePublisherAccount",
    json={
        "accountName": username,
        "password": password,
        "applicationId": APPLICATION_ID,
    },
)

account_id = account_id_response.json()

print("Account id = %s" % account_id)

session_id_response = requests.request(
    "POST",
    "https://shareous1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountById",
    json={
        "accountId": account_id,
        "password": password,
        "applicationId": APPLICATION_ID,
    },
)

session_id = session_id_response.json()

print("Session id = %s" % session_id)

bg_data = requests.request(
    "POST",
    f"https://shareous1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId={session_id}&minutes=1440&maxCount=10",
)

print(bg_data.json())
