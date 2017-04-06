
module Hi(Hi(..), parseHi) where

import Data.List.Extra
import Data.Tuple.Extra
import Data.Char


data Hi = Hi
    {hiExportIdent :: [String]
    ,hiImportPackage :: [String]
    ,hiImportModule :: [String]
    ,hiImportIdent :: [String]
    } deriving Show

instance Monoid Hi where
    mempty = Hi [] [] [] []
    mappend (Hi x1 x2 x3 x4) (Hi y1 y2 y3 y4) = Hi (x1++y1) (x2++y2) (x3++y3) (x4++y4)

parseHi :: String -> Hi
parseHi = foldMap f . repeatedly (\(x:xs) -> first (x:) $ span (" " `isPrefixOf`) xs) .  lines
    where
        f (x:xs) | Just x <- stripPrefix "exports:" x = mempty{hiExportIdent=concatMap words $ x:xs}
        f (x:xs) | Just x <- stripPrefix "module dependencies:" x = mempty{hiImportModule=concatMap words $ x:xs}
        f (x:xs) | Just x <- stripPrefix "package dependencies:" x = mempty{hiImportPackage=map cleanupPackage $ concatMap words $ x:xs}
        f (x:xs) | Just x <- stripPrefix "import " x = case xs of
            [] -> mempty{hiImportIdent = [words x !! 1]}
            _:xs -> mempty{hiImportIdent = map (\y -> (words x !! 1) ++ "." ++ fst (word1 y)) xs}
        f _ = mempty

        -- "old-locale-1.0.0.7@old-locale-1.0.0.7-KGBP1BSKxH5GCm0LnZP04j" -> "old-locale"
        cleanupPackage = intercalate "-" . takeWhile (any isAlpha) . wordsBy (== '-') . takeWhile (/= '@')