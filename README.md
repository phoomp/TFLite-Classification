# Installation Guide

1. Download model file from my [shared folder](https://drive.google.com/open?id=1um49melKB7TVp77z4KZThG2zHflCP8hV). Alternatively, you can download the model from [this Colab](https://colab.research.google.com/drive/17MKg2W48jI8sdMuh9gkVOkhpM9eQ1-Sj) if you want to see how I converted my Keras model into a [Tensorflow Lite model](https://www.tensorflow.org/lite/models). At the bottom of the Colab, there is a more readable & easier to modify piece of code. That one chunk is the same as everything above it.

2. Copy the "rock_paper_scissors.tflite" model file into the ***.xcworkspace*** file by dragging it into XCode. **Do not** simply copy the file to the project's directory. The model can be anything ending with ".tflite" file format. Just make sure to adjust: 
- Name of the model
- Input shape
- No. of output classes
- Normalization value: default is both 300, since the width & height of input shape is 300.

3. This project comes with a Podfile. You will not be able to build it unless you perform `pod install` again. If you don't have CocoaPods, [here's how to download it.](https://cocoapods.org). Make sure you are in the project's directory before running the command above.


