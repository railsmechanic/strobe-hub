module Library.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Library
import Library.State
import List.Extra
import String
import Debug
import Utils.Css


root : Library.Model -> Html Library.Msg
root model =
  div
    [ class "library" ]
    [ folder model (Library.State.currentLevel model) ]


metadata : Maybe (List Library.Metadata) -> Html Library.Msg
metadata metadata =
  case metadata of
    Nothing ->
      div [] []

    Just metadataGroups ->
      div [ class "library--node--metadata" ] (List.map (metadataGroup) metadataGroups)


metadataClick : String -> Html.Attribute Library.Msg
metadataClick action =
  let
      options =
        { preventDefault = True, stopPropagation = True }
  in
      onWithOptions "click" options ( Json.succeed (Library.ExecuteAction action) )

metadataGroup : Library.Metadata -> Html Library.Msg
metadataGroup group =
  let
      makeLink link =
        let
            attrs = case link.action of
              Nothing ->
                [ class "library--no-action" ]
              Just action ->
                [ class "library--click-action", (metadataClick action) ]
        in
            (a attrs [ text link.title ])
      links =
        List.map makeLink group
  in
      div [ class "library--node--metadata-group" ] links


node : Library.Model -> Library.Folder -> Library.Node -> Html Library.Msg
node library folder node =
  let
    isActive =
      Maybe.withDefault
        False
        (Maybe.map (\action -> node.actions.click == action) library.currentRequest)

    options =
      { preventDefault = True, stopPropagation = True }

    click msg =
      onWithOptions "click" options (Json.succeed msg)
  in
    div
      [ classList
          [ ( "library--node", True )
          , ( "library--node__active", isActive )
          , ( "library--click-action", True )
          ]
      , onClick (Library.ExecuteAction node.actions.click)
      ]
      [ div
          [ class "library--node--icon"
          , style [("backgroundImage", (Utils.Css.url node.icon))]
          , click (Library.MaybeExecuteAction node.actions.play)
          ]
          []
      , div
          [ class "library--node--inner" ]
          [ div
            []
            [ text node.title ]
          , (metadata node.metadata)
          ]
      ]


folder : Library.Model -> Library.Folder -> Html Library.Msg
folder model folder =
  let
    children =
      if List.isEmpty folder.children then
        div [] []
      else
        div [ class "block-group library-contents" ] (List.map (node model folder) folder.children)
  in
    -- Debug.log (" folder " ++ (toString folder))
    div
      []
      [ (breadcrumb model folder)
      , children
      ]


breadcrumb : Library.Model -> Library.Folder -> Html Library.Msg
breadcrumb model folder =
  let
    breadcrumbLink classes index level =
      a [ class classes, onClick (Library.PopLevel (index)) ] [ text level.title ]

    sections =
      (model.levels)
        |> List.indexedMap (breadcrumbLink "library--breadcrumb--section")

    ( list', dropdown' ) =
      List.Extra.splitAt 2 (sections)

    dividers list =
      List.intersperse (span [ class "library--breadcrumb--divider" ] []) list

    dropdown =
      dividers (List.reverse dropdown')

    list =
      dividers (List.reverse list')
  in
    div
      [ class "library--breadcrumb" ]
      [ div [ class "library--breadcrumb--dropdown" ] dropdown
        -- , span [ class "library--breadcrumb--divider" ] []
      , div [ class "library--breadcrumb--sections" ] list
      ]
