from __future__ import annotations
from fastapi import FastAPI
from typing import Optional
from pydantic import BaseModel
from dataclasses import dataclass


class Poll(BaseModel):
    name: str
    items: list[str]


class Vote(BaseModel):
    poll_id: int
    item_name: str


@dataclass
class PollInternal:
    poll_id: int
    name: str
    items: [str]
    votes: dict[int, VoteInternal]


@dataclass
class VoteInternal:
    vote_id: int
    poll_id: int
    item_name: str


app = FastAPI()

polls: dict[int, PollInternal] = {}
max_poll_id = 0
max_vote_id = 0


@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.get("/poll")
async def get_polls():
    return polls


@app.post("/poll")
async def create_poll(poll: Poll):
    poll = internal_poll(poll)
    polls[poll.poll_id] = poll


@app.get("/poll/{poll_id}")
async def get_poll_summary(poll_id: int):
    poll = polls[poll_id]
    return {
        "name": poll.name,
        "item_votes": get_items_votes(poll.votes, poll.items)
    }


@app.get("/poll/{poll_id}/vote")
async def get_poll_votes(poll_id: int):
    return polls[poll_id].votes


@app.post("/poll/{poll_id}/vote/{item_name}")
async def create_poll_vote(poll_id: int, item_name: str):
    vote = internal_vote(poll_id, item_name)
    polls[poll_id].votes[vote.vote_id] = vote
    return polls[poll_id].votes


@app.delete("/poll/{poll_id}/vote/{vote_id}")
async def delete_vote(poll_id: int, vote_id: int):
    polls[poll_id].votes.pop(vote_id)
    return polls[poll_id].votes


def get_items_votes(votes: dict[int, VoteInternal], items: [str]) -> dict[str, int]:
    item_votes = {item: 0 for item in items}
    for vote in votes.values():
        item_votes[vote.item_name] += 1

    return item_votes


def internal_poll(poll: Poll) -> PollInternal:
    global max_poll_id
    poll_id = max_poll_id
    max_poll_id += 1

    return PollInternal(poll_id, poll.name, poll.items, {})


def internal_vote(poll_id: int, item_name: str) -> VoteInternal:
    global max_vote_id
    vote_id = max_vote_id
    max_vote_id += 1

    return VoteInternal(vote_id, poll_id, item_name)
