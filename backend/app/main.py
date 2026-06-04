"""Entry point FastAPI untuk autentikasi mobile_app (Bullet Detection)."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routers import auth

app = FastAPI(
    title="Bullet Detection - Auth API",
    description="API login & register untuk mobile_app (Flutter).",
    version="1.0.0",
)

# Izinkan akses dari Flutter (web/Chrome, emulator, HP) tanpa batasan origin.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api")


@app.get("/")
def root():
    return {"status": "ok", "service": "bullet-detection-auth"}


@app.get("/api/health")
def health():
    return {"status": "healthy"}
