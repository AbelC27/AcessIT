#/backend/supabase_client.py
import httpx
import os
from datetime import datetime
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException

# Create FastAPI app
app = FastAPI()

# Load environment variables
load_dotenv()

# Constants
ESP32_URL = "http://192.168.137.35/unlock"
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json"
}

async def fetch_user_by_ble(code: str):
    async with httpx.AsyncClient() as client:
        res = await client.get(
            f"{SUPABASE_URL}/rest/v1/employees?bluetooth_code=eq.{code}&select=*",
            headers=headers
        )
        return res.json()

async def log_access(entry: dict):
    async with httpx.AsyncClient() as client:
        return await client.post(
            f"{SUPABASE_URL}/rest/v1/access_logs",
            headers=headers,
            json=entry
        )

@app.post("/validate")
async def validate_access(ble_code: str):
    users = await fetch_user_by_ble(ble_code)
    if not users:
        raise HTTPException(status_code=404, detail="User not found")

    user = users[0]
    log = {
        "user_id": user["id"],
        "timestamp": datetime.utcnow().isoformat(),
        "direction": "entry",
        "is_visitor": False
    }
    await log_access(log)

    # Trimite user_id la ESP32
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            ESP32_URL,
            json={"user_id": user["id"]}
        )
        resp.raise_for_status()

    return {"status": "granted", "user": user["name"]}