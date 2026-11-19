module Main (main) where
import           Network.Wai              (Application)
import           Network.Wai.Handler.Warp (run)
import           Verity.Config            (loadConfig)
import           Verity.Server            (app)

main :: IO ()
main = do
    config <- loadConfig
    print config
    run 8080 app
