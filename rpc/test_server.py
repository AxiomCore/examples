from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()


class Person(BaseModel):
    id: str
    name: str


class CollectionRequest(BaseModel):
    person_id: str
    max_results: int


@app.get("/people/{person_id}", response_model=Person)
def get_person(person_id: str):
    return Person(id=person_id, name="Example person")


@app.post("/collections")
def create_collection(req: CollectionRequest):
    return {
        "message": f"Fetched {req.max_results} contacts for person {req.person_id} via RPC!"
    }
