"""Konfigurasi aplikasi: dibaca dari file .env."""
import os
from dotenv import load_dotenv

# Muat variabel dari .env yang berada di folder backend/
load_dotenv()


class Settings:
    DB_HOST: str = os.getenv("DB_HOST", "localhost")
    DB_PORT: int = int(os.getenv("DB_PORT", "3306"))
    DB_USER: str = os.getenv("DB_USER", "root")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "")
    DB_NAME: str = os.getenv("DB_NAME", "bullet_detection")

    API_HOST: str = os.getenv("API_HOST", "0.0.0.0")
    API_PORT: int = int(os.getenv("API_PORT", "8000"))

    @property
    def database_url(self) -> str:
        # PyMySQL sebagai driver. quote_plus dipakai agar password
        # yang mengandung karakter khusus tetap aman.
        from urllib.parse import quote_plus

        pwd = quote_plus(self.DB_PASSWORD)
        return (
            f"mysql+pymysql://{self.DB_USER}:{pwd}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}?charset=utf8mb4"
        )


settings = Settings()
