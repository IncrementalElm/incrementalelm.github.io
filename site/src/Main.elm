module Main exposing (main)

import Animation
import Browser
import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Nav
import Content exposing (Content)
import Dict exposing (Dict)
import Dimensions exposing (Dimensions)
import Ease
import Element exposing (Element)
import Element.Border
import Element.Font as Font
import ElmLogo
import Json.Decode
import List.Extra
import Mark
import Mark.Error
import MarkParser
import RawContent
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Task
import Time
import Url exposing (Url)
import View.MenuBar
import View.Navbar


type alias Flags =
    { imageAssets : Json.Decode.Value
    }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , menuBarAnimation : View.MenuBar.Model
    , menuAnimation : Animation.State
    , dimensions : Dimensions
    , styles : List Animation.State
    , showMenu : Bool
    , imageAssets : Dict String String
    }


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , url = url
      , imageAssets = Json.Decode.decodeValue (Json.Decode.dict Json.Decode.string) flags.imageAssets |> Result.withDefault Dict.empty
      , styles = ElmLogo.polygons |> List.map Animation.style
      , menuBarAnimation = View.MenuBar.init
      , menuAnimation =
            Animation.style
                [ Animation.opacity 0
                ]
      , dimensions =
            Dimensions.init
                { width = 0
                , height = 0
                , device = Element.classifyDevice { height = 0, width = 0 }
                }
      , showMenu = False
      }
    , Dom.getViewport
        |> Task.perform InitialViewport
    )


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | StartAnimation
      -- | Animate Animation.Msg
    | InitialViewport Dom.Viewport
    | WindowResized Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

        InitialViewport { viewport } ->
            ( { model
                | dimensions =
                    Dimensions.init
                        { width = viewport.width
                        , height = viewport.height
                        , device =
                            Element.classifyDevice
                                { height = round viewport.height
                                , width = round viewport.width
                                }
                        }
              }
            , Cmd.none
            )

        WindowResized width height ->
            ( { model
                | dimensions =
                    Dimensions.init
                        { width = toFloat width
                        , height = toFloat height
                        , device = Element.classifyDevice { height = height, width = width }
                        }
              }
            , Cmd.none
            )

        StartAnimation ->
            case model.showMenu of
                True ->
                    ( { model
                        | showMenu = False
                        , menuBarAnimation = View.MenuBar.startAnimation model
                        , menuAnimation =
                            model.menuAnimation
                                |> Animation.interrupt
                                    [ Animation.toWith interpolation
                                        [ Animation.opacity 100
                                        ]
                                    ]
                      }
                    , Cmd.none
                    )

                False ->
                    ( { model
                        | showMenu = True
                        , menuBarAnimation = View.MenuBar.startAnimation model
                        , menuAnimation =
                            model.menuAnimation
                                |> Animation.interrupt
                                    [ Animation.toWith interpolation
                                        [ Animation.opacity 100
                                        ]
                                    ]
                      }
                    , Cmd.none
                    )



-- Animate time ->
--     ( { model
--         | styles = List.map (Animation.update time) model.styles
--         , menuBarAnimation = View.MenuBar.update time model.menuBarAnimation
--         , menuAnimation = Animation.update time model.menuAnimation
--       }
--     , Cmd.none
--     )


interpolation =
    Animation.easing
        { duration = second * 1
        , ease = Ease.inOutCubic
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    -- Sub.batch
    --     [ Animation.subscription Animate
    --         (model.styles
    --             ++ View.MenuBar.animationStates model.menuBarAnimation
    --             ++ [ model.menuAnimation ]
    --         )
    -- ,
    Browser.Events.onResize WindowResized



--     ]


view : Model -> Browser.Document Msg
view model =
    let
        { title, body } =
            mainView model
    in
    { title = title
    , body =
        [ body
            |> Element.layout
                [ Element.width Element.fill
                ]
        ]
    }


mainView : Model -> { title : String, body : Element Msg }
mainView model =
    case RawContent.content model.imageAssets of
        Ok site ->
            pageView model site

        Err errorView ->
            { title = "Error parsing"
            , body = errorView
            }


pageView : Model -> Content Msg -> { title : String, body : Element Msg }
pageView model content =
    case Content.lookup content model.url of
        Just pageOrPost ->
            { title = pageOrPost.metadata.title.raw
            , body =
                [ header model
                , pageOrPost.body
                    |> Element.column
                        [ if Dimensions.isMobile model.dimensions then
                            Element.width (Element.fill |> Element.maximum 600)

                          else
                            Element.width (Element.fill |> Element.maximum 700)
                        , Element.height Element.fill
                        , Element.padding 20
                        , Element.spacing 20
                        , Element.centerX
                        ]
                ]
                    |> Element.column [ Element.width Element.fill ]
            }

        Nothing ->
            { title = "Page not found"
            , body =
                Element.column []
                    [ Element.text "Page not found. Valid routes:\n\n"
                    , (content.pages ++ content.posts)
                        |> List.map Tuple.first
                        |> List.map (String.join "/")
                        |> String.join ", "
                        |> Element.text
                    ]
            }


header : Model -> Element Msg
header model =
    View.Navbar.view model animationView StartAnimation


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
            , Element.alignTop
            , Element.alignLeft
            , Element.width (Element.px 100)
            ]


translate n =
    Animation.translate (Animation.px n) (Animation.px n)


second =
    1000


makeTranslated i polygon =
    polygon
        |> Animation.interrupt
            [ Animation.set
                [ translate -1000
                , Animation.scale 1
                ]
            , Animation.wait
                (second
                    * toFloat i
                    * 0.1
                    + (((toFloat i * toFloat i) * second * 0.05) / (toFloat i + 1))
                    |> round
                    |> Time.millisToPosix
                )
            , Animation.to
                [ translate 0
                , Animation.scale 1
                ]
            ]



-- Element.row [ Element.padding 20, Element.Border.width 2, Element.spaceEvenly ]
--     [ Element.el [ Font.size 30 ]
--         (Element.link [] { url = "/", label = Element.text "elm-markup-site" })
--     , Element.row [ Element.spacing 15 ]
--         [ Element.link [] { url = "/articles", label = Element.text "Articles" }
--         , Element.link [] { url = "/about", label = Element.text "About" }
--         ]
--     ]
