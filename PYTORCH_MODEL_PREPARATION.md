# PyTorch Model Preparation Guide

## Converting Your Model to TorchScript for Mobile

Your trained PyTorch model needs to be converted to TorchScript format (`.pt` file) to work with the `pytorch_lite` Flutter package.

## Step 1: Export Your Model to TorchScript

Here's a Python script to convert your model:

```python
import torch
import torch.nn as nn
from torchvision import models

# Load your trained model
# Replace this with your actual model loading code
model = models.mobilenet_v2(pretrained=False)
model.classifier[1] = nn.Linear(model.last_channel, 38)  # 38 classes

# Load your trained weights
model.load_state_dict(torch.load('your_model_weights.pth'))
model.eval()

# Set the model to evaluation mode
model.eval()

# Create a sample input tensor (batch_size=1, channels=3, height=224, width=224)
example_input = torch.rand(1, 3, 224, 224)

# Trace the model
traced_model = torch.jit.trace(model, example_input)

# Save the traced model
traced_model.save('mobile_plantnet_scripted.pt')

print("Model successfully converted to TorchScript!")
print(f"Model saved as: mobile_plantnet_scripted.pt")
```

## Step 2: Verify Your Model

```python
import torch

# Load the saved model
loaded_model = torch.jit.load('mobile_plantnet_scripted.pt')
loaded_model.eval()

# Test with random input
test_input = torch.rand(1, 3, 224, 224)
output = loaded_model(test_input)

print(f"Model output shape: {output.shape}")
print(f"Expected shape: torch.Size([1, 38])")

# Get top prediction
probabilities = torch.nn.functional.softmax(output[0], dim=0)
top_prob, top_class = torch.max(probabilities, dim=0)

print(f"\nTop prediction:")
print(f"  Class index: {top_class.item()}")
print(f"  Confidence: {top_prob.item() * 100:.2f}%")
```

## Step 3: Model Requirements Checklist

✅ **Input Size**: 224x224x3 (RGB image)
✅ **Output Size**: 38 classes (matching class_labels.txt)
✅ **Format**: TorchScript (.pt file)
✅ **Preprocessing**: Model should handle standard ImageNet normalization or document custom preprocessing
✅ **File Size**: Keep under 50MB for better mobile performance

## Step 4: Copy Model to Flutter Project

After conversion, copy the model file:

```bash
# On Windows
copy mobile_plantnet_scripted.pt C:\Users\GroveReaper\IdeaProjects\iot_v3\lib\models\

# On Linux/Mac
cp mobile_plantnet_scripted.pt /path/to/iot_v3/lib/models/
```

## Common Issues and Solutions

### Issue 1: Model Input Size Mismatch
**Solution**: Ensure your model expects 224x224 input. If different, update the Flutter code:
```dart
_model = await PytorchLite.loadObjectDetectionModel(
  'lib/models/mobile_plantnet_scripted.pt',
  38,
  YOUR_WIDTH,  // Change here
  YOUR_HEIGHT, // Change here
  labelPath: 'lib/models/class_labels.txt',
);
```

### Issue 2: Wrong Number of Classes
**Solution**: Verify your model outputs 38 classes. Check with:
```python
output = model(torch.rand(1, 3, 224, 224))
print(output.shape)  # Should be: torch.Size([1, 38])
```

### Issue 3: Model Too Large
**Solution**: Use quantization to reduce size:
```python
import torch
from torch.quantization import quantize_dynamic

# Load your model
model = torch.jit.load('mobile_plantnet_scripted.pt')

# Apply dynamic quantization
quantized_model = quantize_dynamic(
    model, 
    {torch.nn.Linear}, 
    dtype=torch.qint8
)

# Save quantized model
torch.jit.save(quantized_model, 'mobile_plantnet_scripted_quantized.pt')
```

### Issue 4: Custom Preprocessing
If your model requires custom preprocessing, document it here and update the Flutter code accordingly.

## Model Architecture Recommendations

For optimal mobile performance:

1. **Use MobileNetV2 or EfficientNet-Lite** as backbone
2. **Keep model size < 50MB** (quantize if needed)
3. **Use 224x224 input** (standard mobile size)
4. **Avoid dynamic shapes** (use fixed input sizes)
5. **Test on target devices** before deployment

## Example: Complete Conversion Script

```python
#!/usr/bin/env python3
"""
Complete script to convert plant disease model to TorchScript
"""
import torch
import torch.nn as nn
from torchvision import models
import sys

def convert_model(input_path, output_path):
    """
    Convert a PyTorch model to TorchScript format
    
    Args:
        input_path: Path to trained model weights (.pth)
        output_path: Path to save TorchScript model (.pt)
    """
    try:
        # 1. Load model architecture
        print("Loading model architecture...")
        model = models.mobilenet_v2(pretrained=False)
        
        # Modify classifier for 38 classes
        model.classifier[1] = nn.Linear(model.last_channel, 38)
        
        # 2. Load trained weights
        print(f"Loading weights from {input_path}...")
        state_dict = torch.load(input_path, map_location='cpu')
        model.load_state_dict(state_dict)
        
        # 3. Set to evaluation mode
        model.eval()
        
        # 4. Create example input
        print("Creating example input...")
        example_input = torch.rand(1, 3, 224, 224)
        
        # 5. Trace the model
        print("Tracing model...")
        traced_model = torch.jit.trace(model, example_input)
        
        # 6. Optimize for mobile
        print("Optimizing for mobile...")
        optimized_model = torch.jit.optimize_for_inference(traced_model)
        
        # 7. Save the model
        print(f"Saving model to {output_path}...")
        optimized_model.save(output_path)
        
        # 8. Verify
        print("\nVerifying model...")
        loaded = torch.jit.load(output_path)
        test_output = loaded(example_input)
        
        print(f"✅ Success!")
        print(f"   Input shape: {example_input.shape}")
        print(f"   Output shape: {test_output.shape}")
        print(f"   Expected output: torch.Size([1, 38])")
        
        if test_output.shape[1] == 38:
            print("   ✅ Output shape matches!")
        else:
            print("   ❌ Warning: Output shape mismatch!")
            
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    # Example usage
    input_model = "path/to/your/trained_model.pth"
    output_model = "mobile_plantnet_scripted.pt"
    
    convert_model(input_model, output_model)
```

## Testing Your Model in Flutter

After copying the model, test it in the app:

1. **Build the app**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk  # For Android
   ```

2. **Run on device**:
   ```bash
   flutter run --release
   ```

3. **Test with sample images** from each class
4. **Monitor performance** (inference time, memory usage)
5. **Check accuracy** against your validation set

## Performance Benchmarking

Expected performance metrics:

- **Model Load Time**: < 2 seconds
- **Inference Time**: < 500ms per image
- **Memory Usage**: < 200MB
- **Accuracy**: Should match your validation accuracy (±2%)

## Next Steps

1. ✅ Convert your model using the script above
2. ✅ Verify the output shape (1, 38)
3. ✅ Copy to `lib/models/mobile_plantnet_scripted.pt`
4. ✅ Test in the Flutter app
5. 📝 Document any custom preprocessing needed
6. 📝 Benchmark on target devices

## Additional Resources

- PyTorch Mobile Docs: https://pytorch.org/mobile/
- TorchScript Guide: https://pytorch.org/docs/stable/jit.html
- Model Optimization: https://pytorch.org/tutorials/recipes/mobile_interpreter.html
- pytorch_lite Package: https://pub.dev/packages/pytorch_lite
