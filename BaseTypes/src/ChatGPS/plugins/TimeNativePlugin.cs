//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
//

using System.ComponentModel;

namespace Modulus.ChatGPS.Plugins;

[Description("Provides the current date and time from the computer running the ChatGPS proxy.")]
public sealed class TimeNativePlugin
{
    [Description("Get the current date.")]
    public string date()
    {
        return DateTimeOffset.Now.ToString("D");
    }

    [Description("Get today's date.")]
    public string today()
    {
        return date();
    }

    [Description("Get the current date and time in the local time zone.")]
    public string now()
    {
        return DateTimeOffset.Now.ToString("f");
    }

    [Description("Get the current UTC date and time.")]
    public string utcNow()
    {
        return DateTimeOffset.UtcNow.ToString("f");
    }

    [Description("Get the current time.")]
    public string time()
    {
        return DateTimeOffset.Now.ToString("hh:mm:ss tt");
    }

    [Description("Get the current year.")]
    public string year()
    {
        return DateTimeOffset.Now.ToString("yyyy");
    }

    [Description("Get the current month name.")]
    public string month()
    {
        return DateTimeOffset.Now.ToString("MMMM");
    }

    [Description("Get the current month number.")]
    public string monthNumber()
    {
        return DateTimeOffset.Now.ToString("MM");
    }

    [Description("Get the current day of the month.")]
    public string day()
    {
        return DateTimeOffset.Now.ToString("dd");
    }

    [Description("Get the date offset by a number of days from today.")]
    public string daysAgo(double input)
    {
        return DateTimeOffset.Now.AddDays(-input).ToString("D");
    }

    [Description("Get the date of the last day matching the supplied day of the week.")]
    public string dateMatchingLastDayName(DayOfWeek input)
    {
        var dateTime = DateTimeOffset.Now;

        for ( var index = 1; index <= 7; index++ )
        {
            dateTime = dateTime.AddDays(-1);

            if ( dateTime.DayOfWeek == input )
            {
                break;
            }
        }

        return dateTime.ToString("D");
    }

    [Description("Get the current day of the week.")]
    public string dayOfWeek()
    {
        return DateTimeOffset.Now.ToString("dddd");
    }

    [Description("Get the current clock hour.")]
    public string hour()
    {
        return DateTimeOffset.Now.ToString("h tt");
    }

    [Description("Get the current clock hour as a 24-hour number.")]
    public string hourNumber()
    {
        return DateTimeOffset.Now.ToString("HH");
    }

    [Description("Get the minutes on the current hour.")]
    public string minute()
    {
        return DateTimeOffset.Now.ToString("mm");
    }

    [Description("Get the seconds on the current minute.")]
    public string second()
    {
        return DateTimeOffset.Now.ToString("ss");
    }

    [Description("Get the local time zone offset from UTC.")]
    public string timeZoneOffset()
    {
        return DateTimeOffset.Now.ToString("%K");
    }

    [Description("Get the local time zone name.")]
    public string timeZoneName()
    {
        return TimeZoneInfo.Local.DisplayName;
    }
}
