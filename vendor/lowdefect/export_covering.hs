module Main where

import System.Environment (getArgs)
import Data.List (intercalate)
import ClassifierCore (dLT)
import TernaryFamilies (TFam(..), bcp, rank)
import Tools ((!!!))

jsonString :: String -> String
jsonString s = "\"" ++ concatMap esc s ++ "\""
  where
    esc '"' = "\\\""
    esc '\\' = "\\\\"
    esc '\n' = "\\n"
    esc '\r' = "\\r"
    esc '\t' = "\\t"
    esc c = [c]

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

main :: IO ()
main = do
  args <- getArgs
  case args of
    [nText] -> do
      let n = read nText :: Integer
      let covering = dLT !!! n
      putStrLn $
        "{"
          ++ "\"source\":\"Altman lowdefect dLT\""
          ++ ",\"threshold_multiple\":" ++ show n
          ++ ",\"pair_count\":" ++ show (length covering)
          ++ ",\"pairs\":[" ++ intercalate "," (map famJson covering) ++ "]"
          ++ "}"
    _ -> error "usage: export_covering n"
