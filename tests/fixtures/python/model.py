from pydantic import BaseModel


class Greeting(BaseModel):
    name: str


def greet(greeting: Greeting) -> str:
    return f"hello {greeting.name}"


print(greet(Greeting(name="world")))
