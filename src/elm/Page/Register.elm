module Page.Register exposing (Model, Msg, init, jsAddressToMsg, msgToString, update, view)

import Address
import Api.Graphql
import Cambiatus.Enum.SignUpStatus as SignUpStatus
import Cambiatus.InputObject as InputObject
import Cambiatus.Mutation as Mutation
import Cambiatus.Object.SignUpResponse
import Cambiatus.Scalar exposing (Id(..))
import Community exposing (Invite)
import Eos.Account as Eos
import Graphql.Http
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (with)
import Html exposing (Html, a, button, div, img, input, label, p, span, strong, text)
import Html.Attributes exposing (checked, class, disabled, id, src, style, type_, value)
import Html.Events exposing (onCheck, onClick, onSubmit)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Page
import Page.Register.Common exposing (ProblemEvent(..))
import Page.Register.DefaultForm as DefaultForm
import Page.Register.JuridicalForm as JuridicalForm
import Page.Register.NaturalForm as NaturalForm
import Result
import Route
import Session.Guest as Guest exposing (External(..))
import Session.Shared exposing (Shared, Translators)
import UpdateResult as UR
import Validate
import View.Form



-- INIT


init : InvitationId -> Guest.Model -> ( Model, Cmd Msg )
init invitationId { shared } =
    let
        initialStatus =
            case invitationId of
                Just _ ->
                    Loading

                Nothing ->
                    FormShowed
                        (DefaultForm DefaultForm.init)

        initialModel =
            { accountKeys = Nothing
            , hasAgreedToSavePassphrase = False
            , isPassphraseCopiedToClipboard = False
            , serverError = Nothing
            , status = initialStatus
            , invitationId = invitationId
            , invitation = Nothing
            , country = Nothing
            , step = FillForm
            }

        loadInvitationData =
            case invitationId of
                Just id ->
                    Api.Graphql.query
                        shared
                        (Community.inviteQuery id)
                        CompletedLoadInvite

                Nothing ->
                    Cmd.none
    in
    ( initialModel
    , loadInvitationData
    )



-- MODEL


type alias Model =
    { accountKeys : Maybe AccountKeys
    , hasAgreedToSavePassphrase : Bool
    , isPassphraseCopiedToClipboard : Bool
    , serverError : ServerError
    , status : Status
    , invitationId : InvitationId
    , invitation : Maybe Invite
    , country : Maybe Address.Country
    , step : Step
    }


type Status
    = Loading
    | AccountTypeSelectorShowed
    | FormShowed FormModel
    | AccountCreated
    | ErrorShowed Error
    | NotFound


type Step
    = FillForm
    | SavePassphrase


type FormModel
    = NaturalForm NaturalForm.Model
    | JuridicalForm JuridicalForm.Model
    | DefaultForm DefaultForm.Model


type alias SignUpFields =
    { name : String
    , email : String
    , account : String
    }


type alias PdfData =
    { passphrase : String
    , accountName : String
    }


type Error
    = FailedInvite (Graphql.Http.Error (Maybe Invite))
    | FailedCountry (Graphql.Http.Error (Maybe Address.Country))


type alias ServerError =
    Maybe String


type alias InvitationId =
    Maybe String


type AccountType
    = NaturalAccount
    | JuridicalAccount Address.Country



---- ACCOUNT KEYS


type alias AccountKeys =
    { ownerKey : String
    , activeKey : String
    , accountName : Eos.Name
    , words : String
    , privateKey : String
    }



-- VIEW


view : Guest.Model -> Model -> { title : String, content : Html Msg }
view { shared } model =
    let
        { t } =
            shared.translators
    in
    { title =
        t "register.registerTab"
    , content =
        viewCreateAccount shared.translators model
    }


viewCreateAccount : Translators -> Model -> Html Msg
viewCreateAccount translators model =
    let
        formClasses =
            "flex flex-grow flex-col bg-white px-4 px-0 md:max-w-sm sf-wrapper self-center w-full"

        backgroundColor =
            case model.step of
                FillForm ->
                    "bg-white"

                SavePassphrase ->
                    "bg-purple-500"
    in
    div
        [ -- `id` is used for scrolling into view if error happens
          id "registrationPage"
        , class ("flex flex-grow flex-col " ++ backgroundColor)
        ]
        [ viewTitleForStep translators model.step
        , case model.status of
            Loading ->
                div [ class "h-full full-spinner-container" ]
                    [ div [ class "spinner spinner-light" ] [] ]

            AccountTypeSelectorShowed ->
                div [ class formClasses ]
                    [ viewAccountTypeSelector translators model
                    , viewFooterDisabled translators
                    ]

            FormShowed formModel ->
                Html.form
                    [ class formClasses
                    , onSubmit (ValidateForm formModel)
                    ]
                    [ case model.serverError of
                        Just e ->
                            div [ class "bg-red border-lg rounded p-4 mt-2 text-white mb-4" ]
                                [ text e ]

                        Nothing ->
                            text ""
                    , viewAccountTypeSelector translators model
                    , div [ class "sf-content" ]
                        [ viewRegistrationForm translators formModel ]
                    , viewFooterEnabled translators
                    ]

            AccountCreated ->
                case model.accountKeys of
                    Just keys ->
                        viewAccountCreated translators model keys

                    Nothing ->
                        -- TODO: This should never happen
                        text ""

            ErrorShowed _ ->
                Page.fullPageNotFound (translators.t "error.unknown") ""

            NotFound ->
                Page.fullPageNotFound (translators.t "error.pageNotFound") ""
        ]


viewFooterEnabled : Translators -> Html msg
viewFooterEnabled translators =
    viewFooter translators True


viewFooterDisabled : Translators -> Html msg
viewFooterDisabled translators =
    viewFooter translators False


viewFooter : Translators -> Bool -> Html msg
viewFooter { t } isSubmitEnabled =
    let
        viewSubmitButton =
            button
                [ class "button w-full mb-4"
                , class
                    (if isSubmitEnabled then
                        "button-primary"

                     else
                        "button-disabled"
                    )
                , disabled (not isSubmitEnabled)
                ]
                [ text (t "auth.login.continue") ]
    in
    div [ class "mt-auto flex flex-col justify-between items-center h-32" ]
        [ span []
            [ text (t "register.login")
            , a
                [ class "underline text-orange-300"
                , Route.href (Route.Login Nothing)
                ]
                [ text (t "register.authLink") ]
            ]
        , viewSubmitButton
        ]


viewRegistrationForm : Translators -> FormModel -> Html Msg
viewRegistrationForm translators currentForm =
    case currentForm of
        NaturalForm form ->
            NaturalForm.view translators form
                |> Html.map NaturalFormMsg
                |> Html.map FormMsg

        JuridicalForm form ->
            JuridicalForm.view translators form
                |> Html.map JuridicalFormMsg
                |> Html.map FormMsg

        DefaultForm form ->
            DefaultForm.view translators form
                |> Html.map DefaultFormMsg
                |> Html.map FormMsg


viewAccountTypeSelector : Translators -> Model -> Html Msg
viewAccountTypeSelector translators model =
    case ( model.invitation, model.country ) of
        ( Just _, Just country ) ->
            div []
                [ View.Form.primaryLabel "radio" (translators.t "register.form.register_tooltip")
                , div [ class "flex space-x-2" ]
                    [ viewAccountTypeButton
                        (translators.t "register.form.types.natural")
                        NaturalAccount
                        model.status
                    , viewAccountTypeButton
                        (translators.t "register.form.types.juridical")
                        (JuridicalAccount country)
                        model.status
                    ]
                ]

        _ ->
            text ""


viewAccountTypeButton : String -> AccountType -> Status -> Html Msg
viewAccountTypeButton title accountType status =
    let
        isSelected =
            case ( accountType, status ) of
                ( NaturalAccount, FormShowed (NaturalForm _) ) ->
                    True

                ( JuridicalAccount _, FormShowed (JuridicalForm _) ) ->
                    True

                _ ->
                    False
    in
    div
        [ class "w-1/2 leading-10 text-center cursor-pointer rounded-sm cursor-pointer mb-4"
        , class
            (if isSelected then
                "bg-orange-300 text-white"

             else
                "bg-gray-100 text-black"
            )
        , onClick (AccountTypeSelected accountType)
        ]
        [ text title ]


viewAccountCreated : Translators -> Model -> AccountKeys -> Html Msg
viewAccountCreated { t } model keys =
    let
        name =
            Eos.nameToString keys.accountName

        passphraseTextId =
            "passphraseText"

        passphraseInputId =
            -- Passphrase text is duplicated in `input:text` to be able to copy via Browser API
            "passphraseWords"
    in
    div
        [ class "flex-grow bg-purple-500 flex md:block"
        ]
        [ div
            [ class "sf-wrapper"
            , class "px-4 md:max-w-sm md:mx-auto md:pt-20 md:px-0 text-white text-body"
            ]
            [ div [ class "sf-content" ]
                [ p
                    [ class "text-xl mb-3" ]
                    [ text (t "register.account_created.greet")
                    , text " "
                    , strong [] [ text name ]
                    , text ", "
                    , text (t "register.account_created.last_step")
                    ]
                , p [ class "mb-3" ]
                    [ text (t "register.account_created.instructions")
                    ]
                , div [ class "w-1/4 m-auto relative left-1" ]
                    [ img [ src "/images/reg-passphrase-boy.svg" ]
                        []
                    , img
                        [ class "absolute w-1/4 -mt-2 -ml-10"
                        , src "/images/reg-passphrase-boy-hand.svg"
                        ]
                        []
                    ]
                , div [ class "bg-white text-black text-2xl mb-12 p-4 rounded-lg" ]
                    [ p [ class "input-label" ]
                        [ text (t "register.account_created.twelve_words")
                        , if model.isPassphraseCopiedToClipboard then
                            strong [ class "uppercase ml-1" ]
                                [ text (t "register.account_created.words_copied")
                                , text " ✔"
                                ]

                          else
                            text ""
                        ]
                    , p
                        [ class "pb-2 leading-tight" ]
                        [ span [ class "select-all", id passphraseTextId ] [ text keys.words ]
                        , input
                            -- We use `HTMLInputElement.select()` method in port to select and copy the text. This method
                            -- works only with `input` and `textarea` elements which has to be presented in DOM (e.g. we can't
                            -- hide it with `display: hidden`), so we hide it using position and opacity.
                            [ type_ "text"
                            , class "absolute opacity-0"
                            , style "left" "-9999em"
                            , id passphraseInputId
                            , value keys.words
                            ]
                            []
                        ]
                    , button
                        [ class "button m-auto button-primary button-sm"
                        , onClick <| CopyToClipboard passphraseInputId
                        ]
                        [ text (t "register.account_created.copy") ]
                    ]
                ]
            , div [ class "sf-footer" ]
                [ div [ class "my-4" ]
                    [ label [ class "form-label block" ]
                        [ input
                            [ type_ "checkbox"
                            , class "form-checkbox mr-2 p-1"
                            , checked model.hasAgreedToSavePassphrase
                            , onCheck AgreedToSave12Words
                            ]
                            []
                        , text (t "register.account_created.i_saved_words")
                        , text " 💜"
                        ]
                    ]
                , button
                    [ onClick <|
                        DownloadPdf
                            { passphrase = keys.words
                            , accountName = Eos.nameToString keys.accountName
                            }
                    , class "button button-primary w-full mb-8"
                    , disabled (not model.hasAgreedToSavePassphrase)
                    , class <|
                        if model.hasAgreedToSavePassphrase then
                            ""

                        else
                            "button-disabled text-gray-600"
                    ]
                    [ text (t "register.account_created.download") ]
                ]
            ]
        ]


viewTitleForStep : Translators -> Step -> Html msg
viewTitleForStep { t, tr } s =
    let
        stepNum =
            case s of
                FillForm ->
                    "1"

                SavePassphrase ->
                    "2"
    in
    p
        [ class "ml-4 py-4 mb-4 text-body border-b border-dotted text-grey border-grey-500" ]
        [ text (tr "register.form.step" [ ( "stepNum", stepNum ) ])
        , text " / "
        , strong
            [ class <|
                case s of
                    FillForm ->
                        "text-black"

                    SavePassphrase ->
                        "text-white"
            ]
            [ text <| t ("register.form.step" ++ stepNum ++ "_title") ]
        ]



-- UPDATE


type alias UpdateResult =
    UR.UpdateResult Model Msg External


type Msg
    = NoOp
    | ValidateForm FormModel
    | GotAccountAvailabilityResponse Bool
    | AccountKeysGenerated (Result Decode.Error AccountKeys)
    | AgreedToSave12Words Bool
    | DownloadPdf PdfData
    | PdfDownloaded
    | CopyToClipboard String
    | CopiedToClipboard
    | CompletedLoadInvite (Result (Graphql.Http.Error (Maybe Invite)) (Maybe Invite))
    | CompletedLoadCountry (Result (Graphql.Http.Error (Maybe Address.Country)) (Maybe Address.Country))
    | AccountTypeSelected AccountType
    | FormMsg EitherFormMsg
    | CompletedSignUp (Result (Graphql.Http.Error SignUpResponse) SignUpResponse)
    | CompletedKycUpsert (Result (Graphql.Http.Error (Maybe ())) (Maybe ()))
    | CompletedAddressUpsert (Result (Graphql.Http.Error (Maybe ())) (Maybe ()))


type EitherFormMsg
    = JuridicalFormMsg JuridicalForm.Msg
    | NaturalFormMsg NaturalForm.Msg
    | DefaultFormMsg DefaultForm.Msg


getSignUpFields : FormModel -> SignUpFields
getSignUpFields form =
    let
        extract : { f | account : String, name : String, email : String } -> SignUpFields
        extract f =
            { account = f.account
            , name = f.name
            , email = f.email
            }
    in
    case form of
        JuridicalForm f ->
            extract f

        NaturalForm f ->
            extract f

        DefaultForm f ->
            extract f


update : InvitationId -> Msg -> Model -> Guest.Model -> UpdateResult
update _ msg model { shared } =
    let
        { t } =
            shared.translators

        scrollTop =
            UR.addPort
                { responseAddress = NoOp
                , responseData = Encode.null
                , data =
                    Encode.object
                        [ ( "id", Encode.string "registrationPage" )
                        , ( "name", Encode.string "scrollIntoView" )
                        ]
                }
    in
    case msg of
        NoOp ->
            model |> UR.init

        ValidateForm formType ->
            let
                validateForm validator form =
                    case Validate.validate validator form of
                        Ok _ ->
                            []

                        Err err ->
                            err

                account =
                    getSignUpFields formType
                        |> .account

                translators =
                    shared.translators

                problemCount =
                    case formType of
                        JuridicalForm form ->
                            List.length (validateForm (JuridicalForm.validator translators) form)

                        NaturalForm form ->
                            List.length (validateForm (NaturalForm.validator translators) form)

                        DefaultForm form ->
                            List.length (validateForm (DefaultForm.validator translators) form)

                afterValidationAction =
                    if problemCount > 0 then
                        UR.addCmd Cmd.none

                    else
                        UR.addPort
                            { responseAddress = ValidateForm formType
                            , responseData = Encode.null
                            , data =
                                Encode.object
                                    [ ( "name", Encode.string "checkAccountAvailability" )
                                    , ( "account", Encode.string account )
                                    ]
                            }
            in
            { model
                | status =
                    case formType of
                        JuridicalForm form ->
                            JuridicalForm
                                { form
                                    | problems = validateForm (JuridicalForm.validator translators) form
                                }
                                |> FormShowed

                        NaturalForm form ->
                            NaturalForm
                                { form
                                    | problems = validateForm (NaturalForm.validator translators) form
                                }
                                |> FormShowed

                        DefaultForm form ->
                            DefaultForm
                                { form
                                    | problems = validateForm (DefaultForm.validator translators) form
                                }
                                |> FormShowed
            }
                |> UR.init
                |> afterValidationAction

        FormMsg formMsg ->
            case ( formMsg, model.status ) of
                ( JuridicalFormMsg innerMsg, FormShowed (JuridicalForm form) ) ->
                    { model
                        | status =
                            JuridicalForm.update shared.translators innerMsg form
                                |> JuridicalForm
                                |> FormShowed
                    }
                        |> UR.init

                ( NaturalFormMsg innerMsg, FormShowed (NaturalForm form) ) ->
                    { model
                        | status =
                            NaturalForm.update shared.translators innerMsg form
                                |> NaturalForm
                                |> FormShowed
                    }
                        |> UR.init

                ( DefaultFormMsg innerMsg, FormShowed (DefaultForm form) ) ->
                    { model
                        | status =
                            DefaultForm.update shared.translators innerMsg form
                                |> DefaultForm
                                |> FormShowed
                    }
                        |> UR.init

                _ ->
                    UR.init model

        AccountTypeSelected accountType ->
            let
                selectedKycForm =
                    case accountType of
                        NaturalAccount ->
                            NaturalForm
                                (NaturalForm.init
                                    { account = Nothing
                                    , email = Nothing
                                    , phone = Nothing
                                    }
                                )

                        JuridicalAccount country ->
                            JuridicalForm
                                (JuridicalForm.init
                                    { account = Nothing
                                    , email = Nothing
                                    , phone = Nothing
                                    , country = country
                                    }
                                    shared.translators
                                )
            in
            { model | status = FormShowed selectedKycForm }
                |> UR.init

        GotAccountAvailabilityResponse isAvailable ->
            if isAvailable then
                let
                    account =
                        case model.status of
                            FormShowed formType ->
                                getSignUpFields formType
                                    |> .account

                            _ ->
                                ""
                in
                model
                    |> UR.init
                    |> UR.addPort
                        { responseAddress = GotAccountAvailabilityResponse isAvailable
                        , responseData = Encode.null
                        , data =
                            Encode.object
                                [ ( "name", Encode.string "generateKeys" )
                                , ( "account", Encode.string account )
                                ]
                        }

            else
                let
                    composeProblem form formType formField =
                        formType
                            { form
                                | problems = ( formField, t "error.alreadyTaken", OnSubmit ) :: form.problems
                            }
                            |> FormShowed

                    newStatus =
                        case model.status of
                            FormShowed (JuridicalForm form) ->
                                composeProblem form JuridicalForm JuridicalForm.Account

                            FormShowed (NaturalForm form) ->
                                composeProblem form NaturalForm NaturalForm.Account

                            FormShowed (DefaultForm form) ->
                                composeProblem form DefaultForm DefaultForm.Account

                            _ ->
                                model.status
                in
                { model | status = newStatus }
                    |> UR.init

        AccountKeysGenerated (Err v) ->
            UR.init
                model
                |> UR.logDecodeError msg v

        AccountKeysGenerated (Ok accountKeys) ->
            case model.status of
                FormShowed form ->
                    { model | accountKeys = Just accountKeys }
                        |> UR.init
                        |> UR.addCmd
                            (signUp shared
                                accountKeys
                                model.invitationId
                                form
                            )

                _ ->
                    model
                        |> UR.init

        AgreedToSave12Words val ->
            { model | hasAgreedToSavePassphrase = val }
                |> UR.init

        CopyToClipboard elementId ->
            model
                |> UR.init
                |> UR.addPort
                    { responseAddress = CopiedToClipboard
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "id", Encode.string elementId )
                            , ( "name", Encode.string "copyToClipboard" )
                            ]
                    }

        CopiedToClipboard ->
            { model | isPassphraseCopiedToClipboard = True }
                |> UR.init

        DownloadPdf { passphrase, accountName } ->
            model
                |> UR.init
                |> UR.addPort
                    { responseAddress = PdfDownloaded
                    , responseData = Encode.null
                    , data =
                        Encode.object
                            [ ( "name", Encode.string "downloadAuthPdfFromRegistration" )
                            , ( "accountName", Encode.string accountName )
                            , ( "passphrase", Encode.string passphrase )
                            ]
                    }

        PdfDownloaded ->
            model
                |> UR.init
                |> UR.addCmd
                    (Route.replaceUrl shared.navKey (Route.Login Nothing))

        CompletedSignUp (Ok response) ->
            case response.status of
                SignUpStatus.Success ->
                    case model.status of
                        FormShowed (DefaultForm _) ->
                            -- For Default form the account is already created
                            { model
                                | status = AccountCreated
                                , step = SavePassphrase
                            }
                                |> UR.init

                        FormShowed (NaturalForm form) ->
                            model
                                |> UR.init
                                |> UR.addCmd
                                    (saveKycData shared
                                        { accountId = form.account
                                        , countryId = Id "1"
                                        , document = form.document
                                        , documentType = NaturalForm.documentTypeToString form.documentType
                                        , phone = form.phone
                                        , userType = "natural"
                                        }
                                    )

                        FormShowed (JuridicalForm form) ->
                            model
                                |> UR.init
                                |> UR.addCmd
                                    (saveKycData shared
                                        { accountId = form.account
                                        , countryId = Id "1"
                                        , document = form.document
                                        , documentType = JuridicalForm.companyTypeToString form.companyType
                                        , phone = form.phone
                                        , userType = "juridical"
                                        }
                                    )

                        _ ->
                            model |> UR.init

                SignUpStatus.Error ->
                    UR.init
                        { model
                            | serverError = Just (t "register.account_error.title")
                        }

        CompletedSignUp (Err error) ->
            { model | serverError = Just (t "register.account_error.title") }
                |> UR.init
                |> UR.logGraphqlError msg error

        CompletedKycUpsert (Ok _) ->
            case model.status of
                FormShowed (JuridicalForm form) ->
                    -- Juridical account still needs the Address to be saved
                    let
                        addressData : ( InputObject.AddressUpdateInputRequiredFields, InputObject.AddressUpdateInputOptionalFields )
                        addressData =
                            ( { accountId = form.account
                              , cityId = Tuple.first form.city |> Id
                              , countryId = Id "1"
                              , neighborhoodId = Tuple.first form.district |> Id
                              , stateId = Tuple.first form.state |> Id
                              , street = form.street
                              , zip = form.zip
                              }
                            , { number = Graphql.OptionalArgument.Present form.number }
                            )
                    in
                    model
                        |> UR.init
                        |> UR.addCmd
                            (saveAddress shared addressData)

                FormShowed (NaturalForm _) ->
                    -- Natural account is fully created
                    { model
                        | status = AccountCreated
                        , step = SavePassphrase
                    }
                        |> UR.init

                _ ->
                    model |> UR.init

        CompletedKycUpsert (Err error) ->
            { model
                | serverError = Just (t "register.form.error.kyc_problem")
            }
                |> UR.init
                |> UR.logGraphqlError msg error
                |> scrollTop

        CompletedAddressUpsert (Ok _) ->
            -- Address is saved, Juridical account is created.
            { model
                | status = AccountCreated
                , step = SavePassphrase
            }
                |> UR.init

        CompletedAddressUpsert (Err error) ->
            UR.init
                { model | serverError = Just (t "register.form.error.address_problem") }
                |> UR.logGraphqlError msg error
                |> scrollTop

        CompletedLoadInvite (Ok (Just invitation)) ->
            if invitation.community.hasKyc then
                let
                    loadCountryData =
                        Api.Graphql.query
                            shared
                            (Address.countryQuery "Costa Rica")
                            CompletedLoadCountry
                in
                { model
                    | status = Loading
                    , invitation = Just invitation
                }
                    |> UR.init
                    |> UR.addCmd
                        loadCountryData

            else
                { model
                    | status = FormShowed (DefaultForm DefaultForm.init)
                    , invitation = Just invitation
                }
                    |> UR.init

        CompletedLoadInvite (Ok Nothing) ->
            UR.init { model | status = NotFound }

        CompletedLoadInvite (Err error) ->
            { model
                | status = ErrorShowed (FailedInvite error)
                , serverError = Just (t "error.unknown")
            }
                |> UR.init
                |> UR.logGraphqlError msg error

        CompletedLoadCountry (Ok (Just country)) ->
            { model
                | country = Just country
                , status = AccountTypeSelectorShowed
            }
                |> UR.init

        CompletedLoadCountry (Ok Nothing) ->
            UR.init { model | status = NotFound }

        CompletedLoadCountry (Err error) ->
            { model | status = ErrorShowed (FailedCountry error) }
                |> UR.init
                |> UR.logGraphqlError msg error


type alias SignUpResponse =
    { reason : Maybe String
    , status : SignUpStatus.SignUpStatus
    }


signUp : Shared -> AccountKeys -> InvitationId -> FormModel -> Cmd Msg
signUp shared { accountName, ownerKey } invitationId form =
    let
        { email, name } =
            getSignUpFields form

        requiredArgs =
            { account = Eos.nameToString accountName
            , email = email
            , name = name
            , publicKey = ownerKey
            , userType =
                case form of
                    JuridicalForm _ ->
                        "juridical"

                    _ ->
                        "natural"
            }

        fillOptionals opts =
            { opts
                | invitationId =
                    Maybe.map Present invitationId
                        |> Maybe.withDefault Absent
                , kyc = Absent
                , address = Absent
            }
    in
    Api.Graphql.mutation shared
        (Mutation.signUp
            fillOptionals
            requiredArgs
            (Graphql.SelectionSet.succeed SignUpResponse
                |> with Cambiatus.Object.SignUpResponse.reason
                |> with Cambiatus.Object.SignUpResponse.status
            )
        )
        CompletedSignUp


saveKycData : Shared -> InputObject.KycDataUpdateInputRequiredFields -> Cmd Msg
saveKycData shared requiredFields =
    Api.Graphql.mutation shared
        (Mutation.upsertKyc
            { input = InputObject.buildKycDataUpdateInput requiredFields }
            Graphql.SelectionSet.empty
        )
        CompletedKycUpsert


saveAddress :
    Shared
    -> ( InputObject.AddressUpdateInputRequiredFields, InputObject.AddressUpdateInputOptionalFields )
    -> Cmd Msg
saveAddress shared ( required, optional ) =
    Api.Graphql.mutation shared
        (Mutation.upsertAddress
            { input = InputObject.buildAddressUpdateInput required (\_ -> optional) }
            Graphql.SelectionSet.empty
        )
        CompletedAddressUpsert



-- INTEROP


jsAddressToMsg : List String -> Value -> Maybe Msg
jsAddressToMsg addr val =
    case addr of
        "ValidateForm" :: _ ->
            Decode.decodeValue
                (Decode.field "isAvailable" Decode.bool)
                val
                |> Result.map GotAccountAvailabilityResponse
                |> Result.toMaybe

        "GotAccountAvailabilityResponse" :: _ ->
            let
                decodeAccount : Decoder AccountKeys
                decodeAccount =
                    Decode.succeed AccountKeys
                        |> Decode.required "ownerKey" Decode.string
                        |> Decode.required "activeKey" Decode.string
                        |> Decode.required "accountName" Eos.nameDecoder
                        |> Decode.required "words" Decode.string
                        |> Decode.required "privateKey" Decode.string
            in
            Decode.decodeValue (Decode.field "data" decodeAccount) val
                |> AccountKeysGenerated
                |> Just

        "PdfDownloaded" :: _ ->
            Just PdfDownloaded

        "CopiedToClipboard" :: _ ->
            Just CopiedToClipboard

        _ ->
            Nothing


msgToString : Msg -> List String
msgToString msg =
    case msg of
        NoOp ->
            [ "NoOp" ]

        FormMsg _ ->
            [ "FormMsg" ]

        ValidateForm _ ->
            [ "ValidateForm" ]

        GotAccountAvailabilityResponse _ ->
            [ "GotAccountAvailabilityResponse" ]

        AccountKeysGenerated r ->
            [ "AccountKeysGenerated", UR.resultToString r ]

        AgreedToSave12Words _ ->
            [ "AgreedToSave12Words" ]

        CopyToClipboard _ ->
            [ "CopyToClipboard" ]

        CopiedToClipboard ->
            [ "CopiedToClipboard" ]

        DownloadPdf _ ->
            [ "DownloadPdf" ]

        PdfDownloaded ->
            [ "PdfDownloaded" ]

        CompletedLoadInvite _ ->
            [ "CompletedLoadInvite" ]

        AccountTypeSelected _ ->
            [ "AccountTypeSelected" ]

        CompletedSignUp _ ->
            [ "CompletedSignUp" ]

        CompletedLoadCountry _ ->
            [ "CompletedLoadCountry" ]

        CompletedKycUpsert _ ->
            [ "CompletedKycUpsert" ]

        CompletedAddressUpsert _ ->
            [ "CompletedAddressUpsert" ]
