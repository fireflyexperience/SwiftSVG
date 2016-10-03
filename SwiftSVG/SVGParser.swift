//
//  SVGParser.swift
//  SwiftSVG
//
//  Copyright (c) 2015 Michael Choe
//  http://www.straussmade.com/
//  http://www.twitter.com/_mchoe
//  http://www.github.com/mchoe
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#if os(iOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

private var tagMapping: [String: String] = [
    "path": "SVGPath",
    "svg": "SVGElement"
]

@objc(SVGGroup) private class SVGGroup: NSObject { }

@objc(SVGPath) open class SVGPath: NSObject {
    
    var path: UIBezierPath = UIBezierPath()
    var shapeLayer: CAShapeLayer = CAShapeLayer()
    var translate: CGPoint?
    
    var d: String? {
        didSet {
            updateShapeLayer()
        }
    }
    
    var fill: String? {
        didSet {
            if let hexFill = fill {
                self.shapeLayer.fillColor = UIColor(hexString: hexFill).cgColor
            }
        }
    }
    
    var transform: String? {
        didSet {
            guard let transform = transform , transform.containsString("translate") else { return }
            let coordinates = transform.matchesForRegex("[0-9]")
            if coordinates.count > 1 {
                if let
                    x = Double(coordinates[0]),
                    let y = Double(coordinates[1])
                {
                    translate = CGPoint(x: CGFloat(x), y: CGFloat(y))
                    updateShapeLayer()
                }
            }
        }
    }
    
    func updateShapeLayer()
    {
        if let pathStringToParse = d {
            self.path = pathStringToParse.pathFromSVGString()
            self.shapeLayer.path = self.path.cgPath
            
            #if os(iOS)
            if let translate = translate {
                var translation = CGAffineTransform(translationX: translate.x, y: translate.y)
                if let cgpath = self.path.cgPath.copy(using: &translation) {
                    self.path = UIBezierPath(cgPath: cgpath)
                    self.shapeLayer.path = self.path.cgPath
                }                
            }
            #endif
        }                
    }
    
}

@objc(SVGElement) private class SVGElement: NSObject { }

open class SVGParser : NSObject, XMLParserDelegate {
    
    fileprivate var elementStack = Stack<NSObject>()
    
    open var containerLayer: CALayer?
    open var shouldParseSinglePathOnly = false
    open fileprivate(set) var paths = [UIBezierPath]()
    
    public convenience init(SVGURL: URL, containerLayer: CALayer? = nil, shouldParseSinglePathOnly: Bool = false) {
        
        self.init()
        
        if let layer = containerLayer {
            self.containerLayer = layer
        }
        
        if let xmlParser = XMLParser(contentsOf: SVGURL) {
            xmlParser.delegate = self
            xmlParser.parse()
        } else {
            assert(false, "Couldn't initialize parser. Check your resource and make sure the supplied URL is correct")
        }
    }
    
    open func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if let newElement = tagMapping[elementName] {
            
            let className = NSClassFromString(newElement) as! NSObject.Type
            let newInstance = className.init()
            
            let allPropertyNames = newInstance.propertyNames()
            for thisKeyName in allPropertyNames {
                if let attributeValue: AnyObject = attributeDict[thisKeyName] as AnyObject? {
                    newInstance.setValue(attributeValue, forKey: thisKeyName)
                }
            }
            
            if newInstance is SVGPath {
                let thisPath = newInstance as! SVGPath
                if self.containerLayer != nil {
                    self.containerLayer!.addSublayer(thisPath.shapeLayer)
                }
                self.paths.append(thisPath.path)
                
                if self.shouldParseSinglePathOnly == true {
                    parser.abortParsing()
                }
            }
            
            self.elementStack.push(newInstance)
        }
    }
    
    
    open func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let lastItem = self.elementStack.last {
            if let keyForValue = allKeysForValue(tagMapping,valueToMatch: lastItem.classNameAsString())?.first {
                if elementName == keyForValue {
                    self.elementStack.pop()
                }
            }
        }
    }
    
}
