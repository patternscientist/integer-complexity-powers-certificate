module Main where
--lowdefect program. See README.txt for documentation.
import Data.List
import System.IO
import System.Environment
import Tools
import ExactLogs
import ClassifierCore
import AnswerExtraction

main :: IO ()
main =	do l <- getArgs
	   if null l then hPutStrLn stderr "Argument required"
	   else (putStr . runprog . read . head) l

runprog :: Integer -> String
runprog n = let l = genericTake (n+1) dLTsorted in
	concat ["--" ++ show k ++"\n" ++ listonlines
	((l !!! k) \\ (l !!! (k-1))) ++ "\n" | k<-[1..n]] ++
	maybe ("2^" ++ show (n+9) ++ "*3^k has complexity " ++ show (2*n+18)
	++ "+3k for all k\n")
	(\(x,y)->"2^" ++ show (n+9) ++ "*3^" ++ show x ++ " has complexity " ++
	show y ++ "\n") (pow2info n)
