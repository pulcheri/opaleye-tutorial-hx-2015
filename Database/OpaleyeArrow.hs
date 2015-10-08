{-# LANGUAGE Arrows #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}

module OpalistArrow where

import Schema
import Opaleye
import qualified Data.Profunctor.Product as PP
import Control.Arrow (returnA)
import Data.Profunctor.Product.Default (Default)
import qualified Database.PostgreSQL.Simple as PGS
import qualified Data.Foldable as F

connectInfo :: PGS.ConnectInfo
connectInfo =  PGS.ConnectInfo { PGS.connectHost = "212.71.249.246"
                               , PGS.connectPort = 5432
                               , PGS.connectUser = "opaleye_guest"
                               , PGS.connectPassword = "opaleye_guest"
                               , PGS.connectDatabase = "opaleye_tutorial" }

printRows :: forall a b proxy.
             (Default QueryRunner a b, Show b)
          => proxy b
          -> Query a
          -> IO ()
printRows _ q = do
  conn <- PGS.connect connectInfo
  rows <- runQuery conn q
  let _ = rows :: [b]
  mapM_ print rows

-- # Projection

workplace :: Query (Column PGText, Column PGText)
workplace = proc () -> do
  employee <- queryTable employees -< ()
  returnA -< (eName employee, eCountry employee)


-- # Restriction

ukEmployees :: Query EmployeeCol
ukEmployees = proc () -> do
  employee <- queryTable employees -< ()  

  restrict -< eCountry employee .== constant "UK"

  returnA -< employee

-- restrict :: QueryArr (Column PGBool) ()
-- guard :: Bool -> [()]
-- List restrict :: QueryArr Bool ()



-- # Join
--
-- Join is just restriction on an equality

managerOf :: Query (Column PGText, Column PGText)
managerOf = proc () -> do
  employee <- queryTable employees -< ()
  manager  <- queryTable managers  -< ()

  restrict -< eDepartment employee .== mDepartment manager

  returnA -< (eName employee, mManager manager)



-- # Aggregation

linesByEmployeeCountry
  :: Query (Column PGText, Column PGText, Column PGInt4)
linesByEmployeeCountry = proc () -> do
  outputRow <- queryTable output -< ()
  returnA -< (oName outputRow, oCountry outputRow, oOutput outputRow)

totalLinesByEmployeeCountry
  :: Query (Column PGText, Column PGText, Column PGInt4)
totalLinesByEmployeeCountry =
  aggregate (PP.p3 (groupBy, groupBy, Opaleye.sum)) linesByEmployeeCountry



-- # Bad aggregation can't happen with arrows

linesByEmployeeIn :: QueryArr (Column PGText) (Column PGText, Column PGInt4)
linesByEmployeeIn = proc country -> do
  outputRow <- queryTable output -< ()
  restrict -< oCountry outputRow .== country
  returnA -< (oName outputRow, oOutput outputRow)

{- 

  We can't write 'totalLinesByEmployeeIn' because its structure is
  syntactically ruled out by arrow notation, given that aggregation
  works on 'QueryArr () r' rather than 'QueryArr a r'.

  totalLinesByEmployeeIn :: QueryArr String (String, Int)
  totalLinesByEmployeeIn = proc country -> do
    aggregate (PP.p2 (groupBy, sumA)) linesByEmployeeIn -< country

  Couldn't match type `String' with `()'
     Expected type: QueryArr () (String, Int)
       Actual type: QueryArr String (String, Int)
-}



{- # Exercises

  Easy ones to start with:

  1. Project employee and department from the employees table
  2. Restrict the output table to the work which was done on
     Tuesday.
  3. Find all days that each employee was working at their home
     location.

  And now some harder ones:

  3. Calculate the total lines of code output by each employee
     (across all days and locations).
  4. Calculate the total lines of code output on each day
     (across all employees and locations).
  5. Find the maximum number of lines written at each location
     (using the maxA aggregator).
  6. Find the total lines of code output by each employee
     whilst they were working at their home location.
-}
