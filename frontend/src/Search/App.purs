module Search.App where

import Core.Prelude

import Component.Footer as Footer
import Component.Header as Header
import Core.Api as Api
import Core.Model (Talk, unescape)
import Data.Array as Array
import Data.Maybe (Maybe(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

type PageData =
  { q :: String
  }

data Query a = Init a

type State =
  { q :: String
  , talks :: Array Talk
  , loading :: Boolean
  }

type HTML = H.ComponentHTML Query () Aff

initialState :: PageData -> State
initialState pageData =
  { q: pageData.q
  , talks: []
  , loading: false
  }

renderTalk :: Talk -> HTML
renderTalk talk =
  HH.li
  [ class_ "flex flex-col lg:flex-row mb-6"]
  [ HH.a
    [ class_ "mr-4 flex-no-shrink Image"
    , HP.href $ "/talks/" <> talk.slug
    ]
    [ HH.img
      [ class_ "w-full h-full"
      , HP.src $ unescape talk.image
      ]
    ]
  , HH.div_
    [ HH.h3
      [ class_ "mb-1 lg:mb-3" ]
      [ HH.a
        [ class_ "Link"
        , HP.href $ "/talks/" <> talk.slug
        ]
        [ HH.text talk.name ]
      ]
    , HH.p
      [ class_ "leading-normal text-grey500"]
      [ HH.text $ unescape talk.description]
    ]
  ]

render :: State -> HTML
render state =
  HH.div_
  [ Header.render state.q
  , HH.div
    [ class_ "container py-6 px-4 xl:px-0"] $ join
    [ pure $
        if Array.length state.talks == 0
        then HH.text "Nothing found"
        else HH.ul_ $ state.talks <#> renderTalk
    , guard state.loading $> HH.div
        [ class_ "text-center"]
        [ HH.text "loading..."]
    ]
  , Footer.render
  ]

app :: PageData -> H.Component HH.HTML Query Unit Void Aff
app pageData = H.component
  { initialState: const $ initialState pageData
  , render
  , eval
  , receiver: const Nothing
  , initializer: Just $ H.action Init
  , finalizer: Nothing
  }
  where
  eval :: Query ~> H.HalogenM State Query () Void Aff
  eval (Init n) = n <$ do
    H.modify_ $ _ { loading = true }
    H.fork $ H.liftAff (Api.searchTalks pageData.q) >>= traverse_ \talks ->
      H.modify_ $ _
        { talks = talks
        , loading = false
        }
