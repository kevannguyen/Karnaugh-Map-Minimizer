//
//  KmapLogic.swift
//  K-Map App
//
//  Created by Kevan Nguyen on 7/8/15.
//  Copyright (c) 2015 Kevan Nguyen. All rights reserved.
//

import Foundation

class KmapLogic {
    
    var alphabet = "ABCDEFGHIJKLMNO"
    var numVariables: Int
    var mintermGroups: Set<Int>
    
    init(numVariables: Int) {
        self.numVariables = numVariables
        mintermGroups = Set<Int>()
    }
    
    func findPrimeImplicants(minGroups: Set<Int>) -> [MintermGroup]{
        var numOnes = numVariables + 1
        var primeImplicants = [MintermGroup]()
        // Starting groups
        var groups = groupMinterms(mintermToMintermGroups(minGroups), numOnes: numOnes)
        var didCombine = true // Gets reset every group rotation
        
        
        while didCombine == true {
            var newCombinedGroups = [MintermGroup]()
            didCombine = false
            if numOnes <= 1 {
                break
            }
            
            for i in 0..<(numOnes-1) {
                for group1 in groups[i] {
                    for group2 in groups[i+1] {
                        let combinedGroup = group1.compare(group2)
                        if combinedGroup != nil {
                            didCombine = true
                            newCombinedGroups.append(combinedGroup!)
                        }
                    }
                }
            }
            
            // Check for any uncombinable pairs (to be added to the primeImplicants group)
            for i in 0..<numOnes {
                for group in groups[i] {
                    //println("\(group.minterms)   \(group.grayCode)     \(group.canBeCombined)")
                    if group.canBeCombined == false {
                        // Check to see if there's already an existing one of the same greycode
                        var hasSame = false
                        for mintermGroup in primeImplicants {
                            if mintermGroup.grayCode == group.grayCode {
                                hasSame = true
                            }
                        }
                        if hasSame == false {
                            primeImplicants.append(group)
                        }
                    }
                }
                //println()
            }
            numOnes--
            groups = groupMinterms(newCombinedGroups, numOnes: numOnes)
        }
        
        return primeImplicants
    }
    
    
    // FUNCTION that organizes the minterms into groupings by number of ones
    // numOnes refers to the groupings. If we initially start with a 4-variable kmap,
    // numOnes would be 5 (includes 0,1,2,3,4). The next comparison would then be 4 (includes 0,1,2,3)
    func groupMinterms(mintermGroups: [MintermGroup], numOnes: Int) -> [[MintermGroup]] {
        var finalGroups = [[MintermGroup]](count: numOnes, repeatedValue: [])
        for group in mintermGroups {
            finalGroups[group.numOnes].append(group)
        }
        return finalGroups
    }
    
    // Constructs prime implicant table like so
    // http://www.cs.columbia.edu/~cs6861/handouts/quine-mccluskey-handout.pdf
    func constructPrimeImplicantTable(mintermNums: Set<Int>, primeImplicants: [MintermGroup]) -> [Int : [MintermGroup]] {
        // Dictionary with the minterm numbers as the keys
        // and the minterm
        var table = [Int : [MintermGroup]]()
        
        // Create the keys (nums) first. Initialized with empty lists
        for num in mintermNums {
            var implicantList = [MintermGroup]() // To be added to its respective table[num]
            for primeImplicant in primeImplicants {
                if primeImplicant.containsMintermNumber(num) {
                    implicantList.append(primeImplicant)
                }
            }
            table[num] = implicantList
        }
        
        return table
    }
    
    // FINAL SOLUTION
    func findFinalSolution(mintermNums: Set<Int>) -> String {
        if mintermNums.count >= KmapLogic.numPower(2, power: numVariables) {
            //println("1\n")
            return "1"
        }
        
        if mintermNums.count == 0 {
            //println("0")
            return "0"
        }
        
        let primeImplicants = findPrimeImplicants(mintermNums)
        var implicantTable = constructPrimeImplicantTable(mintermNums, primeImplicants: primeImplicants)
        
        var solution = [MintermGroup]()
        
        while true {
            var gotEssentialPrimeImplicants = false
            var gotRowDominance = false
            var gotColumnDominance = false
            
            
            // Stage 1
            var essentialPrimeImplicants = getEssentialPrimeImplicants(implicantTable)
            if essentialPrimeImplicants.count > 0 {
                solution += essentialPrimeImplicants
                gotEssentialPrimeImplicants = true
                
                var essentialGrayCodesToRemoveFromTable = [String]()
                var essentialRowsToRemoveFromTable = Set<Int>()
                
                for mintermGroup in essentialPrimeImplicants {
                    essentialGrayCodesToRemoveFromTable.append(mintermGroup.grayCode)
                    essentialRowsToRemoveFromTable = essentialRowsToRemoveFromTable.union(Set(mintermGroup.minterms))
                }
                
                implicantTable = removeRowsFromTable(implicantTable, rows: Array<Int>(essentialRowsToRemoveFromTable))
                implicantTable = removeColumnsFromTable(implicantTable, columns: essentialGrayCodesToRemoveFromTable)
            }
            
            
            // Stage 2: Row Dominance
            var dominantRowsToRemoveFromTable = rowDominance(implicantTable)
            if dominantRowsToRemoveFromTable.count > 0 {
                gotRowDominance = true
                implicantTable = removeRowsFromTable(implicantTable, rows: dominantRowsToRemoveFromTable)
            }
            
            
            // Stage 3: Column Dominance
            var dominatedColumnsToRemoveFromTable = colDominance(implicantTable)
            if dominatedColumnsToRemoveFromTable.count > 0 {
                gotColumnDominance = true
                implicantTable = removeColumnsFromTable(implicantTable, columns: dominatedColumnsToRemoveFromTable)
            }
            
            
            
            // Exit out of loop when these conditions are meant
            if !gotEssentialPrimeImplicants && !gotRowDominance && !gotColumnDominance {
                break
            }
            
        }
        
        
        // IMPLEMENT PETRICKS METHOD HERE
        solution += petricksMethod(implicantTable)
        
        return solutionToString(solution)
    }
    
    // TO BE USED WITH THE findFinalSolution function
    func solutionToString(solution: [MintermGroup]) -> String {
        let letters = alphabet.substringWithRange(Range(start: alphabet.startIndex, end: advance(alphabet.startIndex, numVariables)))
        var convertedSolution = [String]()
        for minterm in solution {
            convertedSolution.append(KmapLogic.convertBitsToLetters(minterm.grayCode, letters: letters))
        }
        return " + ".join(convertedSolution)
    }

    func petricksMethod(implicantTable: [Int : [MintermGroup]]) -> [MintermGroup] {
        var solutions = [MintermGroup]()
        
        // Dictionary that holds the P1,P2,P3.. combinations...
        // Keys are the mintermGroup.grayCodes and the values are Ints (1,2,3,4,5,etc...)
        // Ex: ["-001" : 0 , "0-1-" : 1, "1101" : 2]
        var groupings = [String : Int]()
        
        for (grayCode, mintermNumbers) in inverseImplicantTable(implicantTable) {
            groupings[grayCode] = groupings.count
        }
        
        // Initialize all the groups to multiply like this example...
        // P = (P1 + P2)(P3 + P4)(P1 + P3)(P5 + P6)(P2 + P5)(P4 + P6)
        // *** The groups are in parentheses
        var groupsToMultiply = [[Set<Int>]]()
        for (row, columnGroups) in implicantTable {
            var group = [Set<Int>]()
            for mintermGroup in columnGroups {
                group.append(Set([groupings[mintermGroup.grayCode]!]))
            }
            groupsToMultiply.append(group)
        }

        if groupsToMultiply.count > 0 {
            var totalProduct = groupsToMultiply[0]
            for i in 1..<groupsToMultiply.count {
                totalProduct = booleanMultiplyTwoGroups(totalProduct, group2: groupsToMultiply[i])
            }
            
            // SORT THE ENTIRE PRODUCT NOW
            
            totalProduct.sortInPlace {$0.count < $1.count }
            
            // Look through all the P1, P2, etc. values of the solution (the smallest product)
            var grayCodeSolutions = [String]()
            for groupingNumber in totalProduct[0] {
                for (grayCodeKey, grayCodeGroupingNumber) in groupings {
                    if groupingNumber == grayCodeGroupingNumber {
                        grayCodeSolutions.append(grayCodeKey)
                        break
                    }
                }
            }
            
            // Convert the list of gray codes into a list of MintermGroups now
            for grayCode in grayCodeSolutions {
                for (row, columnGroups) in implicantTable {
                    var foundMatchingGrayCode = false
                    for mintermGroup in columnGroups {
                        if mintermGroup.grayCode == grayCode {
                            solutions.append(mintermGroup)
                            foundMatchingGrayCode = true
                            break
                        }
                    }
                    if foundMatchingGrayCode {
                        break
                    }
                }
            }
        }
        
        return solutions
    }
    
    
    // For use in petricksMethod()
    // Takes in two groups - Ex:   (P1 + P2P3) * (P3 + P4)
    // Note: A group is just a list of sets. [Set<Int>] ..... [{1}, {2, 3}]
    func booleanMultiplyTwoGroups(group1: [Set<Int>], group2: [Set<Int>]) -> [Set<Int>] {
        var result = [Set<Int>]()
        
        for i in 0..<group1.count {
            for j in 0..<group2.count {
                let temp = group1[i].union(group2[j])
                result.append(temp)
            }
        }
        
        return result
    }

    // Takes in an implicant table and returns all of its essential prime implicants
    func getEssentialPrimeImplicants(implicantTable: [Int : [MintermGroup]]) -> [MintermGroup] {
        var result = [MintermGroup]()
        var grayCodeSet = Set<String>()
        for group in implicantTable.values {
            if group.count == 1 {
                if !grayCodeSet.contains(group[0].grayCode) {
                    grayCodeSet.insert(group[0].grayCode)
                    result.append(group[0])
                }
            }
        }
        return result
    }
    
    // Takes in an implicant table and returns a list of rows to be deleted 
    // (rows that dominate others will be deleted)
    func rowDominance(implicantTable: [Int : [MintermGroup]]) -> [Int] {
        var result = Set<Int>()
        for (row1, columnGroups1) in implicantTable {
            for (row2, columnGroups2) in implicantTable {
                if row1 != row2 && !result.contains(row1){
                    var isDominatedByRow2 = true
                    for mintermGroup1 in columnGroups1 {
                        var doesContain = false
                        for mintermGroup2 in columnGroups2 {
                            if mintermGroup1.sameGrayCode(mintermGroup2) {
                                doesContain = true
                                break
                            }
                        }
                        if !doesContain {
                            isDominatedByRow2 = false
                            break
                        }
                    }
                    if isDominatedByRow2 {
                        result.insert(row2)
                    }
                }
            }
        }
        return Array<Int>(result)
    }
    
    // Takes in an implicant table and returns a list of columns (MintermGroups.grayCode) to be deleted
    // (columns that dominate others will be deleted)
    func colDominance(implicantTable: [Int : [MintermGroup]]) -> [String] {
        let inverseTable = inverseImplicantTable(implicantTable)
        var result = Set<String>()
        
        for (grayCode1, mintermNumbers1) in inverseTable {
            for (grayCode2, mintermNumbers2) in inverseTable {
                if grayCode1 != grayCode2 && !result.contains(grayCode2) {
                    if Set(mintermNumbers1).isSubsetOf(Set(mintermNumbers2)) {
                        result.insert(grayCode1)
                    }
                }
            }
        }
        
        return Array<String>(result)
    }
    
    // Columns (MintermGroups) are now the keys and rows (minterm numbers) are the values
    // The Key is just the grayCode
    func inverseImplicantTable(implicantTable: [Int : [MintermGroup]]) -> [String : [Int]] {
        var inverseTable = [String : [Int]]()
        
        for (row, columnGroups) in implicantTable {
            for mintermGroup in columnGroups {
                if inverseTable[mintermGroup.grayCode] == nil {
                    inverseTable[mintermGroup.grayCode] = [row]
                }
                else {
                    inverseTable[mintermGroup.grayCode]!.append(row)
                }
            }
        }
        
        return inverseTable
    }
    
    // Removes rows (minterm numbers) from a specified prime implicants
    // table. Returns a new simplified prime implicants table now.
    func removeRowsFromTable(implicantTable: [Int : [MintermGroup]], rows: [Int]) -> [Int : [MintermGroup]] {
        var finalTable = implicantTable
        for row in rows {
            finalTable.removeValueForKey(row)
        }
        return finalTable
    }
    
    // Removes columns (minterm groups.grayCode) from a specified prime implicants
    // table. Returns a new simplified prime implicants table now.
    func removeColumnsFromTable(implicantTable: [Int : [MintermGroup]], columns: [String]) -> [Int : [MintermGroup]] {
        var finalTable = [Int : [MintermGroup]]()
        
        for (row, columnGroups) in implicantTable {
            var mintermGroups = [MintermGroup]()
            for col1 in columnGroups {
                if !Set(columns).contains(col1.grayCode) {
                    mintermGroups.append(col1)
                }
            }
            finalTable[row] = mintermGroups
        }
        
        return finalTable
    }
    
    // Adds/removes a minterm group to our current list
    func addOrRemoveMinterm(minterm: Int) {
        if mintermGroups.contains(minterm) {
            mintermGroups.remove(minterm)
        }
        else {
            mintermGroups.insert(minterm)
        }
    }

    func mintermToMintermGroups(minGroups: Set<Int>) -> [MintermGroup] {
        var finalGroups = [MintermGroup]()
        for minterm in minGroups {
            finalGroups.append(MintermGroup(minterms: [minterm], grayCode: KmapLogic.decToBinary(minterm, numVariables: self.numVariables)))
        }
        return finalGroups
    }
    
    static func decToBinary(dec: Int, numVariables: Int) -> String {
        var total = dec
        var binary = ""
        for var i = numVariables-1; i >= 0; i-- {
            let raisedPower = numPower(2, power:i)
            binary += String(total / raisedPower)
            total %= raisedPower
        }
        return binary
    }
    
    static func binaryToDec(binary: String) -> Int {
        /*
        Converts binary to decimal.
        USED to convert graycode to MINTERMS.
        */
        var dec = 0
        // Iterate through binary number right to left
        for i in 0..<binary.characters.count {
            let num = Int(String(binary[advance(binary.startIndex, binary.characters.count-i-1)]))!
            dec += (numPower(2, power: i) * num)
        }
        return dec
    }
    
    // bits and letters must be of same length!
    static func convertBitsToLetters(bits: String, letters: String) -> String {
        var result = ""
        for i in 0..<bits.characters.count {
            if bits[advance(bits.startIndex, i)] == "-" {
                continue
            }
            result += String(letters[advance(bits.startIndex, i)])
            if bits[advance(bits.startIndex, i)] == "0" {
                result += "\u{305}"
            }
        }
        return result
    }
    
    // Exponent function
    static func numPower(number: Int, power: Int) -> Int {
        if power == 0 {
            return 1
        }
        var product = number
        for i in 1..<power {
            product *= number
        }
        return product
    }
    
    // Initialize Grey Code Bits function
    static func initializeBits(numVariables: Int) -> [String] {
        /*
        Used to create grey code bits
        */
        var varCount = 2
        // Has to start off with 0 and 1
        var bits = ["0", "1"]
        
        while varCount <= numVariables {
            // Add the 1s to the front first
            for var i = numPower(2, power:(varCount-1))-1; i >= 0; i-- {
                bits.append("1" + bits[i])
            }
            // then add the 0s to the front
            for j in 0..<numPower(2, power:(varCount-1)) {
                bits[j] = "0" + bits[j]
            }
            varCount += 1
        }
        
        return bits
    }
    
}

class MintermGroup {
    
    var minterms: [Int]
    var grayCode: String
    var numOnes: Int { return self.getNumOnes() }
    // Variable that checks whether or not a minterm group cannot be combined anymore
    // https://en.wikipedia.org/wiki/Quine%E2%80%93McCluskey_algorithm
    // ("starred")
    var canBeCombined: Bool
    
    init(minterms: [Int], grayCode: String) {
        self.minterms = minterms
        self.grayCode = grayCode
        self.canBeCombined = false
    }
    
    // Compares two MintermsGroups with each other and returns a new
    // MintermGroup if they vary by just 1 bit
    func compare(another: MintermGroup) -> MintermGroup? {
        var bitChangeCount = 0
        var bits = ""
        for i in 0..<another.grayCode.characters.count {
            let index = advance(grayCode.startIndex, i)
            if self.grayCode[index] == "-" || another.grayCode[index] == "-" {
                if self.grayCode[index] != another.grayCode[index] {
                    return nil
                }
                else {
                    bits += "-"
                }
            }
            
            else if self.grayCode[index] != another.grayCode[index] {
                bitChangeCount++
                bits += "-"
            }
            
            else {
                bits += String(self.grayCode[index])
            }
        }
        
        if bitChangeCount == 1 {
            self.canBeCombined = true
            another.canBeCombined = true
            //println("SWAG \(self.grayCode)   \(another.grayCode)")
            return MintermGroup(minterms: self.minterms + another.minterms, grayCode: bits)
        }
        
        else {
            return nil
        }
        //return bitChangeCount == 1 ? MintermGroup(minterms: self.minterms + another.minterms, grayCode: bits) : nil
    }
    
    func sameGrayCode(another: MintermGroup) -> Bool {
        return self.grayCode == another.grayCode
    }
    
    func containsMintermNumber(num: Int) -> Bool{
        return Set(minterms).contains(num)
    }
    
    func getNumOnes() -> Int {
        var total = 0
        for c in self.grayCode.characters {
            if c == "1" {
                total++
            }
        }
        return total
    }
    
}