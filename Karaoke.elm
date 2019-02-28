port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode
import Json.Decode exposing (map2, list, field, string)
import Json.Encode as Encode
import List
import String
import Regex
import Html.Events exposing (onInput)
import Maybe


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = \_ -> Sub.none
        , view = view
        , update = update
        }

port cache : Encode.Value -> Cmd msg


-- MODEL


type alias Song =
    { title : String
    , artist : String
    }


type alias Model =
    { allSongs : List Song
    , filter : String
    }


init : Decode.Value -> ( Model, Cmd Msg )
init songsString =
  let songList = Decode.decodeValue decodeSongs songsString |> Result.withDefault []
  in
    ( Model songList  "", fetchSongs )



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

        Songlist (Ok songs) -> ( { model | allSongs = songs }, cache <| encodeSongs <| songs)

        UpdateFilter f ->
            ( { model | filter = f }, Cmd.none )


filterSongs : String -> List Song -> List Song
filterSongs search songs =
    let
        normalize =
            String.toLower >> Regex.replace (Maybe.withDefault Regex.never <| Regex.fromString "[^\\w]") (\_ -> "")

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
  div []
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





-- HTTP / json


fetchSongs : Cmd Msg
fetchSongs =
    let
        url =
            "https://lptsjwc3ua.execute-api.us-west-2.amazonaws.com/public/songs"
    in
        Http.get {url = url, expect = Http.expectJson Songlist decodeSongs}


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
    in
        Encode.list encodeSong songs
