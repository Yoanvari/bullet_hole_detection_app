from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import os

app = FastAPI()

# Izinkan akses dari perangkat luar (HP)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Folder tempat menyimpan foto tembakan
SHOTS_DIR = "web_server/static/shots"
if not os.path.exists(SHOTS_DIR):
    os.makedirs(SHOTS_DIR)

# Mount folder agar gambar bisa diakses lewat URL browser/HP
app.mount("/static", StaticFiles(directory="web_server/static"), name="static")

# List untuk menampung data tembakan (id, url, waktu)
captured_shots = []

@app.get("/api/shots")
async def get_shots():
    # Mengirimkan 10 tembakan terbaru ke Flutter
    return captured_shots[-10:]

@app.post("/api/add_shot")
async def add_shot(filename: str, time_str: str):
    new_data = {
        "id": len(captured_shots) + 1,
        "image_url": f"http://192.168.100.23:8000/static/shots/{filename}",
        "time": time_str
    }
    captured_shots.append(new_data)
    return {"status": "success"}

if __name__ == "__main__":
    import uvicorn
    # Jalankan server di port 8000
    uvicorn.run(app, host="0.0.0.0", port=8000)