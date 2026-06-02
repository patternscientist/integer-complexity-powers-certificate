module Main where

import System.Environment (getArgs)
import System.CPUTime (getCPUTime)
import System.IO (hPutStrLn, stderr)
import Data.List (intercalate, group, sort)
import ClassifierCore (dLT)
import TernaryFamilies (TFam(..), bcp, rank)
import Tools ((!!!))

famJson :: TFam -> String
famJson f =
  "{"
    ++ "\"base_complexity\":" ++ show (bcp f)
    ++ ",\"degree\":" ++ show (rank f)
    ++ ",\"tree\":" ++ treeJson f
    ++ "}"

treeJson :: TFam -> String
treeJson (AFam bc c f) =
  "{"
    ++ "\"kind\":\"affine\""
    ++ ",\"edge_complexity\":" ++ show bc
    ++ ",\"constant\":" ++ show c
    ++ ",\"child\":" ++ treeJson f
    ++ "}"
treeJson (MFam bc c fs) =
  "{"
    ++ "\"kind\":\"product\""
    ++ ",\"vertex_complexity\":" ++ show bc
    ++ ",\"constant\":" ++ show c
    ++ ",\"children\":[" ++ intercalate "," (map treeJson fs) ++ "]"
    ++ "}"

coveringJson :: Integer -> [TFam] -> String
coveringJson n covering =
  "{"
    ++ "\"source\":\"Altman lowdefect dLT\""
    ++ ",\"threshold_multiple\":" ++ show n
    ++ ",\"pair_count\":" ++ show (length covering)
    ++ ",\"pairs\":[" ++ intercalate "," (map famJson covering) ++ "]"
    ++ "}"

histJson :: [Integer] -> String
histJson degrees =
  "{" ++ intercalate "," (map entry grouped) ++ "}"
  where grouped = map (\xs -> (head xs, length xs)) (group (sort degrees))
        entry (d,c) = "\"" ++ show d ++ "\":" ++ show c

metricsJson :: Integer -> [TFam] -> FilePath -> Integer -> String
metricsJson n covering out elapsedMs =
  "{"
    ++ "\"threshold_multiple\":" ++ show n
    ++ ",\"output\":" ++ show out
    ++ ",\"elapsed_ms\":" ++ show elapsedMs
    ++ ",\"pair_count\":" ++ show (length covering)
    ++ ",\"max_degree\":" ++ show (maximum (0 : map rank covering))
    ++ ",\"degree_histogram\":" ++ histJson (map rank covering)
    ++ "}"

elapsedMsSince :: Integer -> IO Integer
elapsedMsSince start = do
  now <- getCPUTime
  pure ((now - start) `div` 1000000000)

writeOne :: FilePath -> Integer -> IO ()
writeOne prefix n = do
  start <- getCPUTime
  let covering = dLT !!! n
  let out = prefix ++ show n ++ ".json"
  writeFile out (coveringJson n covering ++ "\n")
  elapsed <- elapsedMsSince start
  putStrLn (metricsJson n covering out elapsed)
  hPutStrLn stderr ("wrote " ++ out)

main :: IO ()
main = do
  args <- getArgs
  case args of
    [startText,endText,prefix] -> mapM_ (writeOne prefix) [read startText .. read endText]
    _ -> error "usage: export_range start end output-prefix"
