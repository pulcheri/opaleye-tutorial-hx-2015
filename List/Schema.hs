module Schema where

data Employee = Employee {
    eName       :: String
  , eDepartment :: String
  , eCountry    :: String
  }
  deriving Show

data EmployeeOutput = EmployeeOutput {
    oName    :: String
  , oDay     :: String
  , oCountry :: String
  , oOutput  :: Int
  }
  deriving Show

data Manager = Manager {
    mDepartment :: String
  , mManager    :: String
  }
  deriving Show

employees :: [Employee]
employees = [ Employee "Tom"   "Back end"  "UK"
            , Employee "Neil"  "Back end"  "UK"
            , Employee "Alice" "Front end" "FR"
            , Employee "John"  "Front end" "UK"
            , Employee "Anne"  "Testing"   "FR"
            , Employee "Ryan"  "Testing"   "FR" ]

output :: [EmployeeOutput]
output = [ EmployeeOutput "Tom"   "Monday"  "UK" 530
         , EmployeeOutput "Tom"   "Tuesday" "UK" 320
         , EmployeeOutput "Neil"  "Monday"  "UK" 230
         , EmployeeOutput "Neil"  "Tuesday" "FR" 950
         , EmployeeOutput "Alice" "Monday"  "FR" 630
         , EmployeeOutput "Alice" "Tuesday" "FR" 350
         , EmployeeOutput "John"  "Monday"  "FR" 220
         , EmployeeOutput "John"  "Tuesday" "UK" 320
         , EmployeeOutput "Anne"  "Monday"  "UK" 420
         , EmployeeOutput "Anne"  "Tuesday" "FR" 690
         , EmployeeOutput "Ryan"  "Monday"  "UK" 360
         , EmployeeOutput "Ryan"  "Tuesday" "UK" 380 ]

managers :: [Manager]
managers = [ Manager "Back end"  "Tom"
           , Manager "Front end" "Alice"
           , Manager "Testing"   "Anne" ]
