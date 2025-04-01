//
//  CustomFont.swift
//  Athena
//
//  Created by Dhruv Bansal on 3/31/25.
//

import Foundation
import UIKit

class CustomFont {
    static let agaramondProRegular: UIFont = {
        guard let customFont = UIFont(name: "AGaramondPro-Regular", size: UIFont.labelFontSize) else {
            fatalError("""
                Failed to load the "AGaramondPro-Regular" font.
                Make sure the font file is included in the project and the font name is spelled correctly.
                """
            )
        }
        return UIFontMetrics.default.scaledFont(for: customFont)
    }()
}
