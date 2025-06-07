from fastapi import FastAPI, UploadFile, File, HTTPException
from PIL import Image
import torch
from torchvision import models, transforms
# Import EfficientNet_B0_Weights
from torchvision.models import EfficientNet_B0_Weights 
import torch.nn.functional as F
import io
import os

app = FastAPI()

# Device configuration
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Load the EfficientNet-B0 pretrained model architecture
# Use efficientnet_b0 and EfficientNet_B0_Weights
weights = EfficientNet_B0_Weights.DEFAULT 
model = models.efficientnet_b0(weights=weights) 

# Modify the classifier for 16 classes (must match training)
num_classes = 16
model.classifier[1] = torch.nn.Linear(model.classifier[1].in_features, num_classes)

# Load your saved EfficientNet-B0 weights
# Use the model path you provided
model_path = r'D:\Python\efficientnet_b0_rvl_cdip_small_200.pth' 

# Check if the model file exists
if not os.path.exists(model_path):
    # Raise an error if the file is not found
    raise FileNotFoundError(f"Model file not found at {model_path}. Please ensure the path is correct.")

# Load the state dictionary
try:
    model.load_state_dict(torch.load(model_path, map_location=device))
except RuntimeError as e:
    raise RuntimeError(f"Error loading model state_dict: {e}. This might be due to mismatch in model architecture or corrupted file.")

model.to(device)
model.eval()

# Define the same transform as training
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.Grayscale(num_output_channels=3),  # convert grayscale to 3-channel
    transforms.ToTensor(),
    transforms.Normalize([0.5]*3, [0.5]*3)
])

# Define the class mapping (replace with your actual class mapping)
# You can get this from your training code, e.g., train_dataset.class_to_idx
# This is an example, make sure it matches your dataset
class_to_idx = {'advertisement': 0, 'budget': 1, 'email': 2, 'file_folder': 3, 'form': 4, 'handwritten': 5, 'invoice': 6, 'letter': 7, 'memo': 8, 'news_article': 9, 'note': 10, 'report': 11, 'resume': 12, 'scientific_publication': 13, 'specification': 14, 'thesis': 15}
idx_to_class = {v: k for k, v in class_to_idx.items()}


@app.post("/predict/")
async def predict_image(file: UploadFile = File(...)):
    """
    Predicts the top 3 classes for an uploaded image.
    """
    try:
        # Read the image file
        image_bytes = await file.read()
        img = Image.open(io.BytesIO(image_bytes)).convert('RGB')

        # Apply the same transform as training
        img_tensor = transform(img).unsqueeze(0).to(device)

        # Prediction
        with torch.no_grad():
            outputs = model(img_tensor)
            probabilities = F.softmax(outputs, dim=1)
            top_p, top_class_indices = probabilities.topk(3, dim=1)

        top_p = top_p.squeeze().tolist()
        top_class_indices = top_class_indices.squeeze().tolist()

        # Ensure top_class_indices is a list even if only one result is returned
        if not isinstance(top_class_indices, list):
            top_class_indices = [top_class_indices]
            top_p = [top_p]


        # Get class labels
        predicted_labels = [idx_to_class[idx] for idx in top_class_indices]

        results = []
        for i in range(len(predicted_labels)):
            results.append({
                "class": predicted_labels[i],
                "confidence": top_p[i]
            })

        return {"predictions": results}

    except Exception as e:
        # Log the error for debugging
        print(f"An error occurred during prediction: {e}")
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {e}")

# To run this FastAPI application locally:
# 1. Save the code as a Python file (e.g., main.py)
# 2. Install necessary libraries: pip install fastapi uvicorn python-multipart torch torchvision Pillow
# 3. Run the server from your terminal: uvicorn main:app --reload
# 4. Access the API at http://127.0.0.1:8000/docs (FastAPI's interactive documentation)
