module Main where
--stabinfo program.  See README.txt for documentation.
--This program relies on the module System.Console.GetOpt, which is not part of
--the standard library.  Fortunately, it's included with ghc.
import Data.List
import System.IO
import System.Environment
import Tools
import ExactLogs
import ClassifierCore
import AnswerExtraction
import System.Console.GetOpt

data Flag = Size SizeOpt | AllInfo deriving Eq

options :: [OptDescr Flag]
options =
	[ Option "s"	["small"]	(NoArg (Size Small))
		"turns on optimizations for small numbers"
	, Option "v"	["vsmall"]	(NoArg (Size VSmall))
		"turns on optimizations for very small numbers"
	, Option "2"	["pow2"]	(NoArg (Size Pow2))
		"indicates to check 2^n rather than n"
	, Option "a"	["allinfo"]	(NoArg AllInfo)
		"give all info, not just eventual info"
	]

main :: IO ()
main = do l <- getArgs
	  let (opts,args,_)=getOpt Permute options l
	  let sz = if Size Pow2 `elem` opts then Pow2
		else if Size VSmall `elem` opts then VSmall
		else if Size Small `elem` opts then Small
		else Large
	  let fn = if AllInfo `elem` opts then print . allinfo sz
		else print . evinfo sz
	  if null args then hPutStrLn stderr "Argument required"
	  else (fn . read . head) args
