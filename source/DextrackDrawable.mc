using Toybox.Application;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

const GRAPH_HEIGHT = 40;

// Store one hour of readings, one reading every 5 minutes.
const NUM_BGS = 12;

// X axis will have 125 minutes: last 120 minutes of readings, and 5 more
// minutes to slide the graph to the left while waiting for the next reading.
// To keep things simple a minute takes one pixel.
const GRAPH_WIDTH = 125;

class DextrackDrawable extends WatchUi.Drawable {
    private var m_weekResourceArray, m_monthResourceArray;
    private var hhmmWidth;

    private var largeFont;
    private var smallFont;

    // Position of the next event time text. Partial update handler uses this
    // position to render the time until next event. Updated by `draw`.
    private var nextEventTimeTextWidth;
    private var nextEventTimeTextX;
    private var nextEventTimeTextY;

    function initialize(params) {
        // System.println("-- TimeDrawable.initialize");

        Drawable.initialize(params);

        m_weekResourceArray = [
            Rez.Strings.Sun,
            Rez.Strings.Mon,
            Rez.Strings.Tue,
            Rez.Strings.Wed,
            Rez.Strings.Thu,
            Rez.Strings.Fri,
            Rez.Strings.Sat
        ];

        m_monthResourceArray = [
            Rez.Strings.Jan,
            Rez.Strings.Feb,
            Rez.Strings.Mar,
            Rez.Strings.Apr,
            Rez.Strings.May,
            Rez.Strings.Jun,
            Rez.Strings.Jul,
            Rez.Strings.Aug,
            Rez.Strings.Sep,
            Rez.Strings.Oct,
            Rez.Strings.Nov,
            Rez.Strings.Dec
        ];

        largeFont = WatchUi.loadResource(Rez.Fonts.LargeFont);
        smallFont = WatchUi.loadResource(Rez.Fonts.SmallFont);
    }

    function draw(dc) {
        // System.println("-- TimeDrawable.draw");

        dc.clearClip();
        dc.clear();

        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        var timeWidth = drawTime(dc, now);
        drawDate(dc, now);
        drawBattery(dc, timeWidth);
        drawBgStuff(dc);
    }

    function onPartialUpdate(dc) {
        // System.println("-- TimeDrawable.onPartialUpdate");

        partialUpdateTime(dc);
        partialUpdateBgStuff(dc);
    }

    function partialUpdateTime(dc) {

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Clear clip area
        ////////////////////////////////////////////////////////////////////////////////////////////

        var largeFontHeight = dc.getFontHeight(largeFont);
        var smallFontHeight = dc.getFontHeight(smallFont);

        var screenWidth = dc.getWidth();
        var screenHeight = screenWidth;
        var halfScreenWidth = screenWidth / 2;
        var halfScreenHeight = screenHeight / 2;

        var clipStartY = halfScreenHeight + (largeFontHeight / 2) - smallFontHeight - 13;
        var clipHeight = smallFontHeight;

        var clipStartX = halfScreenWidth + (hhmmWidth / 2);
        var clipWidth = 20; // enough for "ss" in small font

        dc.setClip(clipStartX, clipStartY, clipWidth, clipHeight);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Fill the clip, for debugging
        // dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        // dc.fillRectangle(clipStartX, clipStartY, clipWidth, clipHeight);

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Render second
        ////////////////////////////////////////////////////////////////////////////////////////////

        var sec = System.getClockTime().sec;
        var secStr = sec.format("%02d");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(clipStartX, clipStartY, smallFont, secStr, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function partialUpdateBgStuff(dc) {
        var nowSecs = Time.now().value();

        var nextTemporalEventTime = Background.getTemporalEventRegisteredTime();
        if (nextTemporalEventTime == null) {
            return;
        }

        var nextEventTimeSecs = nextTemporalEventTime.value();
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

        var smallFontHeight = dc.getFontHeight(smallFont);
        var clipStartY = nextEventTimeTextY;
        var clipHeight = smallFontHeight;

        // System.println(Lang.format("  clipStartX = $1$, clipStartY = $2$, clipWidth = $3$, clipHeight = $4$", [clipStartX, clipStartY, clipWidth, clipHeight]));

        dc.setClip(clipStartX, clipStartY, clipWidth, clipHeight);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(nextEventTimeTextX, nextEventTimeTextY, smallFont, nextEventTimeText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawTime(dc, now) {
        var largeFontHeight = dc.getFontHeight(largeFont);

        var hrStr = now.hour.format("%02d");
        var minStr = now.min.format("%02d");

        var screenWidth = dc.getWidth();
        var halfScreenWidth = screenWidth / 2;

        var hrWidth = dc.getTextWidthInPixels(hrStr, largeFont);
        var mnWidth = dc.getTextWidthInPixels(minStr, largeFont);
        var timeWidth = hrWidth + mnWidth;
        hhmmWidth = timeWidth;

        var timeX = halfScreenWidth - (timeWidth / 2);
        var timeY = halfScreenWidth - (largeFontHeight / 2);

        // Draw hour
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(
            timeX,
            timeY,
            largeFont,
            hrStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Draw minute
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(
            timeX + hrWidth,
            timeY,
            largeFont,
            minStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        return timeWidth;
    }

    function drawDate(dc, now) {
        var screenWidth = dc.getWidth();
        var halfScreenWidth = screenWidth / 2;

        var dayOfWeekStr = WatchUi.loadResource(m_weekResourceArray[now.day_of_week - 1]).toUpper();
        var monthStr = WatchUi.loadResource(m_monthResourceArray[now.month - 1]).toUpper();
        var dayStr = now.day.toString();

        // var dateStr = Lang.format("$1$$2$", [now.day, monthStr]);

        // TODO: I don't understand why I need `-15` here, but
        // `largeFontHeight` seems to be larger than the text height
        var largeFontHeight = dc.getFontHeight(largeFont);
        var dateY = halfScreenWidth + (largeFontHeight / 2) - 15;
        var dayWidth = dc.getTextWidthInPixels(dayStr, smallFont);
        var monthWidth = dc.getTextWidthInPixels(monthStr, smallFont);
        var dayOfWeekWidth = dc.getTextWidthInPixels(dayOfWeekStr, smallFont);
        var totalDateTextWidth = dayWidth + monthWidth + dayOfWeekWidth;

        // 3 words, 4 spaces
        var spaceWidth = (GRAPH_WIDTH - totalDateTextWidth) / 4;
        var totalDateWidth = totalDateTextWidth;
        if (spaceWidth > 0) {
            totalDateWidth += spaceWidth * 4;
        }

        // graphStart
        var dateX = (screenWidth - GRAPH_WIDTH) / 2;

        // Draw day
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        dc.drawText(
            dateX +  spaceWidth,
            dateY,
            smallFont,
            dayStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Draw month
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        dc.drawText(
            dateX + dayWidth + (2 * spaceWidth),
            dateY,
            smallFont,
            monthStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Draw background for day of week
        // dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
        // dc.fillRoundedRectangle(
        //     dateX + dc.getTextWidthInPixels(dateStr, m_dayOfWeekFont),
        //     dateY,
        //     dc.getTextWidthInPixels(dayOfWeekStr, m_dayOfWeekFont) + 6,
        //     smallFontHeight,
        //     2
        // );

        // Draw day of week
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dateX + dayWidth + monthWidth + (3 * spaceWidth),
            dateY,
            smallFont,
            dayOfWeekStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

    function drawBattery(dc, timeWidth) {
        var smallFontHeight = dc.getFontHeight(smallFont);

        var screenWidth = dc.getWidth();
        var halfScreenWidth = screenWidth / 2;

        var batteryIconWidth = dc.getTextWidthInPixels("100%", smallFont);
        var batteryIconHeight = smallFontHeight - 4;

        var batteryLevelFloat = System.getSystemStats().battery;
        var batteryLevel = Math.floor(batteryLevelFloat).toLong();

        // Center the battery icon in the space right of HHMM
        var batteryIconMaxWidth = halfScreenWidth - (timeWidth / 2);

        // Battery on right:
        // var batteryX = halfScreenWidth + (timeWidth / 2) + ((batteryIconMaxWidth - batteryIconWidth) / 2);

        // Battery on left:
        var batteryX = (batteryIconMaxWidth - batteryIconWidth) / 2;

        var batteryY = halfScreenWidth - 10;

        var batteryColor;
        if (batteryLevel <= 25) {
            batteryColor = Graphics.COLOR_RED;
        } else if (batteryLevel <= 50) {
            batteryColor = Graphics.COLOR_YELLOW;
        } else {
            batteryColor = Graphics.COLOR_DK_GREEN;
        }

        // Draw battery frame body
        dc.setColor(batteryColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        dc.drawRoundedRectangle(
            batteryX,
            batteryY,
            batteryIconWidth - 5,
            batteryIconHeight,
            2
        );

        // Draw battery head
        dc.fillRoundedRectangle(
            batteryX + batteryIconWidth - 4,
            batteryY + 5,
            3,
            batteryIconHeight - 10,
            2
        );

        var batteryTotalFillWidth = batteryIconWidth - 12;
        var batteryFillWidth = (batteryTotalFillWidth.toDouble() * batteryLevelFloat) / 100.0;

        // Draw filler
        dc.fillRectangle(
            batteryX + 3,
            batteryY + 3,
            batteryFillWidth,
            batteryIconHeight - 7
        );

        // Draw battery percentage text
        var batteryLevelStr = Lang.format("$1$%", [batteryLevel]);
        var batteryLevelStrWidth = dc.getTextWidthInPixels(batteryLevelStr, smallFont);
        dc.setColor(batteryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            batteryX + ((batteryIconWidth - batteryLevelStrWidth) / 2),
            batteryY + smallFontHeight - 4,
            smallFont,
            batteryLevelStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

    function drawBgStuff(dc) {
        var app = Application.getApp();

        var screenHeight = dc.getHeight();
        var screenWidth = dc.getWidth();

        var bgs = app.getProperty(PROP_BGS) as Lang.Array<Lang.Number>;
        var nowSecs = Time.now().value();

        drawGraph(dc, bgs, nowSecs);

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Draw current BG, or error message
        ////////////////////////////////////////////////////////////////////////////////////////////

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var nextEventTimeText;
        var nextTemporalEventTime = Background.getTemporalEventRegisteredTime();
        if (nextTemporalEventTime == null) {
            nextEventTimeText = "NA";
        } else {
            var nextEventTimeSecs = nextTemporalEventTime.value();
            var nextEventTimeLeftSecs = nextEventTimeSecs - nowSecs;

            if (nextEventTimeLeftSecs < 60) {
                nextEventTimeText = Lang.format("$1$s", [nextEventTimeLeftSecs]);
            } else {
                nextEventTimeText = Lang.format("$1$m", [nextEventTimeLeftSecs / 60]);
            }
        }

        var largeFontHeight = dc.getFontHeight(largeFont);
        var smallFontHeight = dc.getFontHeight(smallFont);
        var timeDrawableHeight = largeFontHeight + smallFontHeight;

        var errMsg = app.getProperty(PROP_ERROR_MSG);
        if (errMsg != null) {
            drawLine1_2(dc, errMsg, timeDrawableHeight);
            drawLine2_2_nextEventTime(dc, nextEventTimeText, timeDrawableHeight);
        }

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
                drawLine1_2(dc, "REQ. RECENT DATA", timeDrawableHeight);
                drawLine2_2_nextEventTime(dc, nextEventTimeText, timeDrawableHeight);
            }
        }
    }

    function drawLine1_2(dc, text, timeDrawableHeight) {
        var screenHeight = dc.getHeight();
        var screenWidth = dc.getWidth();

        var smallFontHeight = dc.getFontHeight(smallFont);

        var textWidth = dc.getTextWidthInPixels(text, smallFont);
        var textX = (screenWidth - textWidth) / 2;
        var textY = (((screenHeight - timeDrawableHeight) / 2) - smallFontHeight) - 10;
        dc.drawText(textX, textY, smallFont, text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawLine2_2_nextEventTime(dc, text, timeDrawableHeight) {
        var screenHeight = dc.getHeight();
        var screenWidth = dc.getWidth();

        nextEventTimeTextWidth = dc.getTextWidthInPixels(text, smallFont);
        nextEventTimeTextX = (screenWidth - nextEventTimeTextWidth) / 2;
        nextEventTimeTextY = ((screenHeight - timeDrawableHeight) / 2) - 10;
        dc.drawText(nextEventTimeTextX, nextEventTimeTextY, smallFont, text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawGraph(dc, bgs, nowSecs) {
        var screenHeight = dc.getHeight();
        var screenWidth = dc.getWidth();
        var graphStart = (screenWidth - GRAPH_WIDTH) / 2;

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Draw graph lines
        ////////////////////////////////////////////////////////////////////////////////////////////

        var largeFontHeight = dc.getFontHeight(largeFont);
        var smallFontHeight = dc.getFontHeight(smallFont);
        var timeDrawableHeight = largeFontHeight + smallFontHeight;

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
        // Draw points
        ////////////////////////////////////////////////////////////////////////////////////////////

        if (bgs == null) {
            // System.println("bgs == null, returning");
            return;
        }

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
            var diffSecs = bgTsSecs - graphLeftSecs;
            var diffMins = Math.round(diffSecs.toDouble() / 60.0).toLong();
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
}
