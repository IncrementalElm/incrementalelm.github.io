module Page.Article exposing (view)

import Dimensions exposing (Dimensions)
import Element exposing (Element)
import Element.Background as Background
import Element.Border
import Element.Font
import Html
import Html.Attributes exposing (attribute, class, style)
import Mark
import MarkParser
import Page.Article.Post exposing (Post)
import Style exposing (fontSize, fonts, palette)
import Style.Helpers
import View.Ellie
import View.FontAwesome
import View.Resource as Resource exposing (Resource)


view : Dimensions -> Maybe String -> Element.Element msg
view dimensions learnPageName =
    Element.column
        [ if Dimensions.isMobile dimensions then
            Element.width (Element.fill |> Element.maximum 600)

          else
            Element.width (Element.fill |> Element.maximum 700)
        , Element.height Element.fill
        , Element.padding 20
        , Element.spacing 20
        , Element.centerX
        ]
        (case learnPageName of
            Just actualLearnPageName ->
                findPostByName actualLearnPageName
                    |> Maybe.map (learnPostView dimensions)
                    |> Maybe.withDefault [ Element.text "Couldn't find page!" ]

            Nothing ->
                resourcesDirectory
        )


learnPostView :
    Dimensions
    -> Post
    -> List (Element msg)
learnPostView dimensions learnPost =
    [ title learnPost.title
    , parsePostBody learnPost.body
    ]


parsePostBody : String -> Element msg
parsePostBody markup =
    markup
        |> MarkParser.parse []
        |> (\result ->
                case result of
                    Err message ->
                        Element.text "Couldn't parse!\n"

                    Ok element ->
                        element identity
           )


resourcesDirectory : List (Element msg)
resourcesDirectory =
    Page.Article.Post.all
        |> List.map
            (\resource ->
                Style.Helpers.sameTabLink2
                    { url = "/articles/" ++ resource.pageName
                    , content =
                        Element.column
                            [ Element.centerX
                            , Element.width (Element.maximum 800 Element.fill)
                            , Element.centerX
                            , Element.padding 40
                            , Element.spacing 10
                            , Element.Border.width 1
                            , Element.Border.color (Element.rgba255 0 0 0 0.1)
                            , Element.mouseOver
                                [ Element.Border.color (Element.rgba255 0 0 0 1)
                                ]
                            ]
                            [ title resource.title
                            , Element.column [ Element.spacing 20 ]
                                [ resource |> postPreview
                                , readMoreLink
                                ]
                            ]
                    }
            )


readMoreLink =
    Element.text "Continue reading >>"
        |> Element.el
            [ Element.centerX
            , Element.Font.size 18
            , Element.alpha 0.6
            , Element.mouseOver [ Element.alpha 1 ]
            , Element.Font.underline
            ]


postPreview : Post -> Element msg
postPreview post =
    post.body
        |> MarkParser.parsePreview []
        |> (\result ->
                case result of
                    Err message ->
                        Element.text "Couldn't parse!\n"

                    Ok element ->
                        element identity
           )


findPostByName : String -> Maybe Post
findPostByName postName =
    Page.Article.Post.all
        |> List.filter (\post -> post.pageName == postName)
        |> List.head


title : String -> Element msg
title text =
    [ Element.text text ]
        |> Element.paragraph
            [ Element.Font.size 36
            , Element.Font.center
            , Element.Font.family [ Element.Font.typeface "Raleway" ]
            , Element.Font.semiBold
            , Element.padding 16
            ]


newResourcesView :
    List Resource
    -> Element msg
newResourcesView resources =
    Element.column
        [ Element.spacing 16
        , Element.centerX
        , Element.padding 30
        , Element.width Element.fill
        ]
        (resources
            |> List.map
                (\resource ->
                    case resource.description of
                        Nothing ->
                            Resource.view resource

                        Just description ->
                            Element.column
                                [ Element.spacing 8
                                , Element.width Element.fill
                                , Element.paddingXY 0 16
                                ]
                                [ Resource.view resource
                                , Element.paragraph [ Style.fontSize.small, Element.Font.center ] [ Element.text description ]
                                ]
                )
        )
