FROM python:3.12-slim-trixie

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/ 

WORKDIR /app

ENV PATH="$HOME/.local/bin:$PATH"

COPY ./pyproject.toml ./uv.lock /

ENV UV_PROJECT_ENVIRONMENT=/opt/venv

ENV PATH="/opt/venv/bin:$PATH"

RUN uv sync --locked --no-install-project

EXPOSE 8000

COPY . .

CMD [ "uv","run","manage.py","runserver","0.0.0.0:8000" ]


