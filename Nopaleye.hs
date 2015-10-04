{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE Arrows #-}

module Nopaleye where

import qualified Control.Foldl as Foldl
import qualified Data.Profunctor as P
import qualified Data.Profunctor.Product as PP
import qualified Control.Applicative as A
import qualified Control.Arrow as Arr
import qualified Data.Map as Map
import qualified Data.Monoid as M
import           Data.Monoid ((<>))
import qualified Data.List as L

type Query a = QueryArr () a
type QueryArr a b = Arr.Kleisli [] a b

restrict :: QueryArr Bool ()
restrict = Arr.Kleisli (\b -> if b then [()] else [])

data Aggregator a b =
  forall r r'. Ord r => Aggregator (a -> r) (Foldl.Fold a r') ((r, r') -> b)

instance P.Profunctor Aggregator where
  dimap f g (Aggregator group fold finish) =
    Aggregator (P.lmap f group) (P.lmap f fold) (fmap g finish)

instance Functor (Aggregator a) where
  fmap f (Aggregator group fold finish) = Aggregator group fold (fmap f finish)

instance A.Applicative (Aggregator a) where
  pure x = Aggregator (A.pure ()) (A.pure ()) (A.pure x)
  Aggregator groupf foldf finishf <*> Aggregator groupx foldx finishx =
    Aggregator (groupf Arr.&&& groupx)
               ((,) A.<$> foldf A.<*> foldx)
               (\((rf, rx), (r'f, r'x)) -> finishf (rf, r'f) (finishx (rx, r'x)))

instance PP.ProductProfunctor Aggregator where
  empty  = PP.defaultEmpty
  (***!) = PP.defaultProfunctorProduct

aggregate :: Aggregator a b -> Query a -> Query b
aggregate (Aggregator group fold finish) =
  Arr.Kleisli
  . const
  . map finish
  . Map.toList
  . fmap (Foldl.fold fold)
  . Map.fromListWith (++)
  . map (group Arr.&&& (:[]))
  . ($ ())
  . Arr.runKleisli

groupBy :: Ord a => Aggregator a a
groupBy = Aggregator id (A.pure ()) fst

fromFoldl :: Foldl.Fold a b -> Aggregator a b
fromFoldl foldl = Aggregator (A.pure ()) foldl snd

sumA :: Num a => Aggregator a a
sumA = fromFoldl Foldl.sum

maxA :: Ord a => Aggregator a (Maybe a)
maxA = fromFoldl Foldl.maximum

countA :: Aggregator a Int
countA = fromFoldl Foldl.length

test =
  (runQuery
   . orderBy (desc fst <> asc snd)
   . aggregate (PP.p2 (countA, groupBy)))
  (Arr.arr (\(x, y, _) -> (x, y)) Arr.<<< speakers)

data Order a = Order (a -> a -> Ordering)

asc :: Ord b => (a -> b) -> Order a
asc f = Order (\x y -> compare (f x) (f y))

desc :: Ord b => (a -> b) -> Order a
desc f = Order (\x y -> compare (f y) (f x))

orderBy :: Order a -> Query a -> Query a
orderBy (Order compare') = listQuery .L.sortBy compare' . runQuery

instance M.Monoid (Order a) where
  mempty = Order (const (const EQ))
  Order f `mappend` Order g = Order (\x y -> f x y `M.mappend` g x y)

keepWhen :: (a -> Bool) -> QueryArr a a
keepWhen p = Arr.Kleisli (\a -> if p a then [a] else [])

listQuery :: [a] -> Query a
listQuery = Arr.Kleisli . const

runQuery :: Query a -> [a]
runQuery = ($ ()) . Arr.runKleisli

speakers = listQuery [ ("Andres", "DE", "Thursday")
                     , ("Simon PJ", "UK", "Thursday")
                     , ("Alfredo", "IT", "Thursday")
                     , ("Jasper", "BE", "Thursday")
                     , ("Vladimir", "RU", "Thursday")
                     , ("Francesco", "IT", "Thursday")
                     , ("Matthew", "UK", "Thursday")
                     , ("Ivan", "ES", "Thursday")
                     , ("Johan", "SE", "Thursday")
                     , ("Martijn", "NL", "Thursday")
                     , ("Lennart", "SE", "Thursday")
                     , ("Phillip", "DE", "Thursday")
                     , ("Bodil", "NO", "Thursday")
                     , ("San", "BE", "Thursday")
                     , ("Simon M", "UK", "Friday")
                     , ("Neil", "UK", "Friday")
                     , ("Alp", "FR", "Friday")
                     , ("Mietek", "PL", "Friday")
                     , ("Lars", "DE", "Friday")
                     , ("Miles", "UK", "Friday")
                     , ("Gershom", "US", "Friday")
                     , ("Tom", "UK", "Friday")
                     , ("Nicolas", "UK", "Friday")
                     , ("Luite", "NL", "Friday") ]

directions = listQuery [ ("DE", "North")
                       , ("UK", "North")
                       , ("IT", "South")
                       , ("BE", "North")
                       , ("ES", "South")
                       , ("NL", "North")
                       , ("RU", "East")
                       , ("SE", "North")
                       , ("US", "West")
                       , ("PL", "East")
                       , ("NO", "North")
                       , ("FR", "North") ]

q :: Query (String, String)
q = proc () -> do
  (speaker, country, _) <- speakers  -< ()
  (country', direction) <- directions -< ()
  restrict -< country == country'
  Arr.returnA -< (speaker, direction)
  
qcount :: [(Int, String)]
qcount = (runQuery
          . orderBy (desc fst <> asc snd)
          . aggregate (PP.p2 (countA, groupBy)))
         q
