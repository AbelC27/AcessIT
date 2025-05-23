#/backend/main.py
from fastapi import FastAPI, HTTPException
from datetime import datetime
from supabase_client import fetch_user_by_ble, log_access

app = FastAPI()

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
    return {"status": "granted", "user": user["name"]}
