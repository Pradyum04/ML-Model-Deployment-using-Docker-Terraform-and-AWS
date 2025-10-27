from flask import Flask, request, jsonify
import joblib
import numpy as np
import os

# Initialize Flask app
app = Flask(__name__)

# Load the trained model
model_path = os.path.join(os.path.dirname(__file__), '../model/model.pkl')
model = joblib.load(model_path)

# Define class labels (Iris dataset target names)
class_labels = ["setosa", "versicolor", "virginica"]

@app.route('/')
def home():
    return "🌸 Iris Flower Prediction API is Running!"

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Example input: {"features": [5.1, 3.5, 1.4, 0.2]}
        data = request.get_json(force=True)
        
        if "features" not in data:
            return jsonify({"error": "Missing 'features' key in request JSON"}), 400
        
        # Convert features to numpy array and reshape for single prediction
        features = np.array(data["features"]).reshape(1, -1)

        # Make prediction
        prediction = model.predict(features)
        predicted_class = class_labels[prediction[0]]

        # Optionally add probabilities
        probabilities = model.predict_proba(features).tolist()[0]

        return jsonify({
            "predicted_class": predicted_class,
            "class_probabilities": dict(zip(class_labels, probabilities))
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    # Run on 0.0.0.0 for Docker / AWS compatibility
    app.run(host="0.0.0.0", port=5000, debug=True)
