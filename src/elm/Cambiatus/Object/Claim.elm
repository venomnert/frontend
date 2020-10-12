-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Cambiatus.Object.Claim exposing (..)

import Cambiatus.Enum.ClaimStatus
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


action :
    SelectionSet decodesTo Cambiatus.Object.Action
    -> SelectionSet decodesTo Cambiatus.Object.Claim
action object_ =
    Object.selectionForCompositeField "action" [] object_ identity


type alias ChecksOptionalArguments =
    { input : OptionalArgument Cambiatus.InputObject.ChecksInput }


checks :
    (ChecksOptionalArguments -> ChecksOptionalArguments)
    -> SelectionSet decodesTo Cambiatus.Object.Check
    -> SelectionSet (List decodesTo) Cambiatus.Object.Claim
checks fillInOptionals object_ =
    let
        filledInOptionals =
            fillInOptionals { input = Absent }

        optionalArgs =
            [ Argument.optional "input" filledInOptionals.input Cambiatus.InputObject.encodeChecksInput ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "checks" optionalArgs object_ (identity >> Decode.list)


claimer :
    SelectionSet decodesTo Cambiatus.Object.Profile
    -> SelectionSet decodesTo Cambiatus.Object.Claim
claimer object_ =
    Object.selectionForCompositeField "claimer" [] object_ identity


createdAt : SelectionSet Cambiatus.ScalarCodecs.DateTime Cambiatus.Object.Claim
createdAt =
    Object.selectionForField "ScalarCodecs.DateTime" "createdAt" [] (Cambiatus.ScalarCodecs.codecs |> Cambiatus.Scalar.unwrapCodecs |> .codecDateTime |> .decoder)


createdBlock : SelectionSet Int Cambiatus.Object.Claim
createdBlock =
    Object.selectionForField "Int" "createdBlock" [] Decode.int


createdEosAccount : SelectionSet String Cambiatus.Object.Claim
createdEosAccount =
    Object.selectionForField "String" "createdEosAccount" [] Decode.string


createdTx : SelectionSet String Cambiatus.Object.Claim
createdTx =
    Object.selectionForField "String" "createdTx" [] Decode.string


id : SelectionSet Int Cambiatus.Object.Claim
id =
    Object.selectionForField "Int" "id" [] Decode.int


status : SelectionSet Cambiatus.Enum.ClaimStatus.ClaimStatus Cambiatus.Object.Claim
status =
    Object.selectionForField "Enum.ClaimStatus.ClaimStatus" "status" [] Cambiatus.Enum.ClaimStatus.decoder
