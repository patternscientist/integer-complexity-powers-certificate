module TernaryFamilies where
--TernaryFamilies module.  "Ternary family" was an old name for low-defect
--polynomials.  The first part of this file contains the TFam data type and
--tools for working with it.  The second part of this file contains functions
--for extracting information about what a given low-defect polynomial
--represents.
import Data.Ratio
import Data.List
import Tools
import ExactLogs

--PART 1: TOOLS

data TFam = AFam Integer Integer TFam |
	MFam Integer Integer [TFam] deriving (Eq, Ord)
--First, we have the TFam data type.  A TFam represents a low-defect pair,
--although as mentioned in the "Implementation notes" appendix, what it actually
--represents is not a low-defect pair, but rather a low-defect expression,
--together with sufficient information to determine an upper bound on its
--complexity (and hence to determine a low-defect pair).
--I probably would have used low-defect trees if I'd thought of them before I
--wrote this, but since I hadn't, the format is, though close, a little more
--unwieldy.
--
--AFam bc c f represents an expression of the form f*x+c, where x is a variable
--not appearing in f.  bc here should be an upper bound on the complexity of c.
--Thus, if f has complexity at most bc', f*x+c has complexity at most bc'+bc.
--(Essentially, bc here is an upper bound on the complexity of an edge label.)
--
--MFam bc c l represents the product (with disjoint variables) of the constant c
--and the contents of the list l.  (Note that l may be empty; this is how
--constants are represented.)  As above, bc here should be an upper bound on the
--complexity of c, UNLESS c=1 and l is nonempty; in that case, we should have
--bc=0, since we do not actually want to spend 1 performing a multiplication by
--1.  (If l is empty, of course, we cannot do this.)  So, aside from in this
--case, bc is essentially an upper bound on the complexity of a vertex label.
--
--Note that althought TFam derives Ord, this order is NOT meaningful.  This is
--done purely for the purpose of giving each low-defect expression a canonical
--form.

canon :: TFam -> TFam
--Gives a "canonical form" for the given ternary family, allowing for
--equivalence testing.  Note that while this function only makes use of
--commutativity and associativity, the constraints on the functions for building
--TFams mean that one only ever gets reduced low-defect expressions.  Hence,
--ignoring the issue of the upper bounds on the complexities of the edge labels
--and the vertex labels (since those are not ignored), this really is
--equivalence.
canon (AFam bc c f) = AFam bc c (canon f)
canon (MFam bc c l) = MFam bc c ((sort . map canon) l)

canonub :: [TFam] -> [TFam]
--Given a list of TFams, gives a canonical form for that list, by taking the
--canonical form for each one, sorting the result, and deleting duplicates.
canonub = nub . sort . map canon

bcp :: TFam -> Integer
--Given a TFam, computes its base complexity (the upper bound on the complexity of the low-defect expression it represents) by summing up all the bc's.
bcp (AFam bc _ f) = bc + bcp f
bcp (MFam bc _ l)  = bc + sum (map bcp l)

lc :: TFam -> Integer
--Given a TFam, computes the leading coefficient of the polynomial it
--evaluates to.
lc (AFam _ _ f) = lc f
lc (MFam _ c l) = c * product (map lc l)

termct :: TFam -> Integer
--Given a TFam, computes the number of terms in the polynomial it evaluates to.
termct (AFam _ _ f) = termct f + 1
termct (MFam _ _ l) = product (map termct l)

maxcoeff :: TFam -> Integer
--Given a TFam, computes the largest coefficient in the polynomial it evaluates
--to.
maxcoeff (AFam _ c f) = max c (maxcoeff f)
maxcoeff (MFam _ c l) = c * product (map maxcoeff l)

maxnlcoeff :: TFam -> Integer
--Given a TFam, computes the largest non-leading coefficient in the polynomial
--it evaluates to.  If the input is a constant, this function returns 0.
maxnlcoeff (AFam _ c f) = max c (maxnlcoeff f)
maxnlcoeff (MFam _ c l) = let l2 = map maxnlcoeff l in
	(maxw0 . map (c*) . zipWith (*) l2 . applyexcept product) l2

ub :: TFam -> Log
--Returns the defect of the input TFam.  (Or, if you prefer, of the low-defect
--pair it represents.)  The name "ub" is because it's an upper bound on the
--defects of the numbers it 3-represents.
ub f = frInt (bcp f) .- 3 ..* llogi (lc f)

ftimes :: TFam -> TFam -> TFam
--Multiplies the two input TFams.
ftimes f1@(AFam _ _ _) f2@(AFam _ _ _) = MFam 0 1 [f1,f2]
ftimes (MFam bc1 c1 l1) (MFam bc2 c2 l2) = MFam (bc1+bc2) (c1*c2) (l1++l2)
ftimes (MFam bc c l) f@(AFam _ _ _) = MFam bc c (f:l)
ftimes f@(AFam _ _ _) (MFam bc c l) = MFam bc c (f:l)

cmpub :: TFam -> TFam -> Ordering
--Compares two TFams by their defect.
--cmpub f g = compare (ub f) (ub g)
cmpub f g = compare (3^(bcp f) * (lc g)^3) (3^(bcp g) * (lc f)^3)

supersedes :: TFam -> TFam -> Bool
--Redundancy checker.  If supersedes f g returns true, this means that
--"f supersedes g", i.e., every number that can be 3-represented by g can be
--3-represented by f, and, moreover, with no greater (upper bound on the)
--complexity; that is to say, it's checking whether f makes g redundant as a
--low-defect PAIR, not just as a low-defect POLYNOMIAL.
--Note that this function is not designed to catch all redundancies, just some!
--Specifically, this function can only catch redundancies coming from low-defect
--trees that look the same as f, but with some of the vertex coefficients
--multiplied by powers of 3.
--NOTE: This function assumes the inputs are in canonical form!
supersedes (AFam _ _ _) (MFam _ _ _) = False
supersedes (MFam _ _ _) (AFam _ _ _) = False
supersedes (AFam bc1 c1 f1) (AFam bc2 c2 f2) = c1 == c2 && bc1 <= bc2 &&
	supersedes f1 f2
supersedes (MFam bc1 c1 l1) (MFam bc2 c2 l2) = let (q,r) = c2 `divMod` c1 in
	r==0 && let (k,m) = splitbybase 3 q in m == 1 && bc1+3*k <= bc2 &&
	length l1 == length l2 &&
	any (and . zipWith supersedes l1) (permutations l2)

supersedesstrict :: TFam -> TFam -> Bool
--Like supersedes, except returns false if both inputs are the same.
supersedesstrict f g = f /= g && supersedes f g

consolidate :: TFam -> TFam
--This is a helper function for turning a TFam with an invalid form, due to
--having stacked multiplications, into a TFam with a valid form.  Most of the
--time these will not be produced, and hence this function will not be
--necessary, but it is used in the function submaxantikeys in ClassifierCore.hs.
consolidate (AFam bc c f) = AFam bc c (consolidate f)
consolidate (MFam bc c l) = foldl ftimes (MFam bc c []) (map consolidate l)

rank :: TFam -> Integer
--Given a TFam, returns the degree of the polynomial it yields.
rank (AFam _ _ f) = 1 + rank f
rank (MFam _ _ l) = sum (map rank l)

minlvars :: TFam -> Integer
--Given a TFam, returns the number of minimal variables (leaves in the
--corresponding low-defect tree).
--NOTE: This function assumes the input is in canonical form!
minlvars (MFam _ _ l) = sum (map minlvars l)
minlvars (AFam _ _ (MFam _ _ [])) = 1
minlvars (AFam _ _ f) = minlvars f

applyfamily :: TFam -> [Integer] -> Integer
--Given a TFam f of degree r and numbers k_1,...,k_r, this function computes
--the value f(3^k_1,...,3^k_r).
--NOTE: In order to properly use this function, we need to know what order the
--variables are in!  The rule is as follows:
--If f is a product of families f_1,...,f_s, the variables of f_1 come before
--those of f_2, etc, come before those of f_s.
--If f is of the form g*x+c, the variable x comes FIRST, then the variables of
--g.
applyfamily (AFam _ c f) (n:ns) = (applyfamily f ns)*3^n+c
applyfamily (AFam _ c f) [] = error "too few args to family"
applyfamily (MFam _ c l) ns = c*product (zipWith applyfamily l
	(splitbylength (map rank l) ns))

expapplyfamily :: TFam -> [Integer] -> Integer
--Given a TFam f of degree r and numbers k_0,...,k_r, this function computes
--the value 3^k_0 * f(3^k_1,...,3^k_r).
--See applyfamily regarding the order of the variables k_1,...,k_r.
expapplyfamily f (n:ns) = 3^n * applyfamily f ns

applyfamilycpx :: TFam -> [Integer] -> (Integer, Integer)
--Given a TFam f of degree r and numbers k_1,...,k_r, this function computes
--the value f(3^k_1,...,3^k_r), and also returns the complexity used
--(i.e., bcp(f)+3(k_1+...+k_r)
--See applyfamily regarding the order of the variables k_1,...,k_r.
applyfamilycpx f l = (applyfamily f l, bcp f + 3 * sum l)

expapplyfamilycpx :: TFam -> [Integer] -> (Integer, Integer)
--Given a TFam f of degree r and numbers k_1,...,k_r, this function computes
--the value 3^k_0 * f(3^k_1,...,3^k_r), and also returns the complexity used
--(i.e., bcp(f)+3(k_0+...+k_r)
--See applyfamily regarding the order of the variables k_1,...,k_r.
expapplyfamilycpx f l = (expapplyfamily f l, bcp f + 3 * sum l)

applyfamilyd :: TFam -> [Integer] -> Rational
--Given a TFam f of degree r and numbers k_1,...,k_r, this function computes
--the value g(3^k_1,...,3^k_r), where g is the reverse polynomial of f.
--See applyfamily regarding the order of the variables k_1,...,k_r.
--(Recall that delta_{f,C}(x)=C-3log_3(g(x)).)
applyfamilyd (AFam _ c f) l@(n:ns) = (applyfamilyd f ns)+(c%1)*3^^(-sum l)
applyfamilyd (AFam _ c f) [] = error "too few args to family"
applyfamilyd (MFam _ c l) ns = (c%1)*product (zipWith applyfamilyd l
	(splitbylength (map rank l) ns))

applyfamilydminl :: Integer -> TFam -> Rational
--Given a TFam f and a numbers k, this function computes the value
--g(3^k_1,...,3^k_r), where g is the reverse polynomial of f, and k_i is equal
--to k if x_i is a minimal variable, and 0 otherwise.
--See applyfamily regarding the order of the variables k_1,...,k_r.
--NOTE: This function assumes the input is in canonical form!
applyfamilydminl k (MFam _ c l) = (c%1)*product (map (applyfamilydminl k) l)
applyfamilydminl k (AFam _ c1 (MFam _ c2 [])) = (c2%1) + (c1%1)*3^^(-k)
applyfamilydminl k (AFam _ c f) = applyfamilydminl k f+(c%1)*3^^(-k*minlvars f)

sumcoeffs :: TFam -> Integer
--Given a TFam, returns the sum of the coefficients of the polynomial it yields.
--This is the same as plugging in all 0s to applyfamily f.
sumcoeffs (AFam _ c f) = c + sumcoeffs f
sumcoeffs (MFam _ c l) = c * product (map sumcoeffs l)

prodcoeffs :: TFam -> Integer
--Given a TFam, returns the product of the nonzero coefficients of the
--polynomial it yields.
prodcoeffs (AFam _ c f) = c * prodcoeffs f
prodcoeffs (MFam _ c l) = let counts = map termct l in
	c^product counts *
	product (zipWith (^) (map prodcoeffs l) (applyexcept product counts))

v3bd :: TFam -> Integer
--Given a TFam f, returns a number k such that any n which is 3-represented by
--f has v_3(n)<=k.
v3bd f = termct f + (floorlogBase 3 . prodcoeffs) f - 1

shownobc :: TFam -> String
--Print a string representing the low-defect expression that f represents.
--Variables will be represented as "3^_", because we plug in powers of 3 to
--them; because each variable only appears once, i.e. all appearing variables
--are independent of one another, it is safe to represent each just as "_" (or
--rather, "3^_").
shownobc (AFam _ c f) = "(" ++ shownobc f ++ ")3^_+" ++ show c
shownobc (MFam bc c l) = (if bc==0 then "" else show c)
			 ++ concatMap (\s -> "(" ++ shownobc s ++ ")") l

showtfam :: TFam -> String
--Print a string representing the TFam f; it consists of a string representing
--the low-defect expression represented by f, followed by the base complexity
--of f.
--NOTE that while this tells you the low-defect pair that f represents, it is
--not enough information to reconstruct f itself, as it only tells you bcp(f)
--and not the value of the individual bc's.
showtfam f = shownobc f ++ " : " ++ show (bcp f)

instance Show TFam where
--We'll define TFam to be an instance of Show, using showtfam.
	show = showtfam

rm3dup = rm3dup1
--Given a list of TFams, remove redundancies.  Several versions of this function
--have been included, depending on what tradeoffs one wants to make; using a
--more thorough check can slow things down, but using a less thorough check can
--also slow things down when one has to check through more TFams later.  rm3dup1
--is the version actually used in computations so far.
--NOTE: This function may assume that the TFams in the list are in canonical
--form!

rm3dup0 :: [TFam] -> [TFam]
--The least thorough possible version -- don't delete redundancies at all.
rm3dup0 = id

rm3dup1 :: [TFam] -> [TFam]
--Remove redundancies, using supersedes to check for them.
--NOTE: This function assumes the TFams are in canonical form!
rm3dup1 l = filter (\g->not (any (flip supersedesstrict g) l)) l

rm3dup2 :: [TFam] -> [TFam]
--Remove redundancies, using gensupersedes to check for them.
--gensupersedes is a stricter (slower) redundancy checker than supersedes; see
--below.
--NOTE: This function assumes the TFams are in canonical form!
rm3dup2 l = filter (\g->not (any (flip gensupersedesstrict g) l)) l

gensupersedes :: TFam -> TFam -> Bool
--Like supersedes, except slower/stricter; can detect more redundancies. (For
--instance, this function can detect a redundancy where one TFam has lower
--degree than the other, which supersedes cannot.)
--This function is capable of checking to see whether certain truncations of f
--(the first argument) yield g (the second argument).  However, re-reading the
--code, it appears to me I didn't cover all cases as I thought I did; I'm pretty
--sure I intended to write something even stricter.  Nonetheless, it will at
--least only return True in case of an actual redundancy.  It's also not used
--in the current version of the program.
gensupersedes f@(AFam _ _ _) (MFam bc c []) =
	exprepresentsbetter f c bc
gensupersedes (AFam _ _ _) (MFam _ _ _) = False
gensupersedes (AFam bc1 c1 f1) (AFam bc2 c2 f2) = c1 == c2 && bc1 <= bc2 &&
	gensupersedes f1 f2
gensupersedes (MFam _ _ _) (AFam _ _ _) = False
gensupersedes f1@(MFam bc1 c1 l1) (MFam bc2 c2 l2) =
	length l2 <= length l1 &&
	any (\(lp,lr)->all (uncurry gensupersedes) lp &&
	exprepresentsbetter (foldl ftimes (MFam bc1 c1 []) lr) c2 bc2)
	(map (\x->(zip x l2,drop (length l2) x)) (permutations l1))

gensupersedesstrict :: TFam -> TFam -> Bool
--Like gensupersedes, except returns false if both inputs are the same.
gensupersedesstrict f g = f /= g && gensupersedes f g

--PART 2: EXTRACTION

repcpx :: TFam -> Integer -> Maybe Integer
--Does f 3-represent n?  If not, return Nothing.
--If yes, return the complexity it yields; i.e., if n=f(3^k_1,...,3^k_r),
--return bcp(f)+3(k_1+...+k_r).  If there are multiple ways of 3-representing n,
--return the lowest possible complexity.
repcpx f n = (lookup n . sortBy cmpsnd . map (applyfamilycpx f))
	(sumbetween (rank f)
	(ceillogBase 3 (n `updiv` (maxcoeff f * termct f)))
	(floorlogBase 3 (n `div` lc f)))

exprepcpx :: TFam -> Integer -> Maybe Integer
--Does the augmented polynomial hat(f) 3-represent n?  If not, return Nothing.
--If yes, return the complexity it yields; i.e., if n=hat(f)(3^k_0,...,3^k_r),
--return bcp(f)+3(k_0+...+k_r).  If there are multiple ways of 3-representing n,
--return the lowest possible complexity.
exprepcpx f n = (lookup n . sortBy cmpsnd . map (expapplyfamilycpx f))
	(sumbetween (rank f+1)
	(ceillogBase 3 (n `updiv` (maxcoeff f * termct f)))
	(floorlogBase 3 (n `div` lc f)))

represents :: TFam -> Integer -> Bool
--Does f 3-represent n?
represents f n = maybe False (const True) (repcpx f n)

expandedrepresents :: TFam -> Integer -> Bool
--Does the augmented polynomial hat(f) 3-represent n?
expandedrepresents f n = maybe False (const True) (exprepcpx f n)

repspow3info :: TFam -> Integer -> Maybe (Integer, Integer)
--Does f 3-represent any 3^k*n?  If so, return k and the complexity used (see
--repcpx); if not, return Nothing.
--If the same 3^k*n is represented in multiple ways, use the one with the lowest
--complexity.
--If multiple 3^k*n are represented, each with complexity l_k, use the one that
--minimizes l_k-3*k; that is to say, we are choosing the inputs k_1,...,k_r to
--f so as to minimize delta_{f,C}(k_1,...,k_r).  If this is not enough to break
--ties, further break ties by using the lowest k possible.
repspow3info f n = minimumBy cmpjustdefmes (fmap (\x->(0,x)) (exprepcpx f n) :
	let (k,m)=splitbybase 3 n
	    bound=v3bd f
	in zipWith (\x -> fmap (\y -> (x,y))) [1 .. bound]
	((map (repcpx f) . genericTake (bound-k) . tail . iterate (*3)) n))

representstimes3 :: TFam -> Integer -> Bool
--Does f 3-represent any 3^k*n?
representstimes3 f n = maybe False (const True) (repspow3info f n)

representedl :: Integer -> [TFam] -> Bool
--Given n and a list of TFams, do any of them 3-represent any 3^k*n?
representedl n = maybe False (const True) . repcpxl n

repcpxl :: Integer -> [TFam] -> Maybe (Integer,Integer)
--Given n and a list of TFams, do any of them 3-represent any 3^k*n?
--If not, return Nothing.
--If so, return k and the complexity used (see repcpx).
--If multiple 3^k*n are represented, each with complexity l_k, use the one that
--minimizes l_k-3*k.  If this is not enough to break ties, further break ties by
--using the lowest k possible.
repcpxl n = minimumBy cmpjustdefmes . map (flip repspow3info n)

representedlstrict :: Integer -> [TFam] -> Bool
--Given n and a list of TFams, do any of their augmented versions 3-represent n?
representedlstrict n = maybe False (const True) . repcpxlstrict n

repcpxlstrict :: Integer -> [TFam] -> Maybe Integer
--Given n and a list of TFams, do any of their augmented versions 3-represent n?
--If not, return Nothing.  If so, return the complexity used (see exprepcpx).
--If multiple of them 3-represent n, return the lowest complexity used.
repcpxlstrict n = minimumBy nothinglarge . map (flip exprepcpx n)

representsbetter :: TFam -> Integer -> Integer -> Bool
--Does f 3-represent n using complexity at most k?  (Returns False if n does not
--3-represent n at all.)
representsbetter f n k = maybe False (<=k) (repcpx f n)

exprepresentsbetter :: TFam -> Integer -> Integer -> Bool
--Does the augmented version of f represent n using complexity at most k?
--(Returns false if hat(f) does not 3-represent n at all.)
exprepresentsbetter f n k = maybe False (<=k) (exprepcpx f n)

defmes :: (Integer, Integer) -> Integer
--"Defect measure".  If (k,l) is a pair such that ||3^k*n||<=l, then l-3k is an
--upper bound on ||n||_st, and l-3k-3log_3(n) is an upper bound on delta(n).
defmes (k,l) = l-3*k

cmpdefmes :: (Integer, Integer) -> (Integer, Integer) -> Ordering
--Given two pairs, order them by defmes; if this is a tie, order them by first
--coordinate.
cmpdefmes p q = compare (defmes p,fst p) (defmes q,fst q)

cmpjustdefmes :: Maybe (Integer,Integer) -> Maybe (Integer,Integer) -> Ordering
--Given two Maybe pairs, if they are pairs, order them using cmpdefmes; Nothing
--will be considered larger than any actual pair.
cmpjustdefmes Nothing Nothing = EQ
cmpjustdefmes Nothing (Just _) = GT
cmpjustdefmes (Just _) Nothing = LT
cmpjustdefmes (Just x) (Just y) = cmpdefmes x y

eqdefmes :: (Integer, Integer) -> (Integer, Integer) -> Bool
--Checks if two pairs have the same defmes.
eqdefmes p q = defmes p == defmes q
