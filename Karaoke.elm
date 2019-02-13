module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode
import Json.Decode exposing (map2, list, field, string)
import Json.Encode as Encode
import List
import String
import Regex exposing (regex, replace, HowMany(All))
import Html.Events exposing (onInput)
import Storage.Local exposing (getSync, setSync)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Song =
    { title : String
    , artist : String
    }


type alias Model =
    { allSongs : List Song
    , filter : String
    }


getState : List Song
getState =
    case getSync "state" of
        Ok (Just songs) ->
            case Json.Decode.decodeString decodeSongs songs of
                Ok songs ->
                    songs

                _ ->
                    []

        _ ->
            []


init : ( Model, Cmd Msg )
init =
    ( Model getState "", fetchSongs )



-- UPDATE


type Msg
    = Songlist (Result Http.Error (List Song))
    | UpdateFilter String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Songlist (Err _) ->
            ( model
            , if List.isEmpty model.allSongs then
                fetchSongs
              else
                Cmd.none
            )

        Songlist (Ok songs) ->
            let
                set =
                    setSync "state" (Encode.encode 0 (encodeSongs songs))
            in
                ( { model | allSongs = songs }, Cmd.none )

        UpdateFilter f ->
            ( { model | filter = f }, Cmd.none )


filterSongs : String -> List Song -> List Song
filterSongs search songs =
    let
        normalize =
            String.toLower >> replace All (regex "[^\\w]") (\_ -> "")

        looselyContains needle haystack =
            String.contains (normalize needle) (normalize haystack)

        matches { title, artist } =
            List.any (looselyContains search) [ title, artist, artist ++ title ]
    in
        List.filter matches songs



-- VIEW


html =
    node "html"


head =
    node "head"


meta =
    node "meta"


link =
    node "link"


sizes =
    attribute "sizes"


script =
    node "script"


view : Model -> Html Msg
view model =
  body []
  [ h1 []
  [ text "Karaoke Search" ]
  , div [ class "container" ]
  [ input [ autofocus True, type_ "text", class "search", placeholder "Search...", onInput UpdateFilter ]
  []
  ]
  , div [ class "results" ]
  [ ul []
  (renderSongs <| filterSongs model.filter model.allSongs)
  ]
  , script [ src "js/vendor/bookmark_bubble.js" ] []
  ]


renderSongs : List Song -> List (Html a)
renderSongs songs =
    let
        renderSong s =
            li [] [ text (s.artist ++ " - " ++ s.title) ]
    in
        List.map renderSong songs



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- HTTP


fetchSongs : Cmd Msg
fetchSongs =
    let
        url =
            "https://lptsjwc3ua.execute-api.us-west-2.amazonaws.com/public/songs"
    in
        Http.send Songlist (Http.get url decodeSongs)


decodeSongs : Decode.Decoder (List Song)
decodeSongs =
    Decode.list (Decode.map2 Song (Decode.field "title" Decode.string) (Decode.field "artist" Decode.string))


encodeSongs : List Song -> Encode.Value
encodeSongs songs =
    let
        encodeSong { artist, title } =
            Encode.object
                [ ( "artist", Encode.string artist )
                , ( "title", Encode.string title )
                ]

        songsJson =
            List.map encodeSong songs
    in
        Encode.list songsJson
