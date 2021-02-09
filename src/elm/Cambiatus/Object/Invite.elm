-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Cambiatus.Object.Invite exposing (..)

import Cambiatus.InputObject
import Cambiatus.Interface
import Cambiatus.Object
import Cambiatus.Scalar
import Cambiatus.ScalarCodecs
import Cambiatus.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


community :
    SelectionSet decodesTo Cambiatus.Object.Community
    -> SelectionSet decodesTo Cambiatus.Object.Invite
community object_ =
    Object.selectionForCompositeField "community" [] object_ identity


creator :
    SelectionSet decodesTo Cambiatus.Object.User
    -> SelectionSet decodesTo Cambiatus.Object.Invite
creator object_ =
    Object.selectionForCompositeField "creator" [] object_ identity
