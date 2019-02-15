//
//  NSAttributedString+Extensions.swift
//
//  Created by Franklyn on 9/02/2019.
//  Copyright © 2019 Franklyn. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreText


extension NSAttributedString {

    var cgPath: CGPath? {

        let size: CGSize = self.size()
        let frameSetter: CTFramesetter = CTFramesetterCreateWithAttributedString(self)
        let tempPath: CGPath = CGPath(rect: CGRect(origin: CGPoint.zero, size: size), transform: nil)
        let frame: CTFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), tempPath, nil)

        guard let lines: [CTLine] = (CTFrameGetLines(frame) as [AnyObject]) as? [CTLine] else { return nil }

        var points: [CGPoint] = [CGPoint](repeating: CGPoint.zero, count: lines.count)

        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &points)

        let path: CGMutablePath = CGMutablePath()

        lines.enumerated().forEach { pair in

            let line: CTLine = pair.element

            guard let glyphRuns: [CTRun] = (CTLineGetGlyphRuns(line) as [AnyObject]) as? [CTRun] else { return }

            var flush: CGFloat = 0
            let range: CFRange = CTLineGetStringRange(line)
            if let paragraphStyle: Any = self.attribute(.paragraphStyle, at: range.location, effectiveRange: nil), let style: NSParagraphStyle = paragraphStyle as? NSParagraphStyle {
                switch style.alignment {
                case .left:
                    flush = 0
                case .center, .justified:
                    flush = 0.5
                case .right:
                    flush = 1
                default:
                    break
                }
            }

            let xOffset: CGFloat = CGFloat(CTLineGetPenOffsetForFlush(line, flush, Double(size.width)))
            let yOffset: CGFloat = points[pair.offset].y

            glyphRuns.forEach { glyphRun in

                // there is some bonkers-looking casting code here, as CoreFoundation doesn't play well with optional casting
                // eg, trying to cast fontAttributes as? CTFont (below) won't compile, with the error 'Conditional downcast to CoreFoundation type 'CTFont' will always succeed'
                // the bridging works for casting to AnyObject, [AnyObject] & [String: AnyObject], but not for the individual CF types
                // we could use force-casting, but I'd prefer not to

                guard let attributes: [String: AnyObject] = CTRunGetAttributes(glyphRun) as? [String: AnyObject] else { return }
                guard let fontAttributes: AnyObject = attributes[kCTFontAttributeName as String] else { return }
                guard let fontArray: [CTFont] = [fontAttributes] as? [CTFont], let font: CTFont = fontArray.first else { return }

                let count: CFIndex = CTRunGetGlyphCount(glyphRun)

                (0..<count).forEach { index in

                    let range: CFRange = CFRangeMake(index, 1)
                    var glyph: CGGlyph = CGGlyph()
                    var position: CGPoint = CGPoint()

                    CTRunGetGlyphs(glyphRun, range, &glyph)
                    CTRunGetPositions(glyphRun, range, &position)

                    position.x += xOffset
                    position.y -= yOffset

                    if let letterPath: CGPath = CTFontCreatePathForGlyph(font, glyph, nil) {
                        let transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: position.x, ty: position.y)
                        path.addPath(letterPath, transform: transform)
                    }
                }
            }
        }

        return path
    }


    /// The multiline version doesn't work for custom fonts (why?)
    var cgPathForSingleLine: CGPath? {

        let line: CTLine = CTLineCreateWithAttributedString(self)

        guard let glyphRuns: [CTRun] = (CTLineGetGlyphRuns(line) as [AnyObject]) as? [CTRun] else { return nil }

        let path: CGMutablePath = CGMutablePath()

        glyphRuns.forEach { glyphRun in

            guard let attributes: [String: AnyObject] = CTRunGetAttributes(glyphRun) as? [String: AnyObject] else { return }
            guard let fontAttributes: AnyObject = attributes[kCTFontAttributeName as String] else { return }
            guard let fontArray: [CTFont] = [fontAttributes] as? [CTFont], let font: CTFont = fontArray.first else { return }

            let count: CFIndex = CTRunGetGlyphCount(glyphRun)

            (0..<count).forEach { index in

                let range: CFRange = CFRangeMake(index, 1)
                var glyph: CGGlyph = CGGlyph()
                var position: CGPoint = CGPoint()

                CTRunGetGlyphs(glyphRun, range, &glyph)
                CTRunGetPositions(glyphRun, range, &position)

                if let letterPath: CGPath = CTFontCreatePathForGlyph(font, glyph, nil) {
                    let transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: position.x, ty: position.y)
                    path.addPath(letterPath, transform: transform)
                }
            }
        }

        return path
    }
}
