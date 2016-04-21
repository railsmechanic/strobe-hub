module App (main) where

import Effects exposing (Effects, Never)
import Html exposing (Html)
import StartApp

import State
import Types exposing (..)
import View

app : App Model
app =
  StartApp.start
    { init = (State.initialState, Effects.none)
    , update = State.update
    , view = View.root
    , inputs = [ incomingActions
               , receiverStatusActions
               , zoneStatusActions
               , sourceProgressActions
               , sourceChangeActions
               , volumeChangeActions
               , playListAdditionActions
               , libraryRegistrationActions
               , libraryResponseActions
               ]
    }

main : Signal Html
main =
  app.html


port tasks : Signal (Task Never ())
port tasks =
  app.tasks


port initialState : Signal Model

incomingActions : Signal Action
incomingActions =
  Signal.map InitialState initialState


port receiverStatus : Signal ( String, ReceiverStatusEvent )

receiverStatusActions : Signal Action
receiverStatusActions =
  Signal.map ReceiverStatus receiverStatus


port zoneStatus : Signal ( String, ZoneStatusEvent )

zoneStatusActions : Signal Action
zoneStatusActions =
  Signal.map ZoneStatus zoneStatus


port sourceProgress : Signal SourceProgressEvent

sourceProgressActions : Signal Action
sourceProgressActions =
  Signal.map SourceProgress sourceProgress


port sourceChange : Signal SourceChangeEvent

sourceChangeActions : Signal Action
sourceChangeActions =
  Signal.map SourceChange sourceChange


port volumeChange : Signal VolumeChangeEvent

volumeChangeActions : Signal Action
volumeChangeActions =
  Signal.map VolumeChange volumeChange


port playlistAddition : Signal PlaylistEntry

playListAdditionActions : Signal Action
playListAdditionActions =
  Signal.map PlayListAddition playlistAddition


port libraryRegistration : Signal Library.Node

libraryRegistrationActions : Signal Action
libraryRegistrationActions =
  Signal.map LibraryRegistration libraryRegistration


port libraryResponse : Signal Library.FolderResponse


libraryResponseActions : Signal Action
libraryResponseActions =
  let
      translate response =
        -- log ("Translate " ++ toString(response.folder))

        Library (Library.Response response.folder)
  in
      Signal.map translate libraryResponse


volumeChangeRequestsBox : Signal.Mailbox ( String, String, Float )
volumeChangeRequestsBox =
  Signal.mailbox ( "", "", 0.0 )


port volumeChangeRequests : Signal ( String, String, Float )
port volumeChangeRequests =
  volumeChangeRequestsBox.signal


zonePlayPauseRequestsBox : Signal.Mailbox ( String, Bool )
zonePlayPauseRequestsBox =
  Signal.mailbox ( "", False )


port playPauseChanges : Signal ( String, Bool )
port playPauseChanges =
  zonePlayPauseRequestsBox.signal


playlistSkipRequestsBox : Signal.Mailbox ( String, String )
playlistSkipRequestsBox =
  Signal.mailbox ( "", "" )


port playlistSkipRequests : Signal ( String, String )
port playlistSkipRequests =
  playlistSkipRequestsBox.signal


attachReceiverRequestsBox : Signal.Mailbox ( String, String )
attachReceiverRequestsBox =
  Signal.mailbox ( "", "" )


port attachReceiverRequests : Signal ( String, String )
port attachReceiverRequests =
  attachReceiverRequestsBox.signal


port libraryRequests : Signal (String, String)
port libraryRequests =
  let
      mailbox = Library.libraryRequestsBox
  in
      mailbox.signal
