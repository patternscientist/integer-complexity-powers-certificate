module ExactLogs where
--ExactLogs module.  Contains the Log type which is used throughout to represent
--exact logarithms.  (More specifically, numbers of the form q+r*log_3(n), where
--q and r are rational and n is a natural number.)  Log is an instance of Loggy,
--so this module largely contains implementations of the methods of the Loggy
--class.
import Data.Ratio
import Tools

base :: Integer
--This is the fixed base used for all the logarithms.  For our purposes,
--obviously, it is 3.  More generally, to make use of the Log type, the base
--should be a prime number.
base = 3

--A Log is a number of the form p+q*log_b(r) where p,q,r rational and b=base.
data Log = ConstrLog Rational Rational Rational deriving Eq
--			p	q	r		
--ConstrLog p q r will represent the number p+q*log_b(r).  To allow Log to
--derive Eq, we will make the following requirements: 
-- r>=1
-- v_b(r)=0
-- r is not a perfect power
-- if r=1, then q=0
--Because of the assumption that b is prime, and these
--requirements, this is a canonical form, and we can safely derive Eq.

mklog :: Rational -> Rational -> Rational -> Log
--Given p, q, r, returns p+q*log_b(r).
mklog p 0 r = ConstrLog p 0 1
mklog p q r = ConstrLog (p+q*(n%1)) (signum (r1-1) * (k%1) * q) r2
			where (k,r1) = powsplitRat r0
			      (n,r0) = splitRat base r
			      r2 = if r1>=1 then r1 else recip r1

instance Ord Log where
--Since we know how to tell if a Log is nonnegative, we can use this to define
--the ordering.
	x <= y = nonneg (y .- x)

instance Loggy Log where
--Here, we implement the methods of the Loggy class.

	frRat r = ConstrLog r (0%1) (1%1)
	--Converts a rational number to a Log.

	--Given r, return log_b(r).
	llog r | r>0 = mklog 0 (1%1) r
	       | otherwise = error "ExactLogs: llog requires positive argument"

	--addition
	(ConstrLog p1 q1 r1) .+ (ConstrLog p2 q2 r2) = 
		mklog (p1+p2) (1%(d1*d2)) (r1^^(n1*d2)*r2^^(n2*d1))
		where (n1,d1) = (numerator q1, denominator q1)
		      (n2,d2) = (numerator q2, denominator q2)

	--negation
	mnegate (ConstrLog p q r) = ConstrLog (-p) (-q) r
	--Note that we don't need to invoke mklog here, since r is unchanged.

	--multiply a Rational by a Log
	a .* (ConstrLog p q r) = ConstrLog (a*p) (a*q) r
	--Again, as r is unchanged, we don't need to invoke mklog.

	--finds floor(a/b)
	(ConstrLog p1 q1 r1) `fldiv` (ConstrLog p2 q2 r2) =
		floorlogBaseRat (r2^^(m2*d1*c1*d2) * (base%1)^^(n2*d1*c1*c2))
		(r1^^(m1*d1*d2*c2) * (base%1)^^(n1*c1*d2*c2))
		where (n1,d1)=(numerator p1, denominator p1)
		      (n2,d2)=(numerator p2, denominator p2)
		      (m1,c1)=(numerator q1, denominator q1)
		      (m2,c2)=(numerator q2, denominator q2)

	--finds ceil(a/b)
	(ConstrLog p1 q1 r1) `cediv` (ConstrLog p2 q2 r2) =
		ceillogBaseRat (r2^^(m2*d1*c1*d2) * (base%1)^^(n2*d1*c1*c2))
		(r1^^(m1*d1*d2*c2) * (base%1)^^(n1*c1*d2*c2))
		where (n1,d1)=(numerator p1, denominator p1)
		      (n2,d2)=(numerator p2, denominator p2)
		      (m1,c1)=(numerator q1, denominator q1)
		      (m2,c2)=(numerator q2, denominator q2)

instance Show Log where
--Log is also an instance of Show.  Here we define how to print out a Log.  It's
--a little messy, but it makes them look nice.
	show (ConstrLog p q r) = empz ((if p/=0 then showRat p else "") ++
		(if q>0 && p/=0 then "+" else "") ++ if r/=1 then (
		(if q==1 then "" else if q== -1 then "-" else (showRat q ++
		"*")) ++ "log_" ++ show base ++ "(" ++ showRat r ++ ")" )
		else "")

showRat :: Rational -> String
--Turns a rational number into a string, in a way somewhat more natural than the
--builtin way.  It prints a rational number as "$n/$d", where $n is the
--numerator and $d is the denominator... unless $d=1, in which case it just
--prints "$n".
showRat q | d/= 1 = show n ++ "/" ++ show d
	  | otherwise = show n
	where (n,d)=(numerator q, denominator q)

empz :: String -> String
--Turn the empty string into 0 and leave other strings alone.  Useful when
--dealing with string representations of numbers.
empz "" = "0"
empz s = s
