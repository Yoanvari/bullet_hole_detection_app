"""Setup koneksi database menggunakan SQLAlchemy."""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from .config import settings

# pool_pre_ping=True -> cek koneksi sebelum dipakai (hindari "MySQL gone away").
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    echo=False,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """Dependency FastAPI: menyediakan satu sesi DB per request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
