# APB Register Map

This document lists all the registers exposed via the APB interface and their roles in the Sobel Edge Detection hardware.

---

## 📐 Address Map

| Address (Hex) | Register Name     | Width    | Description                                 |
|---------------|-------------------|----------|---------------------------------------------|
| `0x00`        | `image_width`     | 16 bits  | Number of pixels per row                    |
| `0x04`        | `image_height`    | 16 bits  | Number of pixels per column                 |
| `0x08`        | `total_pixels`    | 32 bits  | Total number of pixels to process           |
| `0x0C`        | `threshold`       | 8 bits   | Minimum gradient value to keep              |
| `0x10`        | `kernel_0[0]`     | 8 bits   | First element of Kernel 0 (3×3 = 9 entries) |
| `0x11`        | `kernel_0[1]`     | 8 bits   | ...                                         |
| `...`         | `...`             | ...      | Repeat for all 4 kernels                    |
| `0x40`        | `start`           | 1 bit    | Write `1` to begin processing               |

> ⚠️ All kernel values are 8-bit signed integers (2’s complement format).  
> ⚠️ Writing all-zero to a kernel loads the default preset (Sobel or diagonal).

---

## 🧠 Default Kernel Mapping

Each kernel is a 3×3 grid flattened into 9 sequential registers:
```
[k0, k1, k2,
 k3, k4, k5,
 k6, k7, k8]
```
So `kernel_0[0]` = top-left value, `kernel_0[8]` = bottom-right.

---

## 📝 Example APB Write Sequence

```systemverilog
apb_write(0x00, 1920);           // image_width
apb_write(0x04, 1080);           // image_height
apb_write(0x08, 2073600);        // total_pixels
apb_write(0x0C, 40);             // threshold
apb_write(0x40, 1);              // start
```

