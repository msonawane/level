module ResolvedReply exposing (ResolvedReply, addManyToRepo, addToRepo, decoder, resolve, unresolve)

import Actor exposing (Actor)
import Connection exposing (Connection)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Reply exposing (Reply)
import Repo exposing (Repo)
import SpaceUser exposing (SpaceUser)


type alias ResolvedReply =
    { reply : Reply
    , author : Actor
    , reactors : List SpaceUser
    }


decoder : Decoder ResolvedReply
decoder =
    Decode.map3 ResolvedReply
        Reply.decoder
        (field "author" Actor.decoder)
        (Decode.at [ "reactions", "edges" ] (list <| Decode.at [ "node", "spaceUser" ] SpaceUser.decoder))


addToRepo : ResolvedReply -> Repo -> Repo
addToRepo resolvedReply repo =
    repo
        |> Repo.setReply resolvedReply.reply
        |> Repo.setActor resolvedReply.author
        |> Repo.setSpaceUsers resolvedReply.reactors


addManyToRepo : List ResolvedReply -> Repo -> Repo
addManyToRepo resolvedReplies repo =
    List.foldr addToRepo repo resolvedReplies


resolve : Repo -> Id -> Maybe ResolvedReply
resolve repo id =
    case Repo.getReply id repo of
        Just reply ->
            Maybe.map3 ResolvedReply
                (Just <| reply)
                (Repo.getActor (Reply.authorId reply) repo)
                (Just <| Repo.getSpaceUsers (Reply.reactorIds reply) repo)

        Nothing ->
            Nothing


unresolve : ResolvedReply -> Id
unresolve resolvedReply =
    Reply.id resolvedReply.reply
