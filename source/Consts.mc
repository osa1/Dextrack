// Defines various constants (URLs etc.)

// UNUSED: This endpoint is used to get an account id. Since account id never
// changes, we don't need to get it again and again every time we lose the
// session. So currently account id is obtained externally and then hard-coded
// into the app.
//
// TODO: We should provide a way to get account id, and a setting in the watch
// face to set it.
// const DEXCOM_AUTHENTICATE_ENDPOINT = "http://shareous1.dexcom.com/ShareWebServices/Services/General/AuthenticatePublisherAccount";

import Toybox.Lang;

// Endpoint used to get session id, which is then used to read BG data.
const DEXCOM_LOGIN_ENDPOINT = "https://shareous1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountById";

// Endpoint used to read BG data.
const DEXCOM_BG_DATA_ENDPOINT = "https://shareous1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues";

// https://github.com/StephenBlackWasAlreadyTaken/xDrip/issues/182#issuecomment-1164859237
const DEXCOM_APPLICATION_ID = "d89443d2-327c-4a6f-89e5-496bbb0317db";

const MSG_REQUESTING_BG = "REQUESTING BG DATA";
const MSG_LOGGING_IN = "LOGGING IN";
const MSG_INVALID_SESSION = "SESSION INVALID";

function msgLoginError(responseCode) {
    // Handle some common errors.
    if (responseCode == -2) {
        return "BLE host timeout";
    } else if (responseCode == -104) {
        return "BLE unavailable";
    } else {
        return Lang.format("LOGIN ERROR $1$", [responseCode]);
    }
}

function msgOtherError(responseCode) {
    // Handle some common errors. Reference:
    // https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html
    if (responseCode == -2) {
        return "BLE host timeout";
    } else if (responseCode == -104) {
        return "BLE unavailable";
    } else if (responseCode == -300) {
        return "Req timeout";
    } else {
        return Lang.format("ERROR $1$", [responseCode]);
    }
}
