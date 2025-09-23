import json, datetime; print("Script running")
with open("events.json", "r") as f: data = json.load(f)
now = datetime.datetime.now(datetime.timezone.utc); print(f"Current time (UTC): {now.isoformat()}")
upcoming = []
