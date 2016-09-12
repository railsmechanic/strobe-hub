module Main exposing (main)

import Html.App as Html
import Msg exposing (Msg)
import Window
import Root
import Root.State
import Root.View
import Ports


main =
    Html.program
        { init = init
        , update = Root.State.update
        , view = Root.View.root
        , subscriptions = subscriptions
        }


init : ( Root.Model, Cmd Msg )
init =
    ( Root.State.initialState, Cmd.none )


subscriptions : Root.Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.broadcasterStateActions
        , Ports.receiverStatusActions
        , Ports.channelStatusActions
        , Ports.sourceProgressActions
        , Ports.sourceChangeActions
        , Ports.volumeChangeActions
        , Ports.playListAdditionActions
        , Ports.libraryRegistrationActions
        , Ports.libraryResponseActions
        , Ports.windowStartupActions
        , Ports.channelAdditionActions
        , Ports.channelRenameActions
        , Ports.receiverRenameActions
        , Ports.scrollTopActions
        , viewportWidth
        ]


viewportWidth : Sub Msg
viewportWidth =
    Window.resizes (\size -> Msg.BrowserViewport size.width)
