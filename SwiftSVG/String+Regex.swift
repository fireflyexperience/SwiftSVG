//
//  String+Regex.swift
//  SwiftSVG
//
//  Created by Vojtech Vrbka on 19/09/2016.
//  Copyright © 2016 Strauss LLC. All rights reserved.
//

import Foundation

extension String
{
    func matchesForRegex(regex: String) -> [String]
    {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = self as NSString
            let results = regex.matchesInString(self,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func containsString(string: String) -> Bool
    {
        return self.rangeOfString(string) != nil
    }
}
