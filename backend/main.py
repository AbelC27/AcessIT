from fastapi import FastAPI, HTTPException, Query
from datetime import datetime
from supabase_client import fetch_user_by_ble, log_access, get_log_by_id, update_log_status
import uuid

app = FastAPI()

def is_now_in_schedule(schedule: str) -> bool:
    try:
        start, end = schedule.split('-')
        now = datetime.now().time()
        start_h, start_m = map(int, start.split(':'))
        end_h, end_m = map(int, end.split(':'))
        start_time = datetime.now().replace(hour=start_h, minute=start_m, second=0, microsecond=0).time()
        end_time = datetime.now().replace(hour=end_h, minute=end_m, second=0, microsecond=0).time()
        return start_time <= now <= end_time
    except Exception as e:
        print(f"Schedule parse error: {e}")
        return True  # dacă nu e setat, nu restricționăm

@app.post("/validate")
async def validate_access(ble_code: str):
    users = await fetch_user_by_ble(ble_code)
    if not users:
        raise HTTPException(status_code=404, detail="User not found")

    user = users[0]
    allowed_schedule = user.get("allowed_schedule", "08:00-18:00")
    log_id = str(uuid.uuid4())

    if is_now_in_schedule(allowed_schedule):
        # În program, acces direct
        log = {
            "id": log_id,
            "user_id": user["id"],
            "timestamp": datetime.utcnow().isoformat(),
            "direction": "entry",
            "is_visitor": False,
            "status": "granted",
            "message": "Acces permis"
        }
        await log_access(log)
        return {"granted": True, "message": "Acces permis!", "log_id": log_id}
    else:
        # În afara programului, pending
        log = {
            "id": log_id,
            "user_id": user["id"],
            "timestamp": datetime.utcnow().isoformat(),
            "direction": "entry",
            "is_visitor": False,
            "status": "pending",
            "message": "pending"
        }
        await log_access(log)
        return {"granted": False, "message": "pending", "log_id": log_id}

@app.get("/check-access-status")
async def check_access_status(log_id: str = Query(...)):
    log = await get_log_by_id(log_id)
    if not log:
        raise HTTPException(status_code=404, detail="Log not found")
    # Returnează statusul curent
    return {
        "granted": log["status"] == "granted",
        "message": log["message"]
    }

# Pentru test: endpoint să aprobi/respingi manual
@app.post("/approve")
async def approve_access(log_id: str, approve: bool):
    status = "granted" if approve else "denied"
    message = "Acces permis de admin" if approve else "Acces respins de admin"
    await update_log_status(log_id, status, message)
    return {"ok": True}