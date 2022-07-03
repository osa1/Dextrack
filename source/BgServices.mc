// Implements temporal event handling (background services)

using Toybox.Application;
using Toybox.System;

(:background)
class BgDataService extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    // override
    (:background_method)
    function onTemporalEvent() {
        System.println("-- BgDataService.onTemporalEvent");

        var work = Application.getApp().getValue(STORAGE_WORK);

        // TODO: We could avoid 5 min delay if we know how long a session id
        // will be valid for

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
                    // This endpoint returns Content-Type "application/json",
                    // but the body is just a string (in double quotes), which
                    // according to 4627 is not valid JSON (it must be an
                    // object or array), and Garmin SDK doesn't accept it.
                    //
                    // However it accepts the response with
                    // HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN even though the
                    // documentation says "content-type must be text/plain", so
                    // we use that.
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
                },
                method(:loginResponseCallback)
            );
        }

        // else if (work.equals(WORK_READ_BGS)) {
        else {
            System.println("---- Requesting BGs");
            var sessionId = Application.getApp().getValue(STORAGE_SESSION_ID);
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
    function loginResponseCallback(responseCode, data) {
        // NB. All return paths in this function should call `Background.exit`
        // and return `STORAGE_LAST_RESPONSE_TIME_SECS` as background data so that
        // we will call `onBackgroundData` and schedule a new temporal event.
        var now = Time.now();

        System.println("-- BgDataService.loginResponseCallback");
        var msg = Lang.format("Response code = $1$, data = $2$", [responseCode, data]);
        System.println(msg);

        if (responseCode != 200) {
            Background.exit({
                STORAGE_ERROR_MSG => msgLoginError(responseCode),
                STORAGE_LAST_RESPONSE_TIME_SECS => now.value()
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
                STORAGE_SESSION_ID => data,
                STORAGE_LAST_RESPONSE_TIME_SECS => now.value()
            });
        }

        else if (dataLen == 38) {
            // UUID with double quotes
            var sessionId = data.substring(1, data.length() - 1);
            Background.exit({
                STORAGE_SESSION_ID => sessionId,
                STORAGE_LAST_RESPONSE_TIME_SECS => now.value()
            });
        }

        else {
            Background.exit({
                STORAGE_ERROR_MSG => msgLoginError("(UUID)"),
                STORAGE_LAST_RESPONSE_TIME_SECS => now.value()
            });
        }
    }

    (:background_method)
    function bgResponseCallback(responseCode, data) {
        // NB. All return paths in this function should call `Background.exit`
        // and return `STORAGE_LAST_RESPONSE_TIME_SECS` as background data so that
        // we will call `onBackgroundData` and schedule a new temporal event.
        var now = Time.now();

        System.println("-- BgDataService.bgResponseCallback");
        var msg = Lang.format("Response code = $1$, data = $2$", [responseCode, data]);
        System.println(msg);

        if (responseCode == 500) {
            // Session invalid. Login again.
            Background.exit({
                STORAGE_ERROR_MSG => MSG_INVALID_SESSION,
                STORAGE_LAST_RESPONSE_TIME_SECS => now.value()
            });
            return;
        }

        if (responseCode != 200) {
            // Some other error. Display the error and try to login again.
            Background.exit({
                STORAGE_ERROR_MSG => msgOtherError(responseCode),
                STORAGE_LAST_RESPONSE_TIME_SECS => now.value()
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
            STORAGE_BGS => bgs,
            STORAGE_LAST_RESPONSE_TIME_SECS => now.value()
        });
    }
}
