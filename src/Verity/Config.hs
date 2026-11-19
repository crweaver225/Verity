module Verity.Config
    ( Config (..)
    , loadConfig
    ) where

import           Data.Maybe         (fromMaybe)
import           System.Environment (lookupEnv)
import           Text.Read          (readMaybe)

-- -----------------------------------------------------------------------
-- Public config types
-- -----------------------------------------------------------------------

data Config = Config
    { cfgPort        :: Int
    , cfgModelServer :: String
    , cfgDbPath      :: String
    } deriving Show

-- -----------------------------------------------------------------------
-- Loaders
-- -----------------------------------------------------------------------

loadConfig :: IO Config
loadConfig = do
    port <- fromMaybe 8000 . (>>= readMaybe) <$> lookupEnv "PROXY_PORT"
    modelServer <- fromMaybe "http://localhost:8001" <$> lookupEnv "MODEL_SERVER_URL"
    dbPath <- fromMaybe "audit.db" <$> lookupEnv "AUDIT_DB_PATH"
    return Config
        { cfgPort = port
        , cfgModelServer = modelServer
        , cfgDbPath = dbPath
        }
