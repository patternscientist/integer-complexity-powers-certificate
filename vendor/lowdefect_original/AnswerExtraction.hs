module AnswerExtraction where
--AnswerExtraction module.  Having built up good coverings with ClassifierCore,
--this module contains functions for extracting information from them --
--stabilization lengths, stable defects, etc.
import Data.List
import Data.Maybe
import Tools
import Complexity
import ClassifierCore
import TernaryFamilies

data SizeOpt = Large | Small | VSmall | Pow2 deriving Eq
--Many of the functions in this module take an argument which is a SizeOpt.
--This is a parameter that allows the function to be tuned to various
--situations.  Let me explain briefly the meaning of each of these "sizes":
--LARGE: Large enough that computing ||n|| is slow.  When dealing with a size
--Large number, the program conducts an indefinite search until some 3^k*n is
--3-represented, rather than cutting it off at some point.  (L=infinity)
--SMALL: Small enough that computing ||n|| is not so slow.  When dealing with a
--size Small number, the program first computes ||n||, then uses that to bound
--how far it has to search.  (L=||n||)
--VSMALL: Small enough that not only is computing ||n|| fast, but so is
--computing ||3^k*n|| for k<=K(n).  Size VSmall is the same as Small when just
--computing stabilization information, but for more detailed information,
--whereas Small will search until n is 3-represented, VSmall will just combine
--the stabilization information with computations of ||3^k*n|| for k<=K(n).
--POW2: A size representing a power of 2 -- in this case, the input should be
--the exponent k, NOT the number n=2^k!  Yes, this is confusing.
--WARNING: IT IS EASY TO GET THIS MIXED UP.
--In this mode, the program makes use of the obvious upper bound ||n||<=2k to
--cut off the search.  (L=2k).

leadinfof :: TFam -> Integer -> [(Integer,Integer)]
--Given a TFam f and a number n, computes the list of pairs (k,l) where
--a. the augmented version of f 3-represents 3^k*n with complexity l (see
--exprepcpx in TernaryFamilies.hs), and
--b. k+v_3(n) <= v3bd(f)
--It then prunes from this list some elements which are not minimal under the
--partial ordering (k_1,l_1)<=(k_2,l_2) iff k_1<=k_2 and l_1-3*k_1<=l_2-3*k_2
--NOTE: This function returns a larger set of pairs than is necessary for what
--it will be used for, but doing it this way made it easier to write.
leadinfof f n = (sort .
	nubBy eqdefmes . sortBy cmpdefmes . nubBy eqfst . sort . catMaybes)
	(zipWith (\x -> fmap (\y -> (x,y))) [0 .. bound]
	((map (exprepcpx f) .genericTake (max 1 (bound+1-k)) . iterate (*3)) n))
	where (k,m)=splitbybase 3 n
	      bound=v3bd f

leadinfol :: Integer -> [TFam] -> [(Integer,Integer)]
--Given a number n and a list of TFams, concatenates together all the
--leadinfof f n, then takes the set of elements which is minimal under the
--partial order (k_1,l_1)<=(k_2,l_2) iff k_1<=k_2 and l_1-3*k_1<=l_2-3*k_2
leadinfol n = sort . map (\(x,y)->(x,y+3*x)) . minl2d . map (\(x,y)->(x,y-3*x)) 		. concatMap (flip leadinfof n)

leadinfo :: SizeOpt -> Integer -> [(Integer,Integer)]
--Given a number n, determine all pairs (k,l) for which
--a. k=0 or 3^k*n is a leader
--b. l=||3^k*n||
--NOTE: Takes a size option; see comments at top.  This is the only function
--that distinguishes between the Small and VSmall sizes, aside from some ones
--that return errors when called with VSmall because they shouldn't be.
--NOTE: This function is currently written to do some unnecessary recomputation,
--unfortunately.  But changing this would require quite a bit of work.
leadinfo VSmall n = (nubBy eqdefmes . map (\x->(x,cpx!!!(n*3^x))))
	[0 .. stablen Small n]
leadinfo sz n = maybe
	(nubBy eqdefmes (evDefault sz n:leadinfol no (dLT!!!searchbd sz n)))
	(leadinfol no . (dLT!!!)) (finaldetection sz n)
		where no = if sz /= Pow2 then n else 2^n

searchbd :: SizeOpt -> Integer -> Integer
--Given a SizeOpt and an integer n, determines the largest k*delta(2) to check.
--If the size is Large, there's no bound; this shouldn't be called!
--Note that some precomputations have been done in the case where the size is
--Pow2.
searchbd Large _ = error "error: searchbd called with Large size"
searchbd Small n = 1 + (dft n .- frInt 1) `fldiv` d2
searchbd VSmall n = 1 + (dft n .- frInt 1) `fldiv` d2
searchbd Pow2 n = if n==0 then 10 else max 0 (n-9)

allinfo :: SizeOpt -> Integer -> (Integer,[(Integer,Integer)])
--Given a number n, determines the complexity of ||3^k*n|| for all k, and
--returns an object representing this information.  The first element of the
--pair is ||n||.  The format of the second element of the pair is documented
--under dropinfo.
allinfo sz n = let li = leadinfo sz n in (snd (head li),
	((\l->zipWith subtrsnd (tail l) l) . map (\(x,y)->(x,y-3*x))) li)

finaldetection :: SizeOpt -> Integer -> Maybe Integer
--Given a number n, finds the smallest k such that delta(n)<k*delta(2), or
--returns Nothing if the search terminates before finding one.
finaldetection Large n = fmap (1+)
	(genFindIndex (representedlstrict n) (tail dLT))
finaldetection VSmall n = error "error: finaldetection called with VSmall size"
finaldetection sz n = let searchl = genericTake (searchbd sz n) (tail dLT)
			  no = if sz /= Pow2 then n else 2^n in
				(fmap (1+).genFindIndex (representedlstrict no))
				searchl

firstdetection :: SizeOpt -> Integer -> Maybe Integer
--Given a number n, finds the smallest k such that delta_st(n)<k*delta(2), or
--returns Nothing if the search terminates before finding one.
firstdetection Large n = fmap (1+) (genFindIndex (representedl n) (tail dLT))
firstdetection sz n = let searchl = genericTake (searchbd sz n) (tail dLT)
			  no = if sz /= Pow2 then n else 2^n in
				(fmap (1+). genFindIndex (representedl no))
				searchl

evinfoDirect :: SizeOpt -> Integer -> (Integer, Integer)
--Given a number n, returns (k,l) where k is the stabilization length of n
--and l=||3^k*n||
--NOTE: This function is currently written to do some unnecessary recomputation,
--unfortunately.  But changing this would require quite a bit of work.
evinfoDirect sz n = maybe (evDefault sz n) (fromJust . repcpxl no . (dLT!!!))
	(firstdetection sz n)
		where no = if sz /= Pow2 then n else 2^n

evinfo :: SizeOpt -> Integer -> (Integer, Integer)
--Given a number n, return its stabilization length and stable complexity.
evinfo sz n = (k,l-3*k) where (k,l)=evinfoDirect sz n

evDefault :: SizeOpt -> Integer -> (Integer,Integer)
--Given a SizeOpt and a number n, returns the default value for evinfo to be
--used if the search terminates before anything is found.
evDefault Large _ = error "error: evDefault called with Large size"
evDefault Small n = (0,cpx!!!n)
evDefault VSmall n = (0,cpx!!!n)
evDefault Pow2 n = (0,2*n)

stablen :: SizeOpt -> Integer -> Integer
--Given a number n, returns the stabilization length of n.
stablen sz = fst . evinfo sz

stabcpx :: SizeOpt -> Integer -> Integer
--Given a number n, returns the stable complexity of n.
stabcpx sz = snd . evinfo sz

stable :: SizeOpt -> Integer -> Bool
--Given a number n, determines whether or not it is stable.
stable sz = (==0) . stablen sz

dropinfo :: SizeOpt -> Integer -> [(Integer,Integer)]
--Returns the "drop information" for n.  This is the list of pairs (k,d) where:
--a. k>0
--b. 3^k*n is a leader
--b. d = delta(3^(k-1)*n) - delta(3^k*n)
dropinfo sz = snd . allinfo sz

subtrsnd :: (Num a) => (b,a) -> (b,a) -> (b,a)
--Helper function for allinfo; self-explanatory from the code.
subtrsnd (x,y) (z,w) = (x,w-y)

droplocs :: SizeOpt -> Integer -> [Integer]
--Given a number n, return a list of those k>0 such that 3^k*n is a leader.
droplocs sz = map fst . tail . leadinfo sz

newdlt :: Integer -> [TFam]
--Lists the elements of dLT !! n that aren't in dLT !! (n-1); useful for
--testing.  It lists them sorted by defect.
newdlt n = (dLTsorted !!! n \\ dLT !!! (n-1))

dLTsorted :: [[TFam]]
--Like dLT (see ClassifierCore.hs), except the elements have been sorted by
--defect.
dLTsorted = map (sortBy cmpub) dLT

pow2check :: Integer -> Bool
--Given n, determines whether any 3^k*2^(n+9) is 3-represented by any element of
--dLT !! n.
pow2check n = maybe True (const False) (pow2info n)

pow2info :: Integer -> Maybe (Integer, Integer)
--Given n, determines whether any 3^k*2^(n+9) is 3-represented by any element of
--dLT !! n; if not, returns Nothing.  If so, returns (k,l), where l is the
--complexity used.  If there are multiple possibilities, returns one of them in
--accordance with the rules for repcpxl (which see, in TernaryFamilies.hs).
pow2info n = repcpxl (2^(n+9)) (dLT !!! n)
