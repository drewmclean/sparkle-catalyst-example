//
//  AppUpdater+SparkleFeedParser.swift
//  AppKitPlugin
//
//  Created by Andrew McLean on 8/23/24.
//

import Foundation
import Sparkle

extension AppUpdater {
    
    final class SparkleFeedParser: NSObject, XMLParserDelegate {
        typealias ParseCompletion = (_ version: String, _ build: String) -> Void
        
        private var currentElement = ""
        private var completion: ParseCompletion? = nil
        
        private var displayVersionString: String? = nil
        private var versionString: String? = nil
        
        func parse(data: Data, completion: ParseCompletion?) {
            self.completion = completion
            
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        }
        
        // MARK: - XMLParserDelegate
        
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            currentElement = elementName
        }
        
        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if currentElement == "sparkle:version" {
                versionString = string
            } else if currentElement == "sparkle:shortVersionString" {
                displayVersionString = string
            }
        }
        
        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            currentElement = ""
        }
        
        func parserDidEndDocument(_ parser: XMLParser) {
            if let version = displayVersionString, let build = versionString {
                print("Version: \(version)-\(build)")
                completion?(version, build)
            } else {
                print("Failed to find version or build information.")
            }
        }
        
        deinit {
            completion = nil
        }
        
    }
}
