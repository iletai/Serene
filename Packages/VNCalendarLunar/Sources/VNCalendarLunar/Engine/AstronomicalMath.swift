import Foundation

public enum AstronomicalMath {
    public static let vietnamTimeZoneOffset: Double = 7.0 // UTC+7 (105°E)
    private static let rad = Double.pi / 180.0

    /// Chuyển đổi Ngày Dương sang Số ngày Julian (Julian Day Number)
    public static func julianDay(from date: SolarDate) -> Int {
        let a = (14 - date.month) / 12
        let y = date.year + 4800 - a
        let m = date.month + 12 * a - 3

        var jd = date.day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        if jd < 2_299_161 {
            jd = date.day + (153 * m + 2) / 5 + 365 * y + y / 4 - 32083
        }
        return jd
    }

    /// Chuyển đổi Số ngày Julian về Ngày Dương Lịch
    public static func solarDate(from jd: Int) -> SolarDate {
        if jd > 2_299_160 {
            let a = jd + 32044
            let b = (4 * a + 3) / 146097
            let c = a - (146097 * b) / 4
            let d = (4 * c + 3) / 1461
            let e = c - (1461 * d) / 4
            let m = (5 * e + 2) / 153
            let day = e - (153 * m + 2) / 5 + 1
            let month = m + 3 - 12 * (m / 10)
            let year = 100 * b + d - 4800 + (m / 10)
            return SolarDate(day: day, month: month, year: year)
        } else {
            let c = jd + 32082
            let d = (4 * c + 3) / 1461
            let e = c - (1461 * d) / 4
            let m = (5 * e + 2) / 153
            let day = e - (153 * m + 2) / 5 + 1
            let month = m + 3 - 12 * (m / 10)
            let year = d - 4800 + (m / 10)
            return SolarDate(day: day, month: month, year: year)
        }
    }

    /// Tính số ngày Julian của Điểm Sóc (New Moon) thứ k
    public static func newMoonJulianDay(k: Int, timeZoneOffset: Double = vietnamTimeZoneOffset) -> Int {
        let t = Double(k) / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let dr = rad

        var jd1 = 2415020.75933 + 29.53058868 * Double(k) + 0.0001178 * t2 - 0.000000155 * t3
        jd1 += 0.00033 * sin((166.56 + 132.87 * t - 0.009173 * t2) * dr)

        let m = (359.2242 + 29.10535608 * Double(k) - 0.0000333 * t2 - 0.00000347 * t3) * dr
        let mPrime = (306.0253 + 385.81691806 * Double(k) + 0.0107306 * t2 + 0.00001236 * t3) * dr
        let f = (21.2964 + 390.67050646 * Double(k) - 0.0016528 * t2 - 0.00000239 * t3) * dr

        var c1 = (0.1734 - 0.000393 * t) * sin(m) + 0.0021 * sin(2.0 * m)
        c1 -= 0.4068 * sin(mPrime) + 0.0161 * sin(2.0 * mPrime)
        c1 -= 0.0004 * sin(3.0 * mPrime)
        c1 += 0.0104 * sin(2.0 * f) - 0.0051 * sin(m + mPrime)
        c1 -= 0.0074 * sin(m - mPrime) + 0.0004 * sin(2.0 * f + m)
        c1 -= 0.0004 * sin(2.0 * f - m) - 0.0006 * sin(2.0 * f + mPrime)
        c1 += 0.0010 * sin(2.0 * f - mPrime) + 0.0005 * sin(m + 2.0 * mPrime)

        var deltat: Double = 0.0
        if t < -11 {
            deltat = 0.001 + 0.000839 * t + 0.0002261 * t2 - 0.00000845 * t3 - 0.00000061 * t * t3
        } else {
            deltat = -0.000078 + 0.0000004 * Double(k)
        }

        let jdNew = jd1 + c1 - deltat
        return Int(floor(jdNew + 0.5 + timeZoneOffset / 24.0))
    }

    /// Tính Kinh độ biểu kiến Mặt Trời (Solar Longitude in degrees [0, 360))
    public static func sunLongitude(at jd: Int, timeZoneOffset: Double = vietnamTimeZoneOffset) -> Double {
        let t = (Double(jd) - 0.5 - timeZoneOffset / 24.0 - 2451545.0) / 36525.0
        let t2 = t * t
        let dr = rad

        var l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2
        l0 = l0.truncatingRemainder(dividingBy: 360.0)
        if l0 < 0 { l0 += 360.0 }

        var m = 357.52910 + 35999.05029 * t - 0.0001537 * t2
        m = m.truncatingRemainder(dividingBy: 360.0)
        if m < 0 { m += 360.0 }
        let mRad = m * dr

        var c = (1.914600 - 0.004817 * t - 0.000014 * t2) * sin(mRad)
        c += (0.019993 - 0.000101 * t) * sin(2.0 * mRad) + 0.000290 * sin(3.0 * mRad)

        var theta = l0 + c
        theta = theta.truncatingRemainder(dividingBy: 360.0)
        if theta < 0 { theta += 360.0 }
        return theta
    }

    /// Lấy chỉ số Trung khí (0 - 11)
    @inlinable
    public static func majorSolarTerm(at jd: Int, timeZoneOffset: Double = vietnamTimeZoneOffset) -> Int {
        let longitude = sunLongitude(at: jd, timeZoneOffset: timeZoneOffset)
        return Int(floor(longitude / 30.0))
    }

    /// Lấy Tiết khí hiện tại (0 - 23)
    public static func solarTerm(at jd: Int, timeZoneOffset: Double = vietnamTimeZoneOffset) -> SolarTerm {
        let longitude = sunLongitude(at: jd, timeZoneOffset: timeZoneOffset)
        let index = Int(floor(longitude / 15.0)) % 24
        return SolarTerm(rawValue: index) ?? .xuanPhan
    }
}
