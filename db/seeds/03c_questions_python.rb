# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Python Space
# =============================================================================
puts "Creating Python questions..."

python_space = Space.find_by!(slug: "python")

# Expert Python question
create_qa(
  space: python_space,
  author: SEED_EXPERTS["prof.aisha.patel@example.com"],
  title: "Type hints for decorators that preserve function signatures in Python 3.11+",
  body: <<~BODY,
    I'm struggling with properly typing a decorator that preserves the original function's signature. With Python 3.11+ and `ParamSpec`, I expected this to work:

    ```python
    from typing import Callable, ParamSpec, TypeVar
    from functools import wraps

    P = ParamSpec('P')
    R = TypeVar('R')

    def logged(func: Callable[P, R]) -> Callable[P, R]:
        @wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            print(f"Calling {func.__name__}")
            return func(*args, **kwargs)
        return wrapper

    @logged
    def greet(name: str, excited: bool = False) -> str:
        return f"Hello, {name}{'!' if excited else '.'}"
    ```

    But mypy still complains when I call `greet(123)` - it should catch that `123` isn't a string, but it doesn't.

    What am I missing with `ParamSpec`?
  BODY
  answers: [
    {
      author: SEED_EXPERTS["architect.lisa@example.com"],
      body: <<~ANSWER,
        Your decorator is actually correct! The issue is likely with your mypy configuration or version. Let me verify:

        ```python
        from typing import Callable, ParamSpec, TypeVar
        from functools import wraps

        P = ParamSpec('P')
        R = TypeVar('R')

        def logged(func: Callable[P, R]) -> Callable[P, R]:
            @wraps(func)
            def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
                print(f"Calling {func.__name__}")
                return func(*args, **kwargs)
            return wrapper

        @logged
        def greet(name: str, excited: bool = False) -> str:
            return f"Hello, {name}{'!' if excited else '.'}"

        # This SHOULD be an error
        greet(123)  # mypy: Argument 1 to "greet" has incompatible type "int"; expected "str"
        ```

        I tested with mypy 1.5+ and it correctly catches the error. Check:

        1. **mypy version**: `mypy --version` (need 0.950+ for full ParamSpec support)
        2. **Python version in config**: Make sure `python_version = "3.11"` in mypy.ini
        3. **Strict mode**: Try running with `mypy --strict`

        If you're using pyright/pylance instead, they have excellent ParamSpec support.

        **Common gotcha**: If you're testing in a REPL or notebook, type checkers don't run there - you need to run mypy on the actual file.
      ANSWER
      votes: 19,
      correct: true
    }
  ],
  created_ago: 18.days
)

# FastAPI vs Django question
create_qa(
  space: python_space,
  author: SEED_INTERMEDIATES["coder.ian@example.com"],
  title: "FastAPI vs Django REST Framework for new API project?",
  body: <<~BODY,
    Starting a new backend API project. Team has Django experience but FastAPI looks interesting.

    Requirements:
    - REST API with ~30 endpoints
    - PostgreSQL database
    - Background tasks
    - WebSocket support for notifications
    - OpenAPI documentation

    Which framework would you recommend and why?
  BODY
  answers: [
    {
      author: SEED_EXPERTS["tech.lead.omar@example.com"],
      body: <<~ANSWER,
        **FastAPI** for greenfield API-only projects:

        ```python
        from fastapi import FastAPI
        from pydantic import BaseModel

        app = FastAPI()

        class User(BaseModel):
            name: str
            email: str

        @app.post("/users")
        async def create_user(user: User):
            return {"id": 1, **user.dict()}
        ```

        **Pros:**
        - Native async support
        - Auto-generated OpenAPI docs
        - Pydantic validation is amazing
        - WebSockets built-in
        - 3-5x faster than DRF

        **Cons:**
        - Less mature ecosystem
        - No built-in ORM (use SQLAlchemy)
        - Smaller community

        For your use case with WebSocket requirement, FastAPI is the better choice.
      ANSWER
      votes: 42,
      correct: false
    },
    {
      author: SEED_EXPERTS["distinguished.eng@example.com"],
      body: <<~ANSWER,
        Given your **team has Django experience**, I'd lean toward **Django REST Framework**:

        **DRF advantages:**
        - Team productivity from day one
        - Battle-tested at massive scale
        - Rich ecosystem (permissions, filtering, pagination)
        - Django ORM is mature and well-understood

        **For your requirements:**
        - REST endpoints: DRF excels here
        - PostgreSQL: Django ORM is excellent
        - Background tasks: Celery integrates seamlessly
        - WebSockets: Django Channels works fine
        - OpenAPI: drf-spectacular generates great docs

        ```python
        # DRF is very productive
        class UserViewSet(viewsets.ModelViewSet):
            queryset = User.objects.all()
            serializer_class = UserSerializer
            permission_classes = [IsAuthenticated]
            filter_backends = [DjangoFilterBackend]
        ```

        FastAPI is great, but the learning curve + building from scratch (auth, permissions, etc.) will cost you 2-3 months.
      ANSWER
      votes: 28,
      correct: true
    }
  ],
  created_ago: 6.days
)

puts "  Created Python questions"
