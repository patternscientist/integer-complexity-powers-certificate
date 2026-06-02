module Complexity where
--Complexity module.  Contains functions for computing integer complexity by
--standard means and working with the results, as well as working with
--expressions made from +, 1, and *.
import Data.List
import Tools
import ExactLogs

data Expr = One | Plus Integer Integer | Times Integer Integer deriving Show
--An Expr will be a +,*,1-expression.

cpxexp :: Integer -> Integer
--Given n, returns E(n), the largest number with complexity at most n.
cpxexp 1 = 1
cpxexp n = let (k,r) = n `divMod` 3 in
			case r of
				0 -> 3^k
				1 -> 4*3^(k-1)
				2 -> 2*3^k

cpx :: [Integer]
--Integer complexity.  Originally, this was implemented as a list rather than a
--function so that it would be memoized (for speed); this is no longer
--necessary, but I don't have time to change it at the moment.  So, one gets the
--complexity of n with "cpx !! n" or with "cpx !!! n", rather than "cpx n".
--Note: cpx !!! 0 will return 1, but doing this is not actually meaningful.
cpx = [ cpxofexp (cpxtree !!! n) | n <- [(0::Integer) ..]]

cpxofexp :: Expr -> Integer
--Counts the numbers of 1s used in a given expression (its complexity).
cpxofexp One = 1
cpxofexp (Plus a b) = (cpx !!! a) + (cpx !!! b)
cpxofexp (Times a b) = (cpx !!! a) + (cpx !!! b)

cpxtree :: [Expr]
--A shortest expression for n.  This is implemented as a list rather than a
--function so that it will be memoized; use cpxtree !! n or cpxtree !!! n.
--This is done so that it prefers to use addition over multiplication, and
--prefers to use smaller (further apart) addends/factors rather than larger
--(closer together) addends/factors.
--Note: cpxtree !! 0 will return One; this is not meaningful.
cpxtree = [One, One] ++ [ minimumBy cpxprefplus
	  ([Plus a (n-a) | a<-[1 .. maxaddend n ]] ++
	  [Times a (n `div` a) | a<-[2 .. floorsqrt n ], n `mod` a == 0])
	  | n <- [(2::Integer)..]]
		where maxaddend n = binsearchlow (\m->compare
			(3*floorlogBase 3 m + 3*floorlogBase 3 (n-m))
			((cpx!!!(n-1))+1)) 1 (n`div`2)

cpxtree2 :: [Expr]
--A shortest expression for n, implemented slightly differently than cpxtree.
--This one prefers to use multiplication rather than addition, and it prefers
--non-one addends to using 1 as an addend.
cpxtree2 = [One, One] ++ [ minimumBy cpxprefplus
	   ([Times a (n `div` a) | a<-[2 .. floorsqrt n ], n `mod` a == 0] ++
	   [Plus a (n-a) | a<-[2 .. maxaddend n], ischunk a] ++
	   [Plus 1 (n-1)])
	   | n <- [(2::Integer)..]]
		where maxaddend n = binsearchlow (\m->compare
			(3*floorlogBase 3 m + 3*floorlogBase 3 (n-m))
			((cpx!!!(n-1))+1)) 1 (n`div`2)

cpxprefplus :: Expr -> Expr -> Ordering
--Compares two Exprs by their complexity; if complexities are tied, it will
--count an expression with top node + as smaller than an expression with top
--node *.  Otherwise it doesn't care.
cpxprefplus a b | cpxofexp a > cpxofexp b = GT
cpxprefplus a b | cpxofexp a < cpxofexp b = LT
cpxprefplus (Plus _ _) (Times _ _) = LT
cpxprefplus (Times _ _) (Plus _ _) = GT
cpxprefplus _ _ = EQ

ischunk :: Integer -> Bool
--Detects whether the given number is solid. "Chunk" was an old name for "solid
--number".
ischunk n = case (cpxtree !!! n) of
		One -> True
		Times _ _ -> True
		Plus _ _ -> False

isirred :: Integer -> Bool
--Determines whether the given number is m-irreducible.
isirred n = case (cpxtree2 !!! n) of
		One -> True
		Times _ _ -> False
		Plus _ _ -> True

dft :: Integer -> Log
--Computes the defect of the given number (by first computing its complexity
--by standard means).
dft n = frInt (cpx !!! n) .- 3 ..* llogi n
