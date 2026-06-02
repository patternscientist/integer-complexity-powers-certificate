module Main where

import System.Environment (getArgs)
import Data.List (find, intercalate)
import ClassifierCore (dLT)
import TernaryFamilies
  ( TFam
  , applyfamily
  , bcp
  , lc
  , maxcoeff
  , rank
  , showtfam
  , termct
  )
import Tools (ceillogBase, floorlogBase, sumbetween, updiv, (!!!))

targets :: [(Integer, Integer, Integer, Integer)]
targets = [(m, b, 2^m - b, 2*m - 2) | m <- [49..56], b <- [1,6,8,9]]

pow3 :: Integer -> Integer
pow3 = (3^)

expApply :: TFam -> [Integer] -> Integer
expApply f (e:ks) = pow3 e * applyfamily f ks
expApply _ [] = error "expApply: missing augmentation exponent"

expComplexity :: TFam -> [Integer] -> Integer
expComplexity f args = bcp f + 3 * sum args

repAtMost :: TFam -> Integer -> Integer -> Maybe ([Integer], Integer)
repAtMost f n bound
  | bcp f > bound = Nothing
  | lower > upper = Nothing
  | otherwise = fmap (\args -> (args, expComplexity f args)) good
  where
    d = rank f + 1
    lower = ceillogBase 3 (n `updiv` (maxcoeff f * termct f))
    valueUpper = floorlogBase 3 (n `div` lc f)
    budgetUpper = (bound - bcp f) `div` 3
    upper = min valueUpper budgetUpper
    good = find (\args -> expApply f args == n && expComplexity f args <= bound)
      (sumbetween d lower upper)

findSurvivor :: [TFam] -> Integer -> Integer -> Maybe (Integer, TFam, [Integer], Integer)
findSurvivor covering n bound = go 0 covering
  where
    go _ [] = Nothing
    go ix (f:fs) = case repAtMost f n bound of
      Just (args, cpx) -> Just (ix, f, args, cpx)
      Nothing -> go (ix + 1) fs

caseJson :: [TFam] -> (Integer, Integer, Integer, Integer) -> String
caseJson covering (m,b,n,bound) =
  case findSurvivor covering n bound of
    Nothing ->
      "{"
        ++ "\"m\":" ++ show m
        ++ ",\"b\":" ++ show b
        ++ ",\"N\":" ++ show n
        ++ ",\"complexity_bound\":" ++ show bound
        ++ ",\"excluded\":true"
        ++ ",\"survivors\":[]"
        ++ "}"
    Just (ix, f, args, cpx) ->
      "{"
        ++ "\"m\":" ++ show m
        ++ ",\"b\":" ++ show b
        ++ ",\"N\":" ++ show n
        ++ ",\"complexity_bound\":" ++ show bound
        ++ ",\"excluded\":false"
        ++ ",\"survivors\":[{"
        ++ "\"pair_index\":" ++ show ix
        ++ ",\"e\":" ++ show (head args)
        ++ ",\"k\":[" ++ intercalate "," (map show (tail args)) ++ "]"
        ++ ",\"complexity\":" ++ show cpx
        ++ ",\"polynomial\":" ++ show (showtfam f)
        ++ "}]"
        ++ "}"

histJson :: [TFam] -> String
histJson covering =
  "{"
    ++ intercalate "," [ "\"" ++ show d ++ "\":" ++ show (countDegree d) | d <- [0..maxDegree] ]
    ++ "}"
  where
    degrees = map rank covering
    maxDegree = maximum (0 : degrees)
    countDegree d = length (filter (== d) degrees)

reportJson :: Integer -> String
reportJson threshold =
  "{"
    ++ "\"backend\":\"haskell_lowdefect_direct\""
    ++ ",\"threshold_multiple\":" ++ show threshold
    ++ ",\"pair_count\":" ++ show (length covering)
    ++ ",\"max_degree\":" ++ show maxDegree
    ++ ",\"degree_histogram\":" ++ histJson covering
    ++ ",\"target_count\":" ++ show (length cases)
    ++ ",\"all_excluded\":" ++ boolJson allExcluded
    ++ ",\"certificate_succeeded\":" ++ boolJson (threshold == 46 && allExcluded)
    ++ ",\"cases\":[" ++ intercalate "," cases ++ "]"
    ++ "}"
  where
    covering = dLT !!! threshold
    maxDegree = maximum (0 : map rank covering)
    cases = map (caseJson covering) targets
    allExcluded = all caseExcluded cases
    caseExcluded s = "\"excluded\":true" `contains` s

contains :: String -> String -> Bool
contains needle haystack = any (prefix needle) (tails haystack)

prefix :: Eq a => [a] -> [a] -> Bool
prefix [] _ = True
prefix _ [] = False
prefix (x:xs) (y:ys) = x == y && prefix xs ys

tails :: [a] -> [[a]]
tails [] = [[]]
tails xs@(_:rest) = xs : tails rest

boolJson :: Bool -> String
boolJson True = "true"
boolJson False = "false"

main :: IO ()
main = do
  args <- getArgs
  case args of
    [thresholdText] -> putStrLn (reportJson (read thresholdText))
    _ -> error "usage: verify_near_powers threshold"
