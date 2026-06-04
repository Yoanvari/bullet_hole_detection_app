"""Utilitas hashing password menggunakan bcrypt."""
import bcrypt


def hash_password(plain_password: str) -> str:
    """Hash password plaintext menjadi string bcrypt (siap disimpan ke DB)."""
    # bcrypt bekerja dengan bytes; batas maksimal 72 byte.
    pwd_bytes = plain_password.encode("utf-8")
    salt = bcrypt.gensalt(rounds=12)
    hashed = bcrypt.hashpw(pwd_bytes, salt)
    return hashed.decode("utf-8")


def verify_password(plain_password: str, password_hash: str) -> bool:
    """Cek apakah password plaintext cocok dengan hash di database."""
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"),
            password_hash.encode("utf-8"),
        )
    except (ValueError, TypeError):
        # Hash tidak valid / format salah
        return False
