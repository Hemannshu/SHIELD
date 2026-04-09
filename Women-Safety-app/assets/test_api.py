"""
SHEILD Backend API - Unit Tests
Validates emotion prediction endpoint and edge cases.
Run: python test_api.py
"""

import sys
import json

# Import the Flask app
from api import app

client = app.test_client()

passed = 0
failed = 0


def test(name, condition):
    global passed, failed
    if condition:
        print(f"  PASS  {name}")
        passed += 1
    else:
        print(f"  FAIL  {name}")
        failed += 1


print("=" * 50)
print("SHEILD Backend API Tests")
print("=" * 50)

# --- Test 1: Predict endpoint returns 200 ---
resp = client.post("/predict",
                   data=json.dumps({"text": "I am happy"}),
                   content_type="application/json")
test("POST /predict returns 200", resp.status_code == 200)

# --- Test 2: Response is a list of emotions ---
data = resp.get_json()
test("Response is a list", isinstance(data, list))
test("Returns top 3 emotions", len(data) == 3)

# --- Test 3: Each result has emotion and probability ---
if data:
    item = data[0]
    test("Has 'emotion' key", "emotion" in item)
    test("Has 'probability' key", "probability" in item)
    test("Probability is a float", isinstance(item["probability"], float))

# --- Test 4: Happy text returns happy as top emotion ---
resp = client.post("/predict",
                   data=json.dumps({"text": "I am so happy and glad"}),
                   content_type="application/json")
data = resp.get_json()
test("Happy text -> top emotion is 'happy'", data[0]["emotion"] == "happy")

# --- Test 5: Fear text returns fear as top emotion ---
resp = client.post("/predict",
                   data=json.dumps({"text": "I am scared and terrified"}),
                   content_type="application/json")
data = resp.get_json()
test("Fear text -> top emotion is 'fear'", data[0]["emotion"] == "fear")

# --- Test 6: Empty text still returns valid response ---
resp = client.post("/predict",
                   data=json.dumps({"text": ""}),
                   content_type="application/json")
test("Empty text returns 200", resp.status_code == 200)
data = resp.get_json()
test("Empty text returns list", isinstance(data, list))

# --- Test 7: Missing text field handled ---
resp = client.post("/predict",
                   data=json.dumps({}),
                   content_type="application/json")
test("Missing 'text' field returns 200", resp.status_code == 200)

# --- Test 8: Probabilities sum to ~1.0 ---
resp = client.post("/predict",
                   data=json.dumps({"text": "neutral test"}),
                   content_type="application/json")
data = resp.get_json()
total = sum(item["probability"] for item in data)
test("Top 3 probabilities are valid (0 < sum <= 1)", 0 < total <= 1.01)

# --- Summary ---
print("=" * 50)
print(f"Results: {passed} passed, {failed} failed, {passed + failed} total")
print("=" * 50)

sys.exit(0 if failed == 0 else 1)
