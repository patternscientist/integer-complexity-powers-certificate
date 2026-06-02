module Tools where
--Tools module.  Includes generic helpful tools that are used throughout the
--program, as well as the definition of the class used for the logarithm type
--used in the program.
import Data.List
import Data.Maybe
import Data.Ratio

infixl 6 .+, .-
infixr 7 .*, ..*
infix 7 `fldiv`, `cediv`
infixl 7 `updiv`
infixl 9 !!!

(!!!) = genericIndex
--Throughout the program, I've made a point of using Integers rather than Ints.
--as such, for convenience, I've defined (!!!) to be an alias for genericIndex.

gcdFixed :: (Integral a) => a -> a -> a
--A gcd function.  Haskell includes this in the standard prelude, but for some
--reason it defines gcd 0 0 to be an error, rather than the mathematically
--correct value of 0.
gcdFixed 0 0 = 0
gcdFixed x y = gcd x y

floorroot :: (Integral a) => a -> a -> a
--Returns the floor of the kth root of n (exactly).  Does so by using binary
--search.
floorroot k n | n<0 = error "floorroot: negative argument"
floorroot k n = binsearchlow (\m -> compare (m^k) n) 0 n

ceilroot :: (Integral a) => a -> a -> a
--Returns the ceiling of the kth root of n (exactly).  Does so by using binary
--search.
ceilroot k n | n<0 = error "ceilroot: negative argument"
ceilroot k n = binsearchhigh (\m -> compare (m^k) n) 0 n

floorsqrt = floorroot 2
--Returns the floor of the square root of its input (exactly).
ceilsqrt = ceilroot 2
--Returns the ceiling of the square root of its input (exactly).

binsearchlow :: (Integral a) => (a -> Ordering) -> a -> a -> a
--Binary search; takes two numbers low and high, and a nondecreasing function p
--which takes numbers and returns LT, EQ, or GT.  It finds the largest number
--returning EQ or LT.
--Note: The function p is assumed to be nondecreasing.
--Note: This function assumes such a number exists.  Otherwise it will not
--function properly.
--Note: This function is written assuming no overflows occur.
binsearchlow p low high | high == low = low
binsearchlow p low high = let mid = (low + high) `updiv` 2 in case p mid of
					GT -> binsearchlow p low (mid-1)
			      		LT -> binsearchlow p mid high
					EQ -> binsearchlow p mid high

binsearchhigh :: (Integral a) => (a -> Ordering) -> a -> a -> a
--Binary search; takes two numbers low and high, and a nondecreasing function p
--which takes numbers and returns LT, EQ, or GT.  It finds the smallest number
--returning EQ or GT.
--Note: This function assumes such a number exists.  Otherwise it will not
--function properly.
--Note: This function is written assuming no overflows occur.
binsearchhigh p low high | high == low = low
binsearchhigh p low high = let mid = (low + high) `div` 2 in case p mid of
					LT -> binsearchhigh p (mid+1) high
					GT -> binsearchhigh p low mid
					EQ -> binsearchhigh p low mid

indefbinsearchhigh :: (Integral a) => (a -> Ordering) -> a -> a
--Indefinite binary search; takes a lower bound n and a nondecreasing function p
--which takes a number and returns LT, EQ, or GT.  It finds the smallest number
--at least n which returns EQ or GT.  It's "binary" in that it tries binary
--search on intervals, doubling the size of the interval each time.
--Note: If no such number exists that is at least the bound, this function will
--not return.
--Note: This function is written assuming no overflows occur.
indefbinsearchhigh p n = indefbinhighassist p n n

indefbinhighassist :: (Integral a) => (a -> Ordering) -> a -> a -> a
--Helper function for ifdefbinsearchhigh; takes a function p (as above) and
--a lower and upper bound, then runs a binary search inbetween the given bounds.
--If it doesn't find anything, because even the upper bound isn't high enough,
--it will instead try again on a new interval twice the size.
indefbinhighassist p low high = if p high == LT then
	indefbinhighassist p (high+1) (3*high-2*low+2) else
	binsearchhigh p low high

iskthpow :: (Integral a) => a -> a -> Bool
--Given k and n, determines if n is a perfect k'th power.
iskthpow k n = (floorroot k n ^ k) == n

bestpow :: (Integral a) => a -> a
--Given n, finds the largest k such that n is a perfect k'th power.  If n=1, it
--instead returns 0 (which is the maximum element of the natural numbers ordered
--by divisibilty).
bestpow 1 = 0
bestpow n = (fromJust. find (flip iskthpow n) . reverse) [1 .. floorlogBase 2 n]

powsplit :: (Integral a) => a -> (a,a)
--Given n, returns a pair (k,m) where n=m^k and k is as large as possible.
--If n=1, returns (0,1); the reason for k=0 is as explained above; the choice
--m=1 is just for simplicity.
powsplit 1 = (0,1)
powsplit n = (fromJust . find (\(k,m)->(m^k)==n) . map (\k->(k,floorroot k n)))
	(reverse [1 .. floorlogBase 2 n])

floorlogBase :: (Integral a) => a -> a -> a
--Given a base b and a number n, returns floor(log_b(n)).
--This function assumes b>1 and n>0.
floorlogBase b 0 = -1
floorlogBase b n = 1 + floorlogBase b (n `div` b)

ceillogBase :: (Integral a) => a -> a -> a
--Given a base b and a number n, returns ceil(log_b(n)).
--This function assumes b>1 and n>0.
ceillogBase b 1 = 0
ceillogBase b n = 1 + ceillogBase b (n `updiv` b)

floorlogBaseRat :: Rational -> Rational -> Integer
--Given a base b and a number n, returns floor(log_b(n)).
--This function assumes b>1 and n>0.
floorlogBaseRat b n | 1<=n && n<b = 0
		    | n>b = 1 + floorlogBaseRat b (n / b)
		    | otherwise = floorlogBaseRat b (n * b) - 1

ceillogBaseRat :: Rational -> Rational -> Integer
--Given a base b and a number n, returns ceil(log_b(n)).
--This function assumes b>1 and n>0.
ceillogBaseRat b n | 1<n && n<=b = 1
		   | n>b = 1 + ceillogBaseRat b (n / b)
		   | otherwise = ceillogBaseRat b (n * b) - 1

updiv :: (Integral a) => a -> a -> a
--Given integers a and b, returns ceil(a/b).  Useful companion to div, which
--returns floor(a/b).
updiv a b = let (q,r)=a `divMod` b in if r==0 then q else q+1

ispow :: (Integral a) => a -> Bool
--Determines whether its input is or is not a perfect power.
ispow = (>1) . bestpow

splitbybase :: (Integral a) => a -> a -> (a, a)
--Takes a number b and a number n and returns a pair (k,m) where n=b^k*m, where
--m is not divisible by b.  Obviously, this is most useful when b is a prime.
splitbybase b n = let (q,r) = n `divMod` b in if r/=0 then (0,n)
			else let (k1,n1)=splitbybase b q in (k1+1,n1)

splitRat :: Integer -> Rational -> (Integer, Rational)
--Given a prime p and rational number r, returns a pair (k,q), where r=p^k*q
--and v_p(q)=0.
--Note: Does not necessarily return sensible results if p is not prime.
splitRat p r = (k-l, m%c)
	where (n,d)=(numerator r, denominator r)
	      (k,m)=splitbybase p n
	      (l,c)=splitbybase p d

powsplitRat :: Rational -> (Integer, Rational)
--Given q>0, returns a pair (k,r) where n=r^k and k is as large as possible.
--If q=1, returns (0,1), as with powsplit.
powsplitRat q = (k, floorroot k n % floorroot k d)
	where (n,d) = (numerator q, denominator q)
	      k = gcdFixed (bestpow n) (bestpow d)

cmpsnd :: (Ord a) => (b,a) -> (b,a) -> Ordering
--Given two pairs, compares their second elements.
cmpsnd x y = compare (snd x) (snd y)

cmpfst :: (Ord a) => (a,b) -> (a,b) -> Ordering
--Given two pairs, compares their first elements.
cmpfst x y = compare (fst x) (fst y)

cmpjustsnd :: (Ord a) => Maybe (b,a) -> Maybe (b,a) -> Ordering
--Given two Maybe pairs, compares their second elements if they exist;
--Nothing is considered larger than any actual pair.
cmpjustsnd Nothing Nothing = EQ
cmpjustsnd Nothing (Just _) = GT
cmpjustsnd (Just _) Nothing = LT
cmpjustsnd (Just x) (Just y) = cmpsnd x y

cmpsumsnd :: (Real a) => (b,[a]) -> (b,[a]) -> Ordering
--Given two pairs, each of whose second elements is a list of numbers, compares
--the sums of these lists.
cmpsumsnd (x,l) (y,m) = compare (sum l) (sum m)

maxw0 :: (Real a) => [a] -> a
--Like maximum, except that on an empty list it returns 0 instead of an error.
maxw0 = foldl max 0

applyexcept :: ([a]->b) -> [a] -> [b]
--Given a function f and a list [a_0,...,a_n], returns
--[f(a_1,...,a_n),f(a_0,a_2,...,a_n),f(a_0,...,a_{n-1})]
applyexcept f l = map f (zipWith (++)
	((init . inits) l) ((map tail . init .tails) l))

maponce :: (a -> a) -> [a] -> [[a]]
--Given a function f and a list l, returns a list of lists l', where each l' is
--the same as l, except that one of its elements has had f applied to it.
maponce f [] = []
maponce f (x:xs) = ((f x:xs):map (x:) (maponce f xs))

concatMaponce :: (a -> [a]) -> [a] -> [[a]]
--Given a function f with list output and a list l, returns a list of lists l',
--where each l' is the same as l, except that one of its elements has had f
--applied to it and the resulting list spliced into l at the position of the
--element it's replacing.
concatMaponce f [] = []
concatMaponce f (x:xs) = map (:xs) (f x) ++ map (x:) (concatMaponce f xs)

splitbylength :: [Integer] -> [a] -> [[a]]
--Given integers n_1,...,n_k>0 with sum n, and list a of length n, splits that
--list into lists of length n_1,...,n_k.
splitbylength [] [] = []
splitbylength [] l = error "sum too small"
splitbylength (n:ns) as = if n > genericLength as then error "sum too large"
	else genericTake n as : splitbylength ns (tail as)

eqsnd :: (Eq b) => (a,b) -> (a,b) -> Bool
--Compares if the second elements of two pairs are equal.
eqsnd p q = snd p == snd q

eqfst :: (Eq a) => (a,b) -> (a,b) -> Bool
--Compares if the first elements of two pairs are equal.
eqfst p q = fst p == fst q

sumle :: Integer -> Integer -> [[Integer]]
--Given n and k, returns all lists of n whole numbers with sum at most k.
sumle 0 k = [[]]
sumle n k = concatMap (\i->map (i:) (sumle (n-1) (k-i))) [0 .. k]

sumbetween :: Integer -> Integer -> Integer -> [[Integer]]
--Given n, a, and b, returns all lists of n whole numbers with sum at least a
--and at most b.
--This function assumes a<=b.
sumbetween 0 a b = if a<=0 then [[]] else []
sumbetween n a b = concatMap (\i->map (i:) (sumbetween (n-1) (a-i) (b-i)))
	[0 .. b]

nothinglarge :: (Ord a) => Maybe a -> Maybe a -> Ordering
--Compares two Maybes by comparing their contents, with Nothing being considered
--the largest possible value.
nothinglarge Nothing Nothing = EQ
nothinglarge (Just _) Nothing = LT
nothinglarge Nothing (Just _) = GT
nothinglarge (Just x) (Just y) = compare x y

listonlines :: (Show a) => [a] -> String
--For printing a list on lines.  Takes a list of showables and returns a string
--with each one on a separate line.
listonlines = concatMap ((++"\n") . show)

genguarFindIndex :: (a -> Bool) -> [a] -> Integer
--Like genFindIndex below, except that it doesn't use Maybes; if it fails to
--find what it's looking for, it just causes an error.  For use in situations
--where finding is guaranteed.
genguarFindIndex p [] = error "genguarFindIndex: failed to find"
genguarFindIndex p (x:xs) | p x = 0
			  | otherwise = 1 + genguarFindIndex p xs

genFindIndex :: (a -> Bool) -> [a] -> Maybe Integer
--A version of findIndex that uses Integers instead of ints.
genFindIndex p [] = Nothing
genFindIndex p (x:xs) | p x = Just 0
		      | otherwise = fmap (1+) (genFindIndex p xs)

gt2d :: (Eq a, Ord a) => (a,a) -> (a,a) -> Bool
--Given two points in SxS (S a toset), determine if the first is greater than
--the second under the standard partial ordering.
gt2d (x1,y1) (x2,y2) = (x1 > x2 && y1 >= y2) || (x1 >= x2 && y1 > y2)

minl2d :: (Eq a, Ord a) => [(a,a)] -> [(a,a)]
--Given a list of elements of SxS (S a toset), finds the minimal ones under the
--standard partial ordering.
minl2d l = nub (filter (\x-> all (not . gt2d x) l) l)

class (Ord a) => Loggy a where
--Loggy: A type a satisfying Loggy a is one that can represent values of the
--form p+q*log_3(r), where p,q,r are rational numbers.

	(.+) :: a -> a -> a --addition
	(.*) :: Rational -> a -> a --multiplication by a rational
	fldiv :: a -> a -> Integer --floor of ratio
	llog :: Rational -> a --take log_3(q)
	frRat :: Rational -> a --turns a rational into an a
	frRat q = q .* (frInt 1)
	cediv :: a -> a -> Integer --ceiling of ratio
	x `cediv` y = if k ..* y == x then k else k+1 where k = x `fldiv` y
	
	(..*) :: (Integral b) => b -> a -> a --multiplication by an integer
	x ..* y = (fromIntegral x % 1) .* y

	mnegate :: a -> a --negation
	mnegate x = (-1) ..* x

	(.-) :: a -> a -> a --subtraction
	x .- y = x .+ mnegate y

	frInt :: (Integral b) => b -> a --turns an integer into an a
	frInt x = frRat (fromIntegral x % 1)

	llogi :: (Integral b) => b -> a --take log_3(n)
	llogi = llog . fromIntegral

	nonneg :: a -> Bool --is it nonnegative?
	nonneg = (>=0) . floor1
	
	floor1 :: a -> Integer --take the floor
	ceil1 :: a -> Integer --take the ceiling
	floor1 x = fldiv x (frInt 1)
	ceil1 x = cediv x (frInt 1)

instance Loggy Float where
--Define Floats to be Loggy in the obvious way, in case one wants to try the
--program with floating-point arithmetic instead of exact arithmetic.
	(.+) = (+)
	frRat = fromRational
	x .* y = (fromRational x) * y
	llog = logBase 3.0 . fromRational
	frInt = fromIntegral
	x `fldiv` y = floor (x/y)
	x `cediv` y = ceiling (x/y)
	floor1 = floor
	ceil1 = ceiling
	nonneg x = x >= 0
	mnegate = negate
	(.-) = (-)
	x ..* y = (fromIntegral x) * y

instance Loggy Double where
--Define Doubles to be Loggy in the obvious way, in case one wants to try the
--program with floating-point arithmetic instead of exact arithmetic.
	(.+) = (+)
	frRat = fromRational
	x .* y = (fromRational x) * y
	llog = logBase 3.0 . fromRational
	frInt = fromIntegral
	x `fldiv` y = floor (x/y)
	x `cediv` y = ceiling (x/y)
	floor1 = floor
	ceil1 = ceiling
	nonneg x = x >= 0
	mnegate = negate
	(.-) = (-)
	x ..* y = (fromIntegral x) * y
