module Sudoku where
import Test.QuickCheck
import Data.Char hiding (isDigit)
import Data.List
import Data.Maybe


-------------------------------------------------------------------------

-- | Representation of sudoku puzzlese (allows some junk)
newtype Sudoku = Sudoku { rows :: [[Maybe Int]] }
  deriving ( Show, Eq )

type Block = [Maybe Int]

-- | A sample sudoku puzzle
example :: Sudoku
example =
    Sudoku
      [ [j 3,j 6,n  ,n  ,j 7,j 1,j 2,n  ,n  ]
      , [n  ,j 5,n  ,n  ,n  ,n  ,j 1,j 8,n  ]
      , [n  ,n  ,j 9,j 2,n  ,j 4,j 7,n  ,n  ]
      , [n  ,n  ,n  ,n  ,j 1,j 3,n  ,j 2,j 8]
      , [j 4,n  ,n  ,j 5,n  ,j 2,n  ,n  ,j 9]
      , [j 2,j 7,n  ,j 4,j 6,n  ,n  ,n  ,n  ]
      , [n  ,n  ,j 5,j 3,n  ,j 8,j 9,n  ,n  ]
      , [n  ,j 8,j 3,n  ,n  ,n  ,n  ,j 6,n  ]
      , [n  ,n  ,j 7,j 6,j 9,n  ,n  ,j 4,j 3]
      ]
  where
    n = Nothing
    j = Just

-- * A1
-- | allBlankSudoku is a sudoku with just blanks
allBlankSudoku :: Sudoku
allBlankSudoku = Sudoku $ replicate 9 $ replicate 9 Nothing


-- * A2
-- | isSudoku sud checks if sud is really a valid representation of a sudoku
-- puzzle
isSudoku :: Sudoku -> Bool
isSudoku (Sudoku rows) = length rows == 9 && checkSudoku rows isDigitOrNothing

-- Checks that each row is of size 9 and calls helpermethod to check that each element is empty or 1-9 
checkSudoku :: [[Maybe Int]] -> (Maybe Int -> Bool) -> Bool
checkSudoku [] _ = True
checkSudoku (row:rows) f = length row == 9 && checkRow row f && checkSudoku rows f

-- Checks that each element is either empty or between 1-9
checkRow :: [Maybe Int] -> (Maybe Int -> Bool) -> Bool
checkRow row f = all f row

-- Helper method to check digit
isDigitOrNothing :: Maybe Int -> Bool
isDigitOrNothing Nothing = True
isDigitOrNothing number = number < Just 10 && number > Just 0

-- * A3

-- | isFilled sud checks if sud is completely filled in,
-- i.e. there are no blanks
isFilled :: Sudoku -> Bool
isFilled (Sudoku rows) = isSudoku (Sudoku rows) && checkSudoku rows isDigit

isDigit :: Maybe Int -> Bool
isDigit Nothing = False
isDigit number = number < Just 10 && number > Just 0

-------------------------------------------------------------------------

-- * B1

-- Prints a sudoku on the screen
printSudoku :: Sudoku -> IO ()
printSudoku (Sudoku rows) = printSudokuRows rows 

-- Goes through the matrix and change the matrix to the format 
printSudokuRows :: [[Maybe Int]] -> IO ()
printSudokuRows [] = return ()
printSudokuRows (row:rows) =
    do putStr (unwords (printSudokuElement row) ++ "\n")
       printSudokuRows rows

printSudokuElement :: [Maybe Int] -> [String]
printSudokuElement = map makePrintElement 

-- Changes the sign to print
makePrintElement :: Maybe Int -> String
makePrintElement element = case element of
    Nothing -> "."
    Just n -> show n

-- * B2

-- | readSudoku file reads from the file, and either delivers it, or stops
-- if the file did not contain a sudoku
readSudoku :: FilePath -> IO Sudoku
readSudoku source =  do c <- readFile source 
                        checkFormat $ convertListToSudoku $ map lines $ lines c
                        -- Try dots
                        

checkFormat :: Sudoku -> IO Sudoku
checkFormat sud 
            | isSudoku sud = return sud
            | otherwise = error "Not a Sudoku"

convertListToSudoku :: [[String]] -> Sudoku
convertListToSudoku list = Sudoku (map convertRowToSudoku list)

convertRowToSudoku :: [String] -> [Maybe Int]
convertRowToSudoku = map (makeSudokuElement . (:[])) . unwords

-- Change the element back to the original element
makeSudokuElement :: String -> Maybe Int
makeSudokuElement element = case element of
    "." -> Nothing
    n -> Just $ read n :: Maybe Int

-------------------------------------------------------------------------

-- * C1

-- | cell generates an arbitrary cell in a Sudoku
cell :: Gen (Maybe Int)
cell = frequency [(9, return Nothing),
                  (1, nonEmpty)]
                  where nonEmpty = elements[Just n | n<- [1..9]]

-- * C2

-- | an instance for generating Arbitrary Sudokus
instance Arbitrary Sudoku where
  arbitrary =
    do rows <- vectorOf 9 (vectorOf 9 cell)
       return (Sudoku rows)

-- * C3
-- | Checks if all sudokus is sudokus according to A2
prop_Sudoku :: Sudoku -> Bool
prop_Sudoku = isSudoku

-------------------------------------------------------------------------
-- * D1
-- | Checks that the blocks have no duplicate numbers
isOkayBlock :: Block -> Bool
isOkayBlock block = length newBlock == length oldBlock
        where newBlock = nub oldBlock 
              oldBlock = catMaybes block
-- * D2
-- | Splits the sudoku into blocks that consists of 9 elements, either a row, column or a 'square'
blocks :: Sudoku -> [Block]
blocks sud = rows sud ++ transpose (rows sud) ++ buildNewMatrix (rows sud)

-- | Converts a list in the sudoku into three lists with three elements each
convertRows :: [Maybe Int] -> [[Maybe Int]]
convertRows [] = []
convertRows list = take 3 list : convertRows (drop 3 list)

-- | Given three lists builds them into 3x3 blocks
buildBlocks :: [[Maybe Int]] -> [[Maybe Int]] -> [[Maybe Int]] -> [[Maybe Int]]
buildBlocks [] [] []  = []
buildBlocks list1 list2 list3 = (head list1 ++ head list2 ++ head list3) : buildBlocks 
                                                                    (drop 1 list1)
                                                                    (drop 1 list2) 
                                                                    (drop 1 list3)
-- | Builds a new matrix consisting of 9 3x3 blocks                                                                    
buildNewMatrix :: [[Maybe Int]] -> [[Maybe Int]]
buildNewMatrix rows | null rows = []
                    | otherwise = newMatrix ++ buildNewMatrix ( drop 3 rows)
                   where newMatrix = buildBlocks l1 l2 l3
                         l1 = convertRows (head extract3)
                         l2 = convertRows (extract3 !! 1)
                         l3 = convertRows (extract3 !! 2)
                         extract3 = take 3 rows
-- | Checks that there are 27 blocks and all blocks have a length of 9
prop_blocks_lengths :: Sudoku -> Bool
prop_blocks_lengths sud = length listOfBlocks == 3*9 && all (\x -> length x == 9) listOfBlocks
                            where listOfBlocks = blocks sud
                                  

-- D3
-- | Checks that all blocks are okay
isOkay :: Sudoku -> Bool 
isOkay sud = all isOkayBlock $ blocks sud


-- E1
type Pos = (Int, Int)

-- | Find all the blank positions in the Sudoku, that is where the elements are Nothing
blanks :: Sudoku -> [Pos]
blanks (Sudoku rows) = [ (r,c) | (r, row) <- zip [0..] rows, (c, Nothing) <- zip [0..] row]

-- | Checks that for all blanks in a sudoku that they actually were nothing
prop_blanks_allBlank :: Sudoku -> Bool
prop_blanks_allBlank sud = and [ b | (x, y) <- blanks sud, b <- [isNothing (rows sud !! x !! y)]]


-- E2
-- | Inserts an element into a list given an index.
(!!=)  :: [a] -> (Int,a) ->[a]
list !!= (index, element) = start ++ element:end
                        where (start,_:end) = splitAt index list


-- | Checks that the lists have the same length after inserting a new 
-- element and that the inserted element is in the index it was inserted                    
prop_bangBangEquals_correct :: [Int] -> (Int,Int) -> Property
prop_bangBangEquals_correct list (index, element) = index <= length list-1  && index > 0 ==>
                                                    newList !! index == element
                                                    && length list == length newList
                                        where newList = list !!= (index, element)

-- E3
-- | Updates a given index in the sudoku with a new element
update :: Sudoku -> Pos -> Maybe Int -> Sudoku
update (Sudoku rows) (row,col) element = Sudoku (rows !!= (row,(rows !! row) !!= (col, element)))

-- | Checks that the element in the sudoku will be updated with our update function
prop_update_updated :: Sudoku -> Pos -> Maybe Int-> Bool
prop_update_updated sudoku (x,y) element | element == (rows sudoku !! x' !! y') = True 
                                         | otherwise  = sudoku /= update sudoku (x',y') element
                    where x' = mod x 8
                          y' = mod y 8


-- E4
-- Given a position in a sudoku, gives the candidates of elements for that cell
candidates :: Sudoku -> Pos -> [Int]
candidates sudoku@(Sudoku rows) (x,y) = filter (`elem` rowAndCol) allNum
                        where row = rows !! x  
                              col = transpose rows !! y
                              block = takeOutBlock (buildNewMatrix rows) (x,y)
                              allNum = [1..9]
                              filteredRow= filter (`notElem` catMaybes row) allNum
                              filteredCol = filter (`notElem` catMaybes col) allNum
                              rowAndCol = filteredRow `intersect` filteredCol `intersect` filteredBlocks
                              filteredBlocks = filter (`notElem` catMaybes block) allNum

-- | Takes out a 3x3 block given the row and column
takeOutBlock :: [Block] -> Pos -> Block
takeOutBlock ourBlock (row,col) = rowBlock !! x
                          where rowBlock = take 3 $ drop y ourBlock
                                x = col `div` 3
                                y = (row `div` 3) * 3
-- | Checks that given candidates for a blank position, if sudoku is updated with given candidate it is still okay 
prop_candidates_correct :: Sudoku -> Property
prop_candidates_correct sudoku = isSudoku sudoku && isOkay sudoku  ==>
                                         all isSudoku updatedSudoku && all isOkay updatedSudoku  
    where candidateList = candidates sudoku blank
          updatedSudoku = map (update sudoku blank . Just) candidateList
          blank = head $ blanks sudoku
--F1          
-- | Solves a sudoku if it can
solve :: Sudoku -> Maybe Sudoku
solve sud | isSudoku sud && isOkay sud = solve' sud
          | otherwise = Nothing

-- | Helper function to solve a sudoku
solve' :: Sudoku -> Maybe Sudoku
solve' sud | isFilled sud = Just sud
           | otherwise = case  mapMaybe solve' sudokuList of
                [] -> Nothing
                (solvedSud:_) -> Just solvedSud
    where sudokuList = map (update sud blank . Just) (candidates sud blank)
          blank = head $ blanks sud

-- Maybe exchange fromJust!
-- F2
-- | Reads a sudoku and tries to solve it
readAndSolve :: FilePath -> IO ()
readAndSolve filepath = do
    s <- readSudoku filepath
    if isOkay s then printSudoku $ fromJust $ solve s else error "No solution"
-- | Checks that the solved sudoku is a solution of the unsolved sudoku
isSolutionOf :: Sudoku -> Sudoku -> Bool
isSolutionOf solved unsolved = isSolved && (solve solved == solve unsolved)
        where 
            isSolved = isFilled solved && isOkay solved 
-- | Checks that every supposed solution produced by solve actually is a valid solution of the original problem.
prop_SolveSound :: Sudoku -> Property
prop_SolveSound sud =  isJust (solve sud)  ==> fromJust (solve sud) `isSolutionOf` sud


