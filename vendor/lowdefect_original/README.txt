Included are two programs, stabinfo.hs and lowdefect.hs, which provide
interfaces to the underlying provided functions for working with low-defect
polynomials and computing good coverings and stabilization information.  Note
that these interfaces are limited, so it may sometimes be preferable to instead
open the given code with ghci and invoke it by hand.

lowdefect.hs:

Invoke as "./lowdefect n", where n>=1 is a natural number.

The program will print out a good covering of B_{n*delta(2)}, then check whether
or not ||3^k * 2^(n+9)||=3k+2(n+9) for all k.  If not, it will print a
counterexample and its complexity.  When printing out the good covering, it will
first print out a good covering of B_{delta(2)}, then what needs to be added to
make a good covering of B_{2*delta(2)}, then what needs to be added to make a
good covering of B_{3*delta(2)}.  Within each bunch, low-defect pairs will be
sorted by defect.  For instance, running "./lowdefect 2" will yield the
following results:

<begin>
--1
3 : 3

--2
2 : 2

2^11*3^k has complexity 22+3k for all k
<end>

This means that {(3,3)} is a good covering of B_{delta(2)}, and that
{(3,3),(2,2)} is a good covering of B_{2*delta(2)}.

Low-defect expressions are printed with the variables represented as "3^_",
because we plug in powers of 3 to them; because each variable only appears
once, i.e. all appearing variables are independent of one another, it is safe
to represent each just as "_" (or rather, "3^_").

stabinfo.hs:

Invoke as "./stabinfo [options] n", where n is a natural number.  Legal options
are -s, -v, -2, and -a.

By default, the program will print an ordered pair (k,l), where k is the
stabilization length of n and l is its stable complexity.  It will do so by an
unbounded search (L=infinity).

If the -a option is passed, the program will instead print an integer followed
by a list of ordered pairs.  The first integer is the complexity of n.  The list
of ordered pairs is the list of all ordered pairs (k,l) where k>0, 3^k*n is a
leader, and l=delta(3^(k-1)*n)-delta(3^k*n).

If the -s option is passed, the program will first compute ||n|| by standard
means, and use this to bound the search (L=||n||).

The -v option is identical to the -s option unless the -a option is also passed.
In this case, not only will the program first compute ||n|| by standard means,
but after determining K(n), it will determine the rest of the information by
computing ||n||, ||3n||, ..., ||3^K(n) n|| by standard means.

If the -2 option is passed, the program will NOT compute information about the
number n, but rather about the number 2^n.  It will (assuming n>0) use the upper
bound ||2^n||<=2n to bound the search (L=2n).

Note that running "./stabinfo -2 n" can be slower than instead running
"./lowdefect n-9", because lowdefect only does a check to see if 2^n is
represented at the end, whereas stabinfo checks it at each step.

NOTE: stabinfo relies on the module System.Console.GetOpt, which is not part of
the standard library.  Fortunately, it's included with ghc.
