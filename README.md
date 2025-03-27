# Sobel Edge Detection Hardware (SystemVerilog)

This project implements a real-time, flexible edge detection accelerator in SystemVerilog. It performs 3×3 convolution using 4 configurable kernels (Sobel and diagonal by default) and applies a threshold to detect edges in streaming grayscale images. The design is optimized for FPGA/ASIC integration and is fully configurable via an AMBA APB interface.

---

##  Features

- 4 parallel 3×3 convolution kernels (default: Sobel X/Y + diagonals)
- Thresholding: output is 0 or gradient magnitude
- Streaming architecture with 1-pixel-per-cycle input
- Valid-in/valid-out handshake for input/output flow control
- Line buffer with SRAM for 3-row sliding window
- APB interface for runtime configuration of image size, threshold, and kernels
- Scalable and modular SystemVerilog design

---

##  Architecture Overview

The system consists of the following main modules:

- **Line Buffer**  
  Buffers 3 rows of pixels using SRAM. Generates a valid 3×3 sliding window as pixels stream in.

- **Convolution Calculator**  
  Applies 4 independent 3×3 kernels (default: Sobel X, Sobel Y, and two diagonals). Each kernel computes a gradient response for the current window. The maximum response is passed to the threshold block.

- **Threshold Block**  
  Compares the maximum of the 4 gradient responses to a programmable threshold. If the value is greater than or equal to the threshold, the output is the magnitude; otherwise, the output is 0.

- **Controller**  
  Coordinates valid signals, manages the sliding window generation, and synchronizes processing start and stop.

- **APB Register File**  
  Receives configuration from an external CPU or testbench using the AMBA APB protocol. Allows runtime control of image size, threshold value, and kernel weights.

---

##  Input/Output Interface

###  Streaming Data

- **Inputs**
  - `pixel_in [7:0]` — Grayscale input pixel (1 per clock cycle)
  - `valid_in` — High when `pixel_in` is valid

- **Outputs**
  - `gradient_out [7:0]` — Output gradient magnitude (or 0 if below threshold)
  - `valid_out` — High when `gradient_out` is valid

Once 3 full rows are buffered, `valid_out` follows `valid_in` with a short latency. Output values represent the strongest response from the 4 kernels (after thresholding).

---

### 🛠️ Control Interface (APB)

The module is configured via an **AMBA APB interface**, with the following programmable registers:

| Register         | Description                                                                 |
|------------------|-----------------------------------------------------------------------------|
| `image_width`    | Number of pixels per row                                                    |
| `image_height`   | Number of pixels per column                                                 |
| `total_pixels`   | Total number of pixels to process                                           |
| `threshold`      | Minimum gradient magnitude to keep as output                                |
| `kernel_0`       | 3×3 kernel (default: Sobel X if all elements = 0)                           |
| `kernel_1`       | 3×3 kernel (default: Sobel Y if all elements = 0)                           |
| `kernel_2`       | 3×3 kernel (default: Diagonal 1 if all elements = 0)                        |
| `kernel_3`       | 3×3 kernel (default: Diagonal 2 if all elements = 0)                        |
| `start`          | Start processing once all configs are loaded                                |

> ℹ️ **Note:** If a kernel is written with all-zero values, the corresponding **default kernel** will be used internally (see below).

---

##  Default Kernels

```text
Sobel X:        Sobel Y:        Diagonal 1:     Diagonal 2:
[-1  0  1]      [-1 -2 -1]      [-2 -1  0]      [ 0 -1 -2]
[-2  0  2]      [ 0  0  0]      [-1  0  1]      [ 1  0 -1]
[-1  0  1]      [ 1  2  1]      [ 0  1  2]      [ 2  1  0]
```


## 🧪 Testbench Workflow

To test the SystemVerilog design and visualize results, follow these steps:

### 1️⃣ Prepare the Input Image

A Python script is provided to convert any grayscale image into a testbench-compatible format.

1. Choose a grayscale image (recommended max size: **1920 × 1080**).
2. Run the provided Python script or notebook:
   ```bash
   python generate_pixel_data.py
   ```
3. This will generate:
   - `pixel_data.txt` – A text file with one pixel (0–255) per line
   - Configuration values:
     - `image_width`
     - `image_height`
     - `total_pixels`

> ⚠️ Make sure the image dimensions match your hardware limits.

---

### 2️⃣ Set Up the Simulation Environment

In the folder where you run your SystemVerilog simulation:

- Place the following files:
  - `pixel_data.txt` (from the Python script)
  - An empty file named `edge_out.txt` (the testbench will write here)

- Update the testbench’s APB configuration section:
   ```systemverilog
   apb_write(IMAGE_WIDTH_ADDR,  1920);
   apb_write(IMAGE_HEIGHT_ADDR, 1080);
   apb_write(TOTAL_PIXELS_ADDR, 1920 * 1080);
   apb_write(THRESHOLD_ADDR,    40);   // Set your desired threshold
   apb_write(START_ADDR,        1);    // Begin processing
   ```

---

### 3️⃣ Run the Testbench

Run the simulation using your preferred tool (ModelSim, VCS, Verilator, etc.).  
The design will read pixel values from `pixel_data.txt` and write results to `edge_out.txt`.

---

### 4️⃣ Visualize the Output

Once simulation is complete:

1. Copy the generated `edge_out.txt` from your simulation folder into the same directory as the Python script.
2. Run the post-processing script:
   ```bash
   python show_edge_output.py
   ```
3. This will:
   - Load `edge_out.txt`, which contains the output gradient values (one per line)
   - Reconstruct the edge-detected image using the original width and height
   - Display or save the final image result

> ✅ This lets you visually confirm the Sobel edge detection result from the hardware output.

---

## 📚 Documentation

Below are the main documents associated with this project, including the full project report and final presentation slides.

📄 [Project Report (PDF)](doc/sobel_final_report.pdf)  
📊 [Presentation Slides (PPTX)](doc/final_presentation.pptx)  




