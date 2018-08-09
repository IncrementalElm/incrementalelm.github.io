module Main exposing (..)

import Animation
import Color
import Element exposing (Element)
import Element.Background as Background
import Element.Font
import ElmLogo
import Html exposing (Html)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Time exposing (second)


type alias Model =
    { styles : List Animation.State
    , index : Int
    }


type Msg
    = Animate Animation.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        Animate time ->
            ( { model
                | styles = List.map (Animation.update time) model.styles
              }
            , Cmd.none
            )


updateStyles : Model -> Model
updateStyles model =
    { model
        | styles =
            model.styles
                |> List.indexedMap makeTranslated
    }


view : Model -> Html Msg
view model =
    mainView model
        |> Element.layout []


mainView model =
    [ animationView model
    , Element.text "Incremental Elm"
        |> Element.el
            [ Element.Font.color Color.white
            , Element.Font.size 50
            , Element.Font.family [ Element.Font.typeface "Lato" ]
            ]
    ]
        |> Element.row
            [ Background.color (Color.rgb 55 63 81)
            , Element.alignTop
            ]


animationView model =
    svg
        [ version "1.1"
        , x "0"
        , y "0"
        , viewBox "0 0 323.141 322.95"
        , width "100%"
        ]
        [ Svg.g []
            (List.map (\poly -> polygon (Animation.render poly) []) model.styles)
        ]
        |> Element.html
        |> Element.el
            [ Element.padding 20
            , Element.height Element.shrink
            , Element.width (Element.px 100)
            , Element.alignTop
            , Element.alignLeft
            ]


translate n =
    Animation.translate (Animation.px n) (Animation.px n)


makeTranslated i polygon =
    polygon
        |> Animation.interrupt
            [ Animation.set
                [ translate -1000
                , Animation.scale 1
                ]
            , Animation.wait (Time.second * toFloat i * 0.1 + (((toFloat i * toFloat i) * Time.second * 0.05) / (toFloat i + 1)))
            , Animation.to
                [ translate 0
                , Animation.scale 1
                ]
            ]


init : ( Model, Cmd Msg )
init =
    ( { styles = ElmLogo.polygons |> List.map Animation.style
      , index = 1
      }
        |> updateStyles
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Animation.subscription Animate model.styles


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
