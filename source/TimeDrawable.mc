using Toybox.Application;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

class TimeDrawable extends WatchUi.Drawable {
    private var m_weekResourceArray, m_monthResourceArray;

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
    }

    function draw(dc) {
        // System.println("-- TimeDrawable.draw");

        dc.clearClip();

        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        var hrStr = now.hour.format("%02d");
        var minStr = now.min.format("%02d");

        var screenWidth = dc.getWidth();
        var halfScreenWidth = screenWidth / 2;

        var hrWidth = dc.getTextWidthInPixels(hrStr, largeFont);
        var mnWidth = dc.getTextWidthInPixels(minStr, largeFont);
        var timeWidth = hrWidth + mnWidth;

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

        var dayOfWeekStr = WatchUi.loadResource(m_weekResourceArray[now.day_of_week - 1]).toUpper();
        var monthStr = WatchUi.loadResource(m_monthResourceArray[now.month - 1]).toUpper();
        var dayStr = now.day.toString();

        // var dateStr = Lang.format("$1$$2$", [now.day, monthStr]);

        // TODO: I don't understand why I need `-15` here, but
        // `largeFontHeight` seems to be larger than the text height
        var dateY = timeY + largeFontHeight - 15;
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

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Draw battery
        ////////////////////////////////////////////////////////////////////////////////////////////

        var batteryIconWidth = dc.getTextWidthInPixels("100%", smallFont);
        var batteryIconHeight = smallFontHeight - 4;
        var batteryTotalHeight = batteryIconHeight + (2 * smallFontHeight) - 4;

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

    function onPartialUpdate(dc) {
        // System.println("-- TimeDrawable.onPartialUpdate");

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Clear clip area
        ////////////////////////////////////////////////////////////////////////////////////////////

        // Clip area doesn't depend on dynamic parameters (size of rendered
        // "HHMM" etc.) to avoid glitches.
        var screenWidth = dc.getWidth();
        var screenHeight = screenWidth;
        var halfScreenWidth = screenWidth / 2;

        // Same as timeY
        var clipStartY = halfScreenWidth - (largeFontHeight / 2);
        var clipEndY = clipStartY + largeFontHeight;
        var clipHeight = clipEndY - clipStartY;

        var clipStartX = ((screenWidth - GRAPH_WIDTH) / 2) + GRAPH_WIDTH;
        var clipEndX = screenWidth;
        var clipWidth = clipEndX - clipStartX;

        dc.setClip(clipStartX, clipStartY, clipWidth, clipHeight);
        dc.clearClip();

        // Fill the clip, for debugging
        // dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        // dc.fillRectangle(clipStartX, clipStartY, clipWidth, clipHeight);

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Render second
        ////////////////////////////////////////////////////////////////////////////////////////////

        var sec = System.getClockTime().sec;
        var secStr = sec.format("%02d");
        var secStrWidth = dc.getTextWidthInPixels(secStr, smallFont);

        var rectangleStartX = clipStartX + 2;
        var rectangleWidth = 30;
        var rectangleStartY = clipStartY + ((largeFontHeight - smallFontHeight) - 4 - 15);
        var rectangleHeight = smallFontHeight + 4;

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_YELLOW);
        dc.fillRoundedRectangle(
            rectangleStartX,
            rectangleStartY,
            rectangleWidth,
            rectangleHeight,
            2
        );

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            rectangleStartX + ((rectangleWidth - secStrWidth) / 2),
            rectangleStartY + 2,
            smallFont,
            secStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }
}
