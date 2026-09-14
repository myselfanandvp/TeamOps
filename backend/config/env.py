from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    secret_key: str
    debug: bool
    db_name: str
    db_user: str
    db_pass: str
    db_host: str
    db_port: int

    model_config = SettingsConfigDict(
        extra="ignore",
    )


settings = Settings()  # pyright: ignore[reportCallIssue]
