using Toybox.Application;
using Toybox.Background;
using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.Time;
using Toybox.WatchUi;

(:background)
class DextrackApp extends Application.AppBase {
    // override
    function initialize() {
        // Sys.println("-- DextrackApp.initialize");
        AppBase.initialize();

        var work = getProperty(PROP_WORK);
        if (work == null) {
            setProperty(PROP_WORK, WORK_LOGIN);
            setProperty(PROP_ERROR_MSG, MSG_LOGGING_IN);
        }
    }

    // onStart() is called on application start up
    // override
    function onStart(state as Lang.Dictionary?) as Void {
        // Sys.println("-- DextrackApp.onStart");
    }

    // onStop() is called when your application is exiting
    // override
    function onStop(state as Lang.Dictionary?) as Void {
        // Sys.println("-- DextrackApp.onStop");
    }

    // override
    function getInitialView() as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>? {
        // Sys.println("-- DextrackApp.getInitialView");
        return [new DextrackWatchFace()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
    }

    // override
    function getServiceDelegate() {
        // Sys.println("-- DextrackApp.getServiceDelegate");
        return [new BgDataService()] as Lang.Array<Sys.ServiceDelegate>;
    }

    // Handle data passed from a ServiceDelegate to the application.
    //
    // When the Background process terminates, a data payload may be available.
    // If the main application is active when this occurs, the data will be
    // passed directly to the application's onBackgroundData() method. If the
    // main application is not active, the data will be saved until the next
    // time the application is launched and will be passed to the application
    // after the onStart() method completes.
    //
    // override
    (:background_method)
    function onBackgroundData(data) {
        Sys.println(Lang.format("-- DextrackApp.onBackgroundData data=$1$", [data]));

        // TODO: This can be simplified as:
        //
        // - SESSION_ID available => read bg data
        // - otherwise => login

        if (data[PROP_ERROR_MSG] != null) {
            setProperty(PROP_ERROR_MSG, data[PROP_ERROR_MSG]);
            setProperty(PROP_SESSION_ID, null);
            setProperty(PROP_WORK, WORK_LOGIN);
        }

        else if (data[PROP_SESSION_ID] != null) {
            setProperty(PROP_ERROR_MSG, MSG_REQUESTING_BG);
            setProperty(PROP_SESSION_ID, data[PROP_SESSION_ID]);
            setProperty(PROP_WORK, WORK_READ_BGS);
        }

        else if (data[PROP_BGS] != null) {
            setProperty(PROP_ERROR_MSG, null);
            setProperty(PROP_BGS, data[PROP_BGS]);
        }

        setProperty(PROP_LAST_RESPONSE_TIME_SECS, data[PROP_LAST_RESPONSE_TIME_SECS]);

        // Schedule the next temporal event. If the last bg data (N) was read
        // more than 2 minutes ago, then we wait `10 - N` minutes to request bg
        // data again to make read more recent data starting from the next
        // read.
        //
        // (Reminder: Garmin allows min 5 minutes between temporal events)
        //
        // For example, if the last read was 3 minutes ago, because Dexcom
        // uploads bg data in every 5 minutes, next request will also get 3
        // minute old data. If we wait 7 minutes (+ 10 seconds to give Dexcom
        // time to upload) instead, we will read a recent data (less than 10
        // seconds old), and next reads will keep reading recent data.
        //
        // Another optimization here is that if the last bg is too recent, i.e.
        // less than 10 seconds old, then we wait a few seconds extra before
        // the next read to give Dexcom enough time to upload the next reading.
        //
        // TODO: This assumes that the Dexcom device (e.g. phone) and the watch
        // are on same time zone.

        var now = Time.now();

        if (data[PROP_BGS] == null) {

            // Not reading BG data yet, schedule as soon as possible
            var lastTemporalEventTime = Background.getLastTemporalEventTime();
            var nextEventTime = lastTemporalEventTime.add(FIVE_MINUTES);
            setProperty(PROP_NEXT_EVENT_TIME_SECS, nextEventTime.value());
            Background.registerForTemporalEvent(nextEventTime);

        } else {

            var lastBgData = data[PROP_BGS][NUM_BGS - 1];
            var lastBgDataUnixMillis = lastBgData["ts"];
            var lastBgDataUnixSecs = lastBgDataUnixMillis / 1000;
            var nowUnixSecs = now.value();

            if (lastBgDataUnixSecs > nowUnixSecs) {
                // Strange case, debug
                System.println("BG data from future: nowUnixSecs=$1$, lastBgDataUnixSecs=$2$", [nowUnixSecs, lastBgDataUnixSecs]);
                var nextEventTime = now.add(FIVE_MINUTES);
                setProperty(PROP_NEXT_EVENT_TIME_SECS, nextEventTime.value());
                Background.registerForTemporalEvent(nextEventTime);
                return;
            }

            var diffSecs = (nowUnixSecs - lastBgDataUnixSecs) % 300;

            var nextEventTime;
            if (diffSecs < 15) {
                // Give Dexcom some time to upload the next reading before
                // requesting again
                nextEventTime = now.add(FIVE_MINUTES).add(new Time.Duration(15 - diffSecs));
            } else if (diffSecs >= 120) {
                // Data more than a minute old. Wait 5-N minutes plus a few
                // seconds to catch recent readings again.
                nextEventTime = now.add(FIVE_MINUTES).add(new Time.Duration(300 - diffSecs + 15));
            } else {
                nextEventTime = now.add(FIVE_MINUTES);
            }

            System.println(Lang.format("diff=$1$s nextEvent=$2$s", [diffSecs, nextEventTime.value() - nowUnixSecs]));

            setProperty(PROP_NEXT_EVENT_TIME_SECS, nextEventTime.value());
            Background.registerForTemporalEvent(nextEventTime);
        }
    }
}
