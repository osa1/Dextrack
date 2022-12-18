using Toybox.Application;

using Toybox.Background;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

const GRAPH_HEIGHT = 40;

// Store one hour of readings, one reading every 5 minutes.
const NUM_BGS = 12;

// X axis will have 125 minutes: last 120 minutes of readings, and 5 more
// minutes to slide the graph to the left while waiting for the next reading.
// To keep things simple a minute takes one pixel.
const GRAPH_WIDTH = 125;

function widthAtY(screenWidth, y) {
    var radius = screenWidth / 2;
    //var angle = 2 * Math.toDegrees(Math.acos(1 - (y.toFloat() / radius))); // Angle = 2 * arccos(1 - height(y) / radius)
    //return (2 * radius * Math.sin(Math.toRadians(angle) / 2)).toNumber();
    return (2 * radius * Math.sin(Math.toRadians(2 * Math.toDegrees(Math.acos(1 - (y.toFloat() / radius)))) / 2)).toNumber();
}


class BgDataDrawable extends WatchUi.Drawable {
    // Position of the next event time text. Partial update handler uses this
    // position to render the time until next event. Updated by `draw`.
    private var nextEventTimeTextWidth;
    private var nextEventTimeTextX;
    private var nextEventTimeTextY;

    function initialize(params) {
       // System.println("-- BgDataDrawable.initialize");

       Drawable.initialize(params);
    }

    function draw(dc) {
        var app = Application.getApp();

        var screenHeight = dc.getHeight();
        var screenWidth = dc.getWidth();

        var nowSecs = Time.now().value();

        var graphStart = (screenWidth - GRAPH_WIDTH) / 2;

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Draw graph lines
        ////////////////////////////////////////////////////////////////////////////////////////////

        // Upper line
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        var upperY = (screenHeight / 2) + (timeDrawableHeight / 2);
        dc.drawLine(graphStart, upperY, graphStart + GRAPH_WIDTH, upperY);

        // Lower line
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        var lowerY = upperY + GRAPH_HEIGHT;
        dc.drawLine(graphStart, lowerY, graphStart + GRAPH_WIDTH, lowerY);

        // Mid line
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
        dc.drawLine(graphStart, upperY + 20, graphStart + GRAPH_WIDTH, upperY + 20);

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Draw current BG, or error message
        ////////////////////////////////////////////////////////////////////////////////////////////

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var nextEventTimeSecs = app.getProperty(PROP_NEXT_EVENT_TIME_SECS);
        var nextEventTimeLeftSecs = nextEventTimeSecs - nowSecs;
        var nextEventTimeLeftMins = nextEventTimeLeftSecs / 60;

        var nextEventTimeText;
        if (nextEventTimeLeftSecs < 60) {
            nextEventTimeText = Lang.format("$1$s", [nextEventTimeLeftSecs]);
        } else {
            nextEventTimeText = Lang.format("$1$m", [nextEventTimeLeftSecs / 60]);
        }

        var errMsg = app.getProperty(PROP_ERROR_MSG);
        if (errMsg != null) {
            drawLine1_2(dc, errMsg);
            drawLine2_2_nextEventTime(dc, nextEventTimeText);
        }

        var bgs = app.getProperty(PROP_BGS);

        if (bgs == null || bgs.size() == 0) {
            // TODO: Not sure when exactly this can happen, log it to debug later
            if (errMsg == null) {
                System.println("Empty bgs, no error");
                var errText = "NO DATA";
                var textWidth = dc.getTextWidthInPixels(errText, smallFont);
                var textX = (screenWidth - textWidth) / 2;
                var textY = ((screenHeight - timeDrawableHeight - smallFontHeight) / 2) - 10;
                dc.drawText(textX, textY, smallFont, errText, Graphics.TEXT_JUSTIFY_LEFT);
            }
            return;
        }

        var lastReadUnixMillis = bgs[bgs.size() - 1]["ts"];
        var lastReadUnixSecs = lastReadUnixMillis / 1000;
        var diffSecs = nowSecs - lastReadUnixSecs;
        var diffMins = diffSecs / 60;

        if (errMsg == null) {
            // Show the current BG, but only if it's recent enough. Currently
            // we consider less than 10 minutes old as recent.
            if (diffSecs < 10 * 60) {
                var bgText = bgs[NUM_BGS - 1]["bg"].toString();
                var textWidth = dc.getTextWidthInPixels(bgText, largeFont);
                var textX = (screenWidth - textWidth) / 2;
                var textY = ((screenHeight - timeDrawableHeight - largeFontHeight) / 2) - 10;
                dc.drawText(textX, textY, largeFont, bgText, Graphics.TEXT_JUSTIFY_LEFT);

                // Show how long ago the shown bg was read
                if (diffMins != 0) {
                    var diffMinsText = Lang.format("-$1$m", [diffMins]);
                    var diffMinsTextWidth = dc.getTextWidthInPixels(diffMinsText, smallFont);
                    var diffMinsTextX = textX - diffMinsTextWidth - 10;
                    var diffMinsTextY = textY + largeFontHeight - smallFontHeight - 12 - smallFontHeight + 5;
                    dc.drawText(diffMinsTextX, diffMinsTextY, smallFont, diffMinsText, Graphics.TEXT_JUSTIFY_LEFT);
                }

                // Show time until next request
                nextEventTimeTextWidth = dc.getTextWidthInPixels(nextEventTimeText, smallFont);
                nextEventTimeTextX = textX - nextEventTimeTextWidth - 10;
                nextEventTimeTextY = textY + largeFontHeight - smallFontHeight - 12;
                dc.drawText(nextEventTimeTextX, nextEventTimeTextY, smallFont, nextEventTimeText, Graphics.TEXT_JUSTIFY_LEFT);

                // Show bg change rate
                var prevBg = bgs[NUM_BGS - 2];
                if (prevBg != null) {
                    var prevBg_ = prevBg["bg"];
                    var prevBgUnixMillis = prevBg["ts"];
                    var prevBgUnixSecs = prevBgUnixMillis / 1000;
                    var bgDiff = bgs[NUM_BGS - 1]["bg"] - prevBg_;
                    var dt = lastReadUnixSecs - prevBgUnixSecs;
                    var rate = (bgDiff.toDouble() * 60.0) / dt.toDouble();
                    // System.println(Lang.format("bgDiff = $1$, dt = $2$, rate = $3$", [bgDiff, dt, rate]));

                    var sign = "";
                    if (rate > 0) {
                        sign = "+";
                    }

                    var rateStr = rate.toString();
                    if (rate == 0.0) {
                        rateStr = "0";
                    } else if (rate < 0.0 && rateStr.length() > 4) {
                        rateStr = rateStr.substring(0, 4); // includes '-'
                    } else if (rate > 0.0 && rateStr.length() > 3) {
                        rateStr = rateStr.substring(0, 3);
                    }

                    var rateText = Lang.format("$1$$2$/m", [sign, rateStr]);
                    var rateTextX = textX + textWidth + 5;
                    var rateTextY = textY + largeFontHeight - smallFontHeight - 12;
                    dc.drawText(rateTextX, rateTextY, smallFont, rateText, Graphics.TEXT_JUSTIFY_LEFT);
                }
            } else {
                drawLine1_2(dc, "REQ. RECENT DATA");
                drawLine2_2_nextEventTime(dc, nextEventTimeText);
            }
        }

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Draw points
        ////////////////////////////////////////////////////////////////////////////////////////////

        if (bgs == null) {
            // System.println("bgs == null, returning");
            return;
        }

        // Separate the graph to NUM_BGS+1 areas. +1 to shift the graph to the
        // left until the next reading.
        //
        // This is divisible so no need for floating point arithmetic.
        var spaceBetweenDots = GRAPH_WIDTH / (NUM_BGS + 1);

        // Timestamp (in seconds) to the left end of the graph
        var graphLeftSecs = nowSecs - (60 * 60); // one hour

        var minuteWidth = GRAPH_WIDTH / 60;

        for (var dotIdx = 0; dotIdx < NUM_BGS; dotIdx += 1) {
            var bgData = bgs[dotIdx];

            if (bgData == null) {
                continue;
            }

            var bg = bgData["bg"];
            var bgTs = bgData["ts"];
            var bgTsSecs = bgTs / 1000;
            diffSecs = bgTsSecs - graphLeftSecs;
            diffMins = Math.round(diffSecs.toDouble() / 60.0).toLong();
            var dotX = graphStart + (diffMins * minuteWidth);

            // System.println(Lang.format(
            //     "bgTs = $1$, bgTsSecs = $2$, diffSecs = $3$, dotX = $4$",
            //     [bgTs, bgTsSecs, diffSecs, dotX]
            // ));

            if (dotX < graphStart) {
                continue;
            }

            if (bg < 80) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
                var dotY = lowerY;
                dc.fillPolygon([[dotX - 3, dotY], [dotX, dotY + 4], [dotX + 3, dotY]]);
            } else if (bg > 200) {
                dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_DK_BLUE);
                var dotY = upperY;
                dc.fillPolygon([[dotX - 3, dotY], [dotX, dotY - 4], [dotX + 3, dotY]]);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
                var dotY = (upperY + GRAPH_HEIGHT) - Math.round((GRAPH_HEIGHT.toDouble() / 120.0) * (bg - 80).toDouble()).toLong();
                dc.fillRectangle(dotX, dotY, 5, 5);
            }
        }
    }

    function drawLine1_2(dc, text) {
        var screenHeight = dc.getHeight();
        var screenWidth = dc.getWidth();

        var textWidth = dc.getTextWidthInPixels(text, smallFont);
        var textX = (screenWidth - textWidth) / 2;
        var textY = (((screenHeight - timeDrawableHeight) / 2) - smallFontHeight) - 10;
        dc.drawText(textX, textY, smallFont, text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawLine2_2_nextEventTime(dc, text) {
        var screenHeight = dc.getHeight();
        var screenWidth = dc.getWidth();

        nextEventTimeTextWidth = dc.getTextWidthInPixels(text, smallFont);
        nextEventTimeTextX = (screenWidth - nextEventTimeTextWidth) / 2;
        nextEventTimeTextY = ((screenHeight - timeDrawableHeight) / 2) - 10;
        dc.drawText(nextEventTimeTextX, nextEventTimeTextY, smallFont, text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function onPartialUpdate(dc) {
        // System.println("-- BgDataDrawable.onPartialUpdate");

        var app = Application.getApp();
        var nowSecs = Time.now().value();

        var nextEventTimeSecs = app.getProperty(PROP_NEXT_EVENT_TIME_SECS);
        var nextEventTimeLeftSecs = nextEventTimeSecs - nowSecs;

        if (nextEventTimeLeftSecs > 60) {
            return;
        }

        var nextEventTimeText = Lang.format("$1$s", [nextEventTimeLeftSecs]);
        var newNextEventTimeTextWidth = dc.getTextWidthInPixels(nextEventTimeText, smallFont);

        var clipStartX;
        var clipWidth;
        if (newNextEventTimeTextWidth > nextEventTimeTextWidth) {
            clipStartX = nextEventTimeTextX - newNextEventTimeTextWidth / 2;
            clipWidth = newNextEventTimeTextWidth;
        } else {
            clipStartX = nextEventTimeTextX - nextEventTimeTextWidth / 2;
            clipWidth = nextEventTimeTextWidth;
        }

        nextEventTimeTextWidth = newNextEventTimeTextWidth;

        var clipStartY = nextEventTimeTextY;
        var clipHeight = smallFontHeight;

        // System.println(Lang.format("  clipStartX = $1$, clipStartY = $2$, clipWidth = $3$, clipHeight = $4$", [clipStartX, clipStartY, clipWidth, clipHeight]));

        dc.setClip(clipStartX, clipStartY, clipWidth, clipHeight);
        dc.clearClip();

        dc.drawText(nextEventTimeTextX, nextEventTimeTextY, smallFont, nextEventTimeText, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
