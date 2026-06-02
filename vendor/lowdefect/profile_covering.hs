module Main where

import System.Environment (getArgs)
import System.CPUTime (getCPUTime)
import Data.List (intercalate)
import ClassifierCore (candidates, cutoff, dLT)
import TernaryFamilies (TFam(..), bcp, canonub, lc, rank, rm3dup)
import Tools ((!!!))

forceFam :: TFam -> Integer
forceFam (AFam bc c f) = bc + c + forceFam f
forceFam (MFam bc c fs) = bc + c + sum (map forceFam fs)

forceFams :: [TFam] -> Integer
forceFams fs = sum (map forceFam fs) + fromIntegral (length fs)

elapsedMsSince :: Integer -> IO Integer
elapsedMsSince start = do
  now <- getCPUTime
  pure ((now - start) `div` 1000000000)

timed :: String -> [TFam] -> IO [TFam]
timed label xs = do
  start <- getCPUTime
  let token = forceFams xs
  token `seq` pure ()
  elapsed <- elapsedMsSince start
  putStrLn $
    "{"
      ++ "\"stage\":\"" ++ label ++ "\""
      ++ ",\"elapsed_ms\":" ++ show elapsed
      ++ ",\"count\":" ++ show (length xs)
      ++ ",\"max_degree\":" ++ show (maximum (0 : map rank xs))
      ++ ",\"token\":" ++ show token
      ++ "}"
  pure xs

profileThreshold :: Integer -> IO ()
profileThreshold k = do
  if k > 0 then do
    _ <- timed ("warm_dLT_" ++ show (k - 1)) (dLT !!! (k - 1))
    pure ()
  else pure ()
  cand <- timed "candidates" (candidates !!! k)
  cut <- timed "cutoff" (concatMap (cutoff k) cand)
  canonical <- timed "canonub_after_cutoff" (canonub cut)
  reduced <- timed "rm3dup" (rm3dup canonical)
  _ <- timed "dLT_check" (dLT !!! k)
  putStrLn $
    "{"
      ++ "\"threshold\":" ++ show k
      ++ ",\"final_count\":" ++ show (length reduced)
      ++ ",\"leading_coeff_sum\":" ++ show (sum (map lc reduced))
      ++ ",\"base_complexity_sum\":" ++ show (sum (map bcp reduced))
      ++ "}"

main :: IO ()
main = do
  args <- getArgs
  case args of
    [kText] -> profileThreshold (read kText)
    _ -> error "usage: profile_covering threshold"
