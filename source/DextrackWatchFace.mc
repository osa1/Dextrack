using Toybox.Background;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

var largeFont;
var largeFontHeight;
var smallFont;
var smallFontHeight;
var timeDrawableHeight;

const FIVE_MINUTES = new Time.Duration(5 * 60);

class DextrackWatchFace extends WatchUi.WatchFace {
    private var timeDrawable;
    private var bgDataDrawable;
    private var inLowPowerMode = false;

    function initialize() {
        Sys.println("-- DextrackWatchFace.initialize");
        WatchFace.initialize();

        // Start temporal events.
        var lastTemporalEventTime = Background.getLastTemporalEventTime();
        if (lastTemporalEventTime != null) {
            // OK if this is in the past, event will be triggered immediately.
            var nextTime = lastTemporalEventTime.add(FIVE_MINUTES);
            Background.registerForTemporalEvent(nextTime);
        } else {
            var now = Time.now();
            Background.registerForTemporalEvent(now);
        }
    }

    // Load resources here.
    function onLayout(dc as Graphics.Dc) as Void {
        // Sys.println("-- DextrackWatchFace.onLayout");

        largeFont = WatchUi.loadResource(Rez.Fonts.LargeFont);
        smallFont = WatchUi.loadResource(Rez.Fonts.SmallFont);

        largeFontHeight = dc.getFontHeight(largeFont);
        smallFontHeight = dc.getFontHeight(smallFont);
        timeDrawableHeight = largeFontHeight + smallFontHeight;

        setLayout(Rez.Layouts.WatchFace(dc));

        timeDrawable = View.findDrawableById("Time");
        bgDataDrawable = View.findDrawableById("BgData");
    }

    // Called when this View is brought to the foreground. Restore the state of
    // this View and prepare it to be shown. This includes loading resources
    // into memory.
    function onShow() as Void {
        // Sys.println("-- DextrackWatchFace.onShow");
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        // Sys.println("-- DextrackWatchFace.onUpdate");

        // Get and show the current time
        // var clockTime = System.getClockTime();
        // var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
        // var view = View.findDrawableById("TimeLabel") as Text;
        // view.setText(timeString);

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        timeDrawable.onPartialUpdate(dc);
        bgDataDrawable.onPartialUpdate(dc);
    }

    function onPartialUpdate(dc as Dc) as Void {
        // Sys.println("-- DextractWatchFace.onPartialUpdate");
        if (inLowPowerMode) {
            timeDrawable.onPartialUpdate(dc);
            bgDataDrawable.onPartialUpdate(dc);
        }
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
}
