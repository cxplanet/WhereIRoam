//
//  StringUtils.swift
//  Where I Roam
//
//  Created by James Lorenzo on 7/22/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//

import Foundation

public class StringUtils {
    
    static var calInstance: NSCalendar {
        let calendar = NSCalendar.currentCalendar()
        return calendar
    }
    
    static func convertTimeIntervalToHoursMinutes (seconds:Double) -> String {
        let (h, m) = secondsToHoursMinutes (Int(seconds))
        var timeStr : String
        if(h > 0)
        {
            timeStr = "\(h)h \(m)m"
        } else {
            timeStr = "\(m)m"
        }
        return timeStr
    }
    
    static func secondsToHoursMinutes (seconds : Int) -> (Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60)
    }
    
//    static func calcTimeAndDateRange(arrival: NSDate, departure: NSDate) -> String
//    {
//        let calendar = NSCalendar.currentCalendar()
//        let comp = calendar.component(.Hour, fromDate: arrival)
//        let hour = comp.hour
//        let minute = comp.minute
//    
//    }
    
}

