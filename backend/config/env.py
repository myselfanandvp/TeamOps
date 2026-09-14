from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    secret_key: str = "dummy-secret-key-for-testing"
    debug: bool = False
    db_name: str = "teamops"
    db_user: str = "postgres"
    db_pass: str = "dummy-password"
    db_host: str = "localhost"
    db_port: int = 5432

    model_config = SettingsConfigDict(
        extra="ignore",
        env_file="../.env",
    )


settings = Settings()  # pyright: ignore[reportCallIssue]
