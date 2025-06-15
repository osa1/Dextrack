using Toybox.Background;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.System;
using Toybox.Time.Gregorian;
using Toybox.Time;
using Toybox.WatchUi;
using Toybox.Test;

const FIVE_MINUTES = new Time.Duration(5 * 60);

class DextrackWatchFace extends WatchUi.WatchFace {
    private var dextrackDrawable;
    private var inLowPowerMode = false;

    function initialize() {
        Sys.println("-- DextrackWatchFace.initialize");
        WatchFace.initialize();

        dextrackDrawable = View.findDrawableById("Dextrack");

        maybeStartTemporalEvent();
    }

    // Load resources here.
    function onLayout(dc as Graphics.Dc) as Void {
        // Sys.println("-- DextrackWatchFace.onLayout");

        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore the state of
    // this View and prepare it to be shown. This includes loading resources
    // into memory.
    function onShow() as Void {
        // Sys.println("-- DextrackWatchFace.onShow");

        maybeStartTemporalEvent();
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        // Sys.println("-- DextrackWatchFace.onUpdate");

        // Call the parent onUpdate function to redraw the layout.
        View.onUpdate(dc);

        // At least in the sim, `initialize`, `onUpdate`, and `draw` methods
        // seem to be racing or running concurrently, so we don't assume that
        // `initialize` has been run to completion here.
        if (dextrackDrawable != null) {
            dextrackDrawable.onPartialUpdate(dc);
        }

        maybeStartTemporalEvent();
    }

    function onPartialUpdate(dc as Graphics.Dc) as Void {
        // Sys.println("-- DextractWatchFace.onPartialUpdate");
        if (inLowPowerMode) {
            // See comments in `onUpdate` on these null checks.
            if (dextrackDrawable != null) {
                dextrackDrawable.onPartialUpdate(dc);
            }
        }

        maybeStartTemporalEvent();
    }

    // Called when this View is removed from the screen. Save the state of this
    // View here. This includes freeing resources from memory.
    function onHide() as Void {
        // Sys.println("-- DextrackWatchFace.onHide");
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        // Sys.println("-- DextrackWatchFace.onEnterSleep");
        inLowPowerMode = true;
    }

    // The user has just looked at their watch. Timers and animations may be
    // started here.
    function onExitSleep() as Void {
        // Sys.println("-- DextrackWatchFace.onExitSleep");
        inLowPowerMode = false;
    }

    function maybeStartTemporalEvent() {
        Sys.println("-- DextrackWatchFace.maybeStartTemporalEvent");

        // nextTemporalEventTime: Moment or Duration.
        var nextTemporalEventTime = Background.getTemporalEventRegisteredTime();

        // We always register with a Moment, but I've seen other types here. So
        // test the type.
        if (nextTemporalEventTime instanceof Time.Moment) {
            var nextTemporalEventUtc = Gregorian.utcInfo(nextTemporalEventTime, Time.FORMAT_SHORT);
            if (nextTemporalEventTime != null) {
                Sys.println(
                        Lang.format(
                            "---- DextrackWatchFace.maybeStartTemporalEvent: using existing event at $1$:$2$:$3$",
                            [nextTemporalEventUtc.hour, nextTemporalEventUtc.min, nextTemporalEventUtc.sec]));

                var now = Time.now();
                var nowUtc = Gregorian.utcInfo(now, Time.FORMAT_SHORT);
                Sys.println(
                        Lang.format(
                            "---- DextrackWatchFace.maybeStartTemporalEvent: current time $1$:$2$:$3$",
                            [nowUtc.hour, nowUtc.min, nowUtc.sec]));
                return;
            }
        }

        startTemporalEvent();
    }

    function startTemporalEvent() {
        Sys.println("-- DextrackWatchFace.startTemporalEvent");

        // lastTemporalEventTime: Moment or null
        var lastTemporalEventTime = Background.getLastTemporalEventTime();

        // now: Moment
        var now = Time.now();

        if (lastTemporalEventTime == null) {
            Sys.println(
                    "-- DextrackWatchFace.startTemporalEvent: last temporal event is null, registering new now");
            Background.registerForTemporalEvent(now);
            return;
        }

        var lastTemporalEventUtc = Gregorian.utcInfo(lastTemporalEventTime, Time.FORMAT_SHORT);
        Sys.println(
                Lang.format(
                    "-- DextrackWatchFace.startTemporalEvent: last temporal event at $1$:$2$:$3$",
                    [lastTemporalEventUtc.hour, lastTemporalEventUtc.min, lastTemporalEventUtc.sec]));

        // nextMoment: Moment
        var nextMoment = lastTemporalEventTime.add(FIVE_MINUTES);
        var nextMomentUtc = Gregorian.utcInfo(now, Time.FORMAT_SHORT);
        Sys.println(
                Lang.format(
                    "-- DextrackWatchFace.startTemporalEvent: registering temporal event at $1$:$2$:$3$",
                    [nextMomentUtc.hour, nextMomentUtc.min, nextMomentUtc.sec]));

        Background.registerForTemporalEvent(nextMoment);
    }
}
