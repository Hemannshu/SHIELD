from flask import Flask, request, jsonify

app = Flask(__name__)

EMOTIONS = ["happy", "sad", "angry", "fear", "neutral"]


def simple_emotion_scores(text: str):
    """
    Lightweight, rule-based mock classifier so the API
    works without external model files.
    """
    text_l = text.lower()
    scores = {e: 0.1 for e in EMOTIONS}

    if any(w in text_l for w in ["happy", "glad", "joy", "excited"]):
        scores["happy"] += 0.6
    if any(w in text_l for w in ["sad", "upset", "down", "depressed"]):
        scores["sad"] += 0.6
    if any(w in text_l for w in ["angry", "mad", "furious"]):
        scores["angry"] += 0.6
    if any(w in text_l for w in ["scared", "afraid", "fear", "terrified"]):
        scores["fear"] += 0.6

    # Normalize to probabilities
    total = sum(scores.values())
    return {k: v / total for k, v in scores.items()} if total > 0 else scores


@app.route("/predict", methods=["POST"])
def predict():
    data = request.get_json(force=True) or {}
    text = data.get("text", "")

    scores = simple_emotion_scores(text)
    # Sort and take top 3
    sorted_items = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:3]

    results = [
        {"emotion": emotion, "probability": float(prob)}
        for emotion, prob in sorted_items
    ]

    return jsonify(results)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)