"""Model SQLAlchemy yang memetakan tabel `users` (lihat database/schema.sql)."""
from sqlalchemy import (
    BigInteger,
    Column,
    DateTime,
    Enum,
    SmallInteger,
    String,
    func,
)

from .database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    username = Column(String(50), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)  # hash bcrypt
    full_name = Column(String(100), nullable=False)
    email = Column(String(120), nullable=True, unique=True)
    role = Column(
        Enum("shooter", "instructor"),
        nullable=False,
        default="shooter",
    )
    avatar_path = Column(String(255), nullable=True)
    # TINYINT(1) di MySQL -> SmallInteger sudah cukup
    is_active = Column(SmallInteger, nullable=False, default=1)
    last_login_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
