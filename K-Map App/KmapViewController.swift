//
//  KmapViewController.swift
//  K-Map App
//
//  Created by Kevan Nguyen on 7/8/15.
//  Copyright (c) 2015 Kevan Nguyen. All rights reserved.
//

import UIKit

class KmapViewController: UIViewController {
    
    // Variable constants (just the alphabet)
    let alphabet: String = "ABCDEFGHIJKLMNO"
    
    // Number of variables (2 to 5)
    var numVariables: Int = 2
    var numVariablesHorizontal: Int { return numVariables / 2 }
    var numVariablesVertical: Int { return (numVariables+1) / 2 }
    var numRows: Int { return numPower(2, power: numVariablesVertical) }
    var numCols: Int { return numPower(2, power: numVariablesHorizontal) }

    // Underneath the Carrier logo where the first cell will draw
    var gridVerticalOffset: CGFloat { return self.view.bounds.height * 0.10 }
    var gridHorizontalOffset: CGFloat { return self.view.bounds.width * 0.08 }
    // If numVariables is odd, then it starts drawing more towards the center (it's a rectangle)
    var extraHorizontalOffset: CGFloat? // Will be set in initializer
    
    // The Grid is ALWAYS going to be a square (never a rectangle)
    // The kmap grid's drawn width
    var gridWidth: CGFloat { return self.view.bounds.width - (2 * gridHorizontalOffset) }
    
    // Cell size (it's a square always)
    var cellWidth: CGFloat { return gridWidth / CGFloat(numRows) }
    
    // Grey Code text attributes
    var fontStyle: String = "Helvetica"
    var greyFontSize: CGFloat { return self.view.bounds.width / 30 }
    var greyFrameHeight: CGFloat { return gridHorizontalOffset / 2 }
    var greyFrameWidth: CGFloat { return cellWidth }
    
    // Solution Label
    var solutionLabel: UILabel?
    
    // Blank Space dimensions (Sits right underneath the grid)
    // Dedicated to give space for the solutions UILabel
    var blankSpaceHeight: CGFloat { return self.view.bounds.height - gridVerticalOffset - gridWidth }
    var blankSpaceWidth: CGFloat { return self.view.bounds.width }
    var solutionsLabelVerticalOffset: CGFloat { return gridVerticalOffset + gridWidth + (blankSpaceHeight / 5)}
    var solutionsLabelHorizontalOffset: CGFloat { return gridHorizontalOffset }
    var solutionsLabelHeight: CGFloat { return blankSpaceHeight - (2 * (blankSpaceHeight / 5)) }
    var solutionsLabelWidth: CGFloat { return blankSpaceWidth - (2 * gridHorizontalOffset) }
    
    // Solution Text Attributes
    var solutionFontSize: CGFloat { return self.view.bounds.width / 10 }
    
    // Kmap Logic Object
    var kmapLogic: KmapLogic?

    override func viewDidLoad() {
        super.viewDidLoad()
        // If numVariables is odd, then it starts drawing more towards the center (it's a rectangle)
        extraHorizontalOffset = (0 + CGFloat(numVariables) % 2) * (gridWidth / 4)
        kmapLogic = KmapLogic(numVariables: numVariables)
        drawCellTable()
        addHorizontalGreyCode()
        addVerticalGreyCode()
        addSolutionLabel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Used for DELEGATION between CellView and KmapLogic
    func handleCellViewMintermAddRemove(mintermNumber: Int) {
        kmapLogic?.addOrRemoveMinterm(mintermNumber)
        let solution = kmapLogic?.findFinalSolution(kmapLogic!.mintermGroups)
        solutionLabel?.text = solution
    }
    
    // DRAWING THE CELLS
    func drawCellTable() {
        /*
        Draws however many kmap cells are specified.
        (numVariables = 2 --> 4 cells
        numVariables = 3 --> 8 cells)
        */
        
        var rowBits = KmapLogic.initializeBits(numVariablesVertical)
        var colBits = KmapLogic.initializeBits(numVariablesHorizontal)
        
        let cellSize = cellWidth
        for row in 0..<numRows {
            for col in 0..<numCols {
                let cell = CellView(frame: CGRect(x:gridHorizontalOffset+extraHorizontalOffset!+(cellSize*CGFloat(col)), y:gridVerticalOffset+(cellSize*CGFloat(row)), width:cellSize, height:cellSize))
                cell.assignController(self)
                cell.assignGrayCode(colBits[col]+rowBits[row])
                self.view.addSubview(cell)
            }
        }
    }
    
    func addHorizontalGreyCode() {
        /*
        Adds the grey code numbers on the top (labels the columns)
        */
        
        var bits = KmapLogic.initializeBits(numVariables/2)
        //var text = "001"
        
        for col in 0..<numCols {
            let greyFrame = CGRect(x:gridHorizontalOffset+extraHorizontalOffset!+(greyFrameWidth*CGFloat(col)), y: gridVerticalOffset-greyFrameHeight, width: greyFrameWidth, height: greyFrameHeight)
            let label = UILabel(frame: greyFrame)
            label.textAlignment = NSTextAlignment.Center
            label.text = KmapLogic.convertBitsToLetters(bits[col], letters: alphabet.substringWithRange(Range(start: alphabet.startIndex, end: advance(alphabet.startIndex, numVariablesHorizontal))))
            label.font = UIFont(name: fontStyle, size: greyFontSize)
            //label.transform = CGAffineTransformMakeRotation(CGFloat(M_PI * 3 / 2))
            self.view.addSubview(label)
        }
    }
    
    func addVerticalGreyCode() {
        /*
        Adds the grey code numbers on the side (labels the rows)
        */
        
        var bits = KmapLogic.initializeBits((numVariables+1)/2)
        
        for row in 0..<numRows {
            //var greyFrame = CGRect(x:gridHorizontalOffset+extraHorizontalOffset!-(greyFrameWidth/2), y: gridVerticalOffset+(greyFrameWidth*CGFloat(row)), width: greyFrameWidth, height: greyFrameHeight)
            let greyFrame = CGRect(x:gridHorizontalOffset+extraHorizontalOffset!-(greyFrameWidth/2)-(greyFrameHeight/2), y: gridVerticalOffset+(greyFrameWidth*CGFloat(row) + ((greyFrameWidth-greyFrameHeight)/2)), width: greyFrameWidth, height: greyFrameHeight)
            let label = UILabel(frame: greyFrame)
            label.textAlignment = NSTextAlignment.Center
            label.text = KmapLogic.convertBitsToLetters(bits[row], letters: alphabet.substringWithRange(Range(start: advance(alphabet.startIndex, numVariablesHorizontal), end: advance(alphabet.startIndex, numVariables))))
            label.font = UIFont(name: fontStyle, size: greyFontSize)
            label.transform = CGAffineTransformMakeRotation(CGFloat(M_PI * 3 / 2))
            self.view.addSubview(label)
        }
        
    }
    
    // Adds the solution UILabel right below the grid,
    // centered in the blank rectangular space below it
    func addSolutionLabel() {
        let frame = CGRect(x: solutionsLabelHorizontalOffset, y: solutionsLabelVerticalOffset, width: solutionsLabelWidth, height: solutionsLabelHeight)
        //var solutionLabel = UILabel(frame: frame)
        solutionLabel = UILabel(frame: frame)
        solutionLabel?.text = "0"
        solutionLabel?.textAlignment = NSTextAlignment.Center
        // Enable text wrapping
        solutionLabel?.lineBreakMode = NSLineBreakMode.ByClipping
        solutionLabel?.numberOfLines = 5
        solutionLabel?.font = UIFont(name: fontStyle, size: solutionFontSize)
        solutionLabel?.adjustsFontSizeToFitWidth = true
        self.view.addSubview(solutionLabel!)
    }

    // Exponent function
    private func numPower(number: Int, power: Int) -> Int {
        var product = number
        for i in 1..<power {
            product *= number
        }
        return product
    }

}
