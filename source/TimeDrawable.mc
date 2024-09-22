using Toybox.Application;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

class TimeDrawable extends WatchUi.Drawable {
    private var m_weekResourceArray, m_monthResourceArray;
    private var hhmmWidth;

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
        dc.clear();

        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        var hrStr = now.hour.format("%02d");
        var minStr = now.min.format("%02d");

        var screenWidth = dc.getWidth();
        var halfScreenWidth = screenWidth / 2;

        var numFont = Graphics.getVectorFont({:face => "BionicBold", :size => 105});

        var hrWidth = dc.getTextWidthInPixels(hrStr, numFont);
        var mnWidth = dc.getTextWidthInPixels(minStr, numFont);
        var timeWidth = hrWidth + mnWidth;
        hhmmWidth = timeWidth;

        var timeX = halfScreenWidth - (timeWidth / 2);
        var timeY = halfScreenWidth - (dc.getFontHeight(numFont) / 2);

        // Draw hour
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(
            timeX,
            timeY,
            numFont,
            hrStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Draw minute
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(
            timeX + hrWidth,
            timeY,
            numFont,
            minStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        var dayOfWeekStr = WatchUi.loadResource(m_weekResourceArray[now.day_of_week - 1]).toUpper();
        var monthStr = WatchUi.loadResource(m_monthResourceArray[now.month - 1]).toUpper();
        var dayStr = now.day.toString();

        var dateStr = Lang.format("$1$ $2$ $3$", [now.day, monthStr, dayOfWeekStr]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRadialText(
            halfScreenWidth,
            halfScreenWidth,
            Graphics.getVectorFont({:face => "BionicBold", :size => 26}),
            dateStr,
            Graphics.TEXT_JUSTIFY_CENTER,
            180 + 30 + 60,
            halfScreenWidth,
            Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE
        );

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Draw battery
        ////////////////////////////////////////////////////////////////////////////////////////////

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

        // Draw battery percentage text
        var batteryLevelStr = Lang.format("BATT $1$%", [batteryLevel]);
        dc.setColor(batteryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawRadialText(
            halfScreenWidth,
            halfScreenWidth,
            Graphics.getVectorFont({:face => "BionicBold", :size => 26}),
            batteryLevelStr,
            Graphics.TEXT_JUSTIFY_CENTER,
            180 + 30,
            halfScreenWidth,
            Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE
        );
    }

    function onPartialUpdate(dc) {
        // System.println("-- TimeDrawable.onPartialUpdate");

/*
        ////////////////////////////////////////////////////////////////////////////////////////////
        // Clear clip area
        ////////////////////////////////////////////////////////////////////////////////////////////

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
*/
    }
}
