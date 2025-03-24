
# Sobel Edge Detection Hardware (SystemVerilog)

This project implements a flexible and high-throughput edge detection accelerator in SystemVerilog. While it defaults to the Sobel operator, the design supports four configurable convolution kernels (including diagonals) and can be customized at runtime via the APB protocol.

##  Features

- Hardware convolution with 4 3×3 kernels (Sobel X/Y + diagonals by default)
- Real-time edge detection using a sliding 3×3 window
- Line buffer architecture for efficient row-wise processing
- Thresholding logic that outputs either `0` or the gradient magnitude
- APB-based configuration interface for full control via CPU
- Designed for FPGA/ASIC integration

##  Architecture Overview

The accelerator is built from the following modules:

- **Line Buffer**  
  Stores 3 rows of input pixels using SRAM. Continuously outputs a 3×3 window as new pixels stream in.

- **Convolution Calculator**  
  Computes gradient magnitudes using 4 different 3×3 kernels (Sobel X, Sobel Y, and 2 diagonals by default). Kernel values can be overwritten at runtime via the APB bus.

- **Threshold Block**  
  Compares the gradient magnitude to a configurable threshold. Outputs `0` if below threshold, or the full magnitude if above.

- **Controller**  
  Coordinates the flow of valid data, handles start-of-frame control, and manages window alignment.

- **Register File (APB Interface)**  
  Exposes control and configuration registers to an external CPU via the AMBA APB protocol. Configurable parameters include:
  
  - `image_width`
  - `image_height`
  - `total_pixels`
  - `threshold`
  - 4 × (3×3) convolution kernels (optional)
  - `start` signal

##  Input/Output Interface

- **Input**: Stream of 8-bit grayscale pixel values (1 per clock cycle)
- **Output**: Stream of 8-bit gradient magnitudes (or 0 if below threshold)

##  How to Simulate

1. Clone this repo:
   ```bash
   git clone https://github.com/yourusername/sobel-edge-detection.git
   cd sobel-edge-detection
