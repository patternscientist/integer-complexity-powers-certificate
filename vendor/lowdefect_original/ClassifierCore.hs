module ClassifierCore where
--ClassifierCore module.  This module contains the main engine of the program,
--both the building up of low-defect polynomials and the truncating them down,
--to produce good coverings.  Note that everything here assumes a step size of
--delta(2)=2-3*log_3(2)=0.107..., so precomputations have been made based on
--this assumption.
import Data.List
import Tools
import ExactLogs
import TernaryFamilies
import Complexity

td2 :: [TFam]
--Represents the set T_delta(2); T_d(2)={1,2,3} as 3<1/(3^((1-d(2))/3)-1)+1<4
td2 = [MFam 1 1 [], MFam 2 2 [], MFam 3 3 []]

d2 :: Log
--The number delta(2).
d2 = frInt 2 .- 3 ..* llogi 2

nomult :: [TFam]
--Some low-defect pairs you don't want to waste your time multiplying by.
nomult = [MFam 1 1 [], MFam 3 3 []]

dLT :: [[TFam]]
--dLT !! k will consist of a good covering of k*delta(2).
--This is implemented as a list rather than a function for memoization purposes.
dLT = [(rm3dup . canonub . concatMap (cutoff k))
	(candidates !!! k) | k<-[(0::Integer) ..]]

candidates :: [[TFam]]
--candidates !! k will consist of a covering set for k*delta(2).
--This is implemented as a list rather than a function for memoization purposes.
--NOTE: The k=2 case here makes use of the fact that the step size is delta(2);
--see below.
candidates = []:[MFam 3 3 []]:[canonub (td2 ++
	[AFam (cpx !!! c) c f | f<-dLT!!!(k-1),
	c<-filter ischunk (sd2k (toInteger k))]
	++ if k==2 then [] --this line makes use of the fact that the step size
	--is delta(2); ordinarily, here would go something telling us to
	--multiply together three elements of our good covering of B_alpha.
	--However, B_delta(2) consists solely of the number 3, which, as has
	--been noted elsewhere, one need not multiply by.
	else concat [[ftimes f1 f2 | f1 <- filter (`notElem` nomult) (dLT!!! i),
	f2 <- filter (`notElem` nomult) (dLT !!! (k+1-i))] | i<-[2..k-1]]) |
	k<-[(2::Integer)..]]

cutoff :: Integer -> TFam -> [TFam]
--cutoff k f takes the TFam f and truncates it to k*delta(2).  Note that because
--we are using strict inequalities, we need to handle constant expressions
--slightly differently than other expressions.
cutoff k f@(MFam _ c []) = if 9^k*(lc f)^3 > 3^(bcp f) * 8^k then [f] else []
cutoff k f = if 9^k*(lc f)^3 >= 3^(bcp f) * 8^k then [f] else
		(concatMap (cutoff k) . concatMap (flip submaxantikeys f))
		[0 .. maxsub k f]

maxsub :: Integer -> TFam -> Integer
--maxsub k f determines the largest K such that 3^K needs to be substituted into
--the minimal variables of f while truncating f to k*delta(2).
--If f is a constant, the function returns -1, indicating that nothing needs to
--be substituted.
maxsub k (MFam _ _ []) = -1
maxsub k f = indefbinsearchhigh (\n -> compare expbd
	((applyfamilydminl n f)^3) ) 0 - 1
	where expbd=8^k * 3^^(bcp f-2*k)

submaxantikeys :: Integer -> TFam -> [TFam]
--Takes the given number n and the given TFam and returns all TFam's resulting
--from substituting 3^n into a minimal variable of that TFam.  The function's
--name comes from the fact that the minimal variables are the ones with the
--maximal antikeys.
submaxantikeys n (AFam bc1 c1 (MFam bc2 c2 [])) = 
	[MFam (bc1+bc2+3*n) (c2*3^n+c1) []]
submaxantikeys n (AFam bc c f) = map (AFam bc c) (submaxantikeys n f)
submaxantikeys n (MFam bc c l) = (map (consolidate . MFam bc c) .
	concatMaponce (submaxantikeys n)) l

sd2k :: Integer -> [Integer]
--Given k>=1, returns a list of integers such that every natural number b
--satisfying ||b||<k*delta(2)+3log_3(2) is among them.
--NOTE: Causes error if called with k=0.
sd2k k = [1 .. sd2ki k]

sd2ki :: Integer -> Integer
--Helper function for sd2k.  Given k, returns the largest b satisfying
--	b<k*delta(2)+3log_3(2).
--(Note that k=1 is a special case because 1 is the only value of k for which
--the right-hand side is an integer.  However, this function shouldn't really be
--called with k=1 in the first place.)
--NOTE: Causes error if called with k=0.
sd2ki 1 = 1
sd2ki k = cpxexp (2*k-ceillogBase 3 (2^(3*(k-1))))

isinsomet :: Integer -> Bool
--Given a number, determines if it's in T_alpha for some 0<alpha<1.
isinsomet n = case (cpxtree2 !!! n) of
		One -> True
		Times _ _ -> False
		Plus 1 _ -> True
		Plus a _ -> False
