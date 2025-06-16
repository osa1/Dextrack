// Implements temporal event handling (background services).

using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

// UNUSED: This endpoint is used to get an account id. Since account id never
// changes, we don't need to get it again and again every time we lose the
// session. So currently account id is obtained externally and then hard-coded
// into the app.
//
// TODO: We should provide a way to get account id, and a setting in the watch
// face to set it.
// const DEXCOM_AUTHENTICATE_ENDPOINT = "http://shareous1.dexcom.com/ShareWebServices/Services/General/AuthenticatePublisherAccount";

// https://github.com/StephenBlackWasAlreadyTaken/xDrip/issues/182#issuecomment-1164859237
(:background)
const DEXCOM_APPLICATION_ID = "d89443d2-327c-4a6f-89e5-496bbb0317db";

// Endpoint used to get session id, which is then used to read BG data.
(:background)
const DEXCOM_LOGIN_ENDPOINT = "https://shareous1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountById";

// Endpoint used to read BG data.
(:background)
const DEXCOM_BG_DATA_ENDPOINT = "https://shareous1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues";

// https://forums.garmin.com/developer/connect-iq/f/discussion/324155/onbackgrounddata-not-called
// suggets :background with :background_app somehow works better. No official documentation on the
// issue..
(:background, :background_app)
class BgDataService extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    // override
    (:background_method)
    function onTemporalEvent() {
        System.println("-- BgDataService.onTemporalEvent");

        var work = Application.getApp().getProperty(PROP_WORK);

        // TODO: We could avoid 5 min delay if we knew how long a session id
        // will be valid for.

        if (work == null || work.equals(WORK_LOGIN)) {
            System.println("---- Getting session id");
            Communications.makeWebRequest(
                DEXCOM_LOGIN_ENDPOINT,
                {
                    "accountId" => DEX_ACCOUNT_ID,
                    "password" => DEX_PASSWORD,
                    "applicationId" => DEXCOM_APPLICATION_ID,
                },
                {
                    :method => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers => {
                        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                    },
                    // Note: this used to be
                    // `HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN` because even
                    // though the content type is `application/json`, the
                    // content was just a string (in double quotes), which
                    // Garmin SDK did not accept as a valid JSON. The SDK
                    // started accepting it at some point, but I'm not sure if
                    // that was intentional, as a string at the top level is
                    // not a JSON document, the top-level JSON should be an
                    // object. Leaving this note here in case it gets
                    // broken/fixed again later.
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                },
                method(:loginResponseCallback)
            );
        }

        // else if (work.equals(WORK_READ_BGS)) {
        else {
            System.println("---- Requesting BGs");
            var sessionId = Application.getApp().getProperty(PROP_SESSION_ID);
            Communications.makeWebRequest(
                DEXCOM_BG_DATA_ENDPOINT,
                {
                    "sessionId" => sessionId,
                    "minutes" => 1440,
                    "maxCount" => NUM_BGS,
                },
                {
                    :method => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers => {
                        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                },
                method(:bgResponseCallback)
            );
        }

        // else {
        //     System.println(Lang.format("Unexpected WORK: $1$", [work]));
        // }
    }

    (:background_method)
    function loginResponseCallback(responseCode as Lang.Number, data as Lang.String) as Void {
        // NB. All return paths in this function should call `Background.exit`.

        System.println("-- BgDataService.loginResponseCallback");
        var msg = Lang.format("Response code = $1$, data = $2$", [responseCode, data]);
        System.println(msg);

        if (responseCode != 200) {
            Background.exit({
                PROP_ERROR_MSG => msgLoginError(responseCode)
            });
            return;
        }

        var dataLen = data.length();

        // Drop double quotes, if they exist. connectiq and the device behave
        // differently: in connectiq we get data with double quotes, on device
        // we get data without double quotes.
        //
        // When requesting BG data with invalid session id we get this error
        // from the server: "UUID has to be represented by standard 36-char
        // representation". So UUID should be 36 characters without double
        // quotes, or 38 characters with double quotes.

        if (dataLen == 36) {
            // UUID without double quotes
            Background.exit({
                PROP_SESSION_ID => data
            });
        }

        else if (dataLen == 38) {
            // UUID with double quotes
            var sessionId = data.substring(1, data.length() - 1);
            Background.exit({
                PROP_SESSION_ID => sessionId
            });
        }

        else {
            Background.exit({
                PROP_ERROR_MSG => msgLoginError("(UUID)")
            });
        }
    }

    (:background_method)
    function bgResponseCallback(responseCode as Lang.Number, data as Lang.Dictionary) as Void {
        // NB. All return paths in this function should call `Background.exit`.

        System.println("-- BgDataService.bgResponseCallback");
        var msg = Lang.format("Response code = $1$, data = $2$", [responseCode, data]);
        System.println(msg);

        if (responseCode == 500) {
            // Session invalid. Login again.
            Background.exit({
                PROP_ERROR_MSG => "SESSION INVALID"
            });
            return;
        }

        if (responseCode != 200) {
            // Some other error. Display the error and try to login again.
            Background.exit({
                PROP_ERROR_MSG => msgOtherError(responseCode)
            });
            return;
        }

        // ST = system time (UTC+0?)
        // DT = display time
        // WT = ???

        var lenData = data.size();

        var bgs = new [NUM_BGS];

        // From newer to older. Elements look like this:
        //
        //      {
        //        Value => 123, (dunno if this is string or number)
        //        Trend => one of: "DoubleDown", "SingleDown", "FortyFiveDown", "Flat", "FortyFiveUp", "SingleUp", "DoubleUp",
        //        WT => a string like "Date(1656085432000)",
        //        DT => a string like "Date(1656085432000+0200)",
        //        ST => a string like "Date(1656085432000)"
        //      }
        //
        var lastBgReadTs = 0;
        for (var i = 0; i < NUM_BGS; i += 1) {
            if (i > lenData) {
                bgs[NUM_BGS - i - 1] = null;
                continue;
            }

            var reading = data[i];

            // Drop prefix and suffix: `Date(...)`
            var timeMillisStr = reading["ST"];
            var timeMillis = timeMillisStr.substring(5, timeMillisStr.length() - 1);
            var timeMillisLong = timeMillis.toLong();

            if (lastBgReadTs == 0) {
                lastBgReadTs = timeMillisLong;
            }

            bgs[NUM_BGS - i - 1] = {
                "bg" => reading["Value"],
                "ts" => timeMillisLong,
                "trend" => reading["Trend"],
            };

            // Debugging:
            // var now = new Time.Moment(timeMillisLong);
            // var utc = Time.Gregorian.utcInfo(now, Time.FORMAT_MEDIUM);
            // System.println(utc);
        }

        Background.exit({
            PROP_BGS => bgs
        });
    }
}


(:background)
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

(:background)
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
