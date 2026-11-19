{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators     #-}
{-# LANGUAGE DeriveGeneric     #-}

module Verity.Server (app) where

import           Data.Text (Text)
import           Servant
import Data.Aeson (toJSON, FromJSON, ToJSON)
import GHC.Generics (Generic)

data PromptRequest = PromptRequest { prompt :: Text }
    deriving (Generic)
instance FromJSON PromptRequest

data PromptResponse = PromptResponse { response :: Text }
    deriving (Generic)
instance ToJSON PromptResponse


type VerityAPI  
  =     "health" :> Get '[JSON] Text 
  :<|> "prompt" :> ReqBody '[JSON] PromptRequest :> Post '[JSON] PromptResponse

handleHealth :: Handler Text
handleHealth = return "OK"

handlePrompt :: PromptRequest -> Handler PromptResponse
handlePrompt (PromptRequest prompt) = return $ PromptResponse ("You said: " <> prompt)

app :: Application
app = serve (Proxy :: Proxy VerityAPI) (handleHealth :<|> handlePrompt)
