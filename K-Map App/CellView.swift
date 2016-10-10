//
//  CellView.swift
//  K-Map App
//
//  Created by Kevan Nguyen on 7/8/15.
//  Copyright (c) 2015 Kevan Nguyen. All rights reserved.
//

import UIKit

class CellView: UIView {
    
    // Cell's state is either 0 or 1
    var state: Int = 0 { didSet { setNeedsDisplay() } }
    
    // Cell's Gray Code / Minterm Number
    var grayCode = String()
    var mintermNumber = Int()
    
    // Colors
    var outlineColor: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }
    // Light gray when state = 0, cyan when state = 1
    var fillColors: [UIColor] = [UIColor.lightGrayColor(), UIColor.cyanColor()]
    
    // Line width
    var lineWidth: CGFloat = 2 { didSet { setNeedsDisplay() } }
    
    // UILabel (displays 0/1)
    var label: UILabel?
    
    // Font style/size
    var fontStyle: String = "HelveticaNeue-Bold"
    var fontSize: CGFloat { return bounds.width / 3 }
    
    // Tap gesture recognizer
    let tap = UITapGestureRecognizer()
    
    // KmapViewController
    var viewController: KmapViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tap.addTarget(self, action: "handleTap")
        self.addGestureRecognizer(tap)
        
        label = UILabel(frame: bounds)
        label?.textAlignment = NSTextAlignment.Center
        label?.text = "\(state)"
        label?.font = UIFont(name: fontStyle, size: fontSize)
        self.addSubview(label!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        let cell = UIBezierPath(rect: bounds)
        cell.lineWidth = lineWidth
        fillColors[state].set()
        cell.fill()
        outlineColor.set()
        cell.stroke()
    }
    
    func assignController(sender: KmapViewController) {
        viewController = sender
    }
    
    func assignGrayCode(grayCode: String) {
        self.grayCode = grayCode
        self.mintermNumber = KmapLogic.binaryToDec(grayCode)
    }
    
    func handleTap() {
        state = (state == 0) ? 1 : 0
        label?.text = "\(state)"
        viewController?.handleCellViewMintermAddRemove(mintermNumber)
    }
    
}
