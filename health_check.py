from flask import Flask
import threading
import requests
import time
import subprocess
import os

app = Flask(__name__)

# === CONFIG ===
APP_URL = "https://hello-python-happy-bongo-mr.cfapps.ap21.hana.ondemand.com/"  # replace with your deployed app URL
CHECK_INTERVAL = 60  # seconds
FAILOVER_SCRIPT = "./automation.sh"

# === State Tracking ===
has_triggered_failover = False

def health_check_loop():
    global has_triggered_failover

    while True:
        try:
            print(f"🔍 Checking health of {APP_URL} ...")
            response = requests.get(APP_URL, timeout=10)
            if response.status_code == 200:
                print("✅ App is healthy.")
                has_triggered_failover = False  # reset if app recovers
            else:
                print(f"⚠️ Unexpected status: {response.status_code}")
                trigger_failover()
        except requests.RequestException as e:
            print(f"❌ App check failed: {e}")
            trigger_failover()

        time.sleep(CHECK_INTERVAL)

def trigger_failover():
    global has_triggered_failover

    if has_triggered_failover:
        print("⏳ Failover already triggered. Waiting for recovery...")
        return

    print("🚨 App is DOWN! Triggering failover...")
    try:
        result = subprocess.run(["bash", FAILOVER_SCRIPT], capture_output=True, text=True)
        print("📜 Failover script output:")
        print(result.stdout)
        if result.returncode != 0:
            print("❌ Failover failed:", result.stderr)
        else:
            print("✅ Failover completed.")
            has_triggered_failover = True
    except Exception as e:
        print("⚠️ Error running failover script:", e)

@app.route("/health-monitor")
def monitor():
    return "Health check service is running", 200

if __name__ == "__main__":
    print("🚀 Starting Flask health check service...")
    thread = threading.Thread(target=health_check_loop)
    thread.daemon = True
    thread.start()
    app.run(host="0.0.0.0", port=5000)
