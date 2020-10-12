-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Cambiatus.Object.DeleteAddress exposing (..)

import Cambiatus.Enum.DeleteAddressStatus
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


reason : SelectionSet String Cambiatus.Object.DeleteAddress
reason =
    Object.selectionForField "String" "reason" [] Decode.string


status : SelectionSet Cambiatus.Enum.DeleteAddressStatus.DeleteAddressStatus Cambiatus.Object.DeleteAddress
status =
    Object.selectionForField "Enum.DeleteAddressStatus.DeleteAddressStatus" "status" [] Cambiatus.Enum.DeleteAddressStatus.decoder
