# NC-World: Quantitative Results

All values read directly from stored evaluation artefacts. The three
tables are kept separate because their rows are not mutually comparable.

## 1. External benchmarks

Official validation splits, 8-frame action-conditioned continuation,
512 clips, one shared FVD implementation.

| Method | Bridge-V2 FVD | Language-Table FVD | RT-1 FVD |
|---|---:|---:|---:|
| Static frame (floor) | 238.70 | 167.31 | 459.53 |
| IRASim | 91.60 | 60.05 | -- |
| DriftWorld | 101.20 | 39.09 | 68.72 |
| **Ours (from scratch)** | **45.08** | **37.97** | 79.47 |

## 2. Causal versus bidirectional

All arms from random init, same data, same 7500 steps, identical protocol.

| Attention | Noise | FVD | PSNR | SSIM | LPIPS | b |
|---|---|---:|---:|---:|---:|---:|
| Bidirectional | shared | 1566.27 | 21.74 | 0.7970 | 0.1292 | 0.392 |
| Bidirectional | per-chunk | 4454.38 | 12.72 | 0.3427 | 0.5545 | -0.006 |
| Block-causal | per-chunk | 690.81 | 23.79 | 0.8599 | 0.0772 | 0.610 |

## 3. Design ablations

| Factor | FVD | PSNR | SSIM | LPIPS |
|---|---:|---:|---:|---:|
| **Training context length (frames)** | | | | |
| 45 | 513.91 | 19.64 | 0.7873 | 0.1520 |
| 125 | 350.47 | 19.54 | 0.7770 | 0.1435 |
| 253 | 296.01 | 19.68 | 0.7797 | 0.1368 |
| **Self-generated history + inference-matched noise** | | | | |
| both on | 283.46 | 19.61 | 0.7777 | 0.1363 |
| both off | 629.93 | 16.91 | 0.6978 | 0.2335 |
| **Chunks in flight** | | | | |
| 3 | 296.01 | 19.68 | 0.7797 | 0.1368 |
| 8 | 724.54 | 16.35 | 0.5820 | 0.2298 |
| **Denoising updates per chunk** | | | | |
| 2 | 64.33 | 31.50 | 0.9610 | 0.0228 |
| 4 | 59.34 | 34.12 | 0.9706 | 0.0188 |
| 8 | 56.52 | 33.99 | 0.9697 | 0.0190 |
| **Guidance scale** | | | | |
| 1.0 | 317.19 | 19.78 | 0.7863 | 0.1328 |
| 1.25 | 289.79 | 19.76 | 0.7849 | 0.1325 |
| 1.5 | 274.85 | 19.71 | 0.7827 | 0.1337 |
| 2.0 | 283.46 | 19.61 | 0.7777 | 0.1363 |
| 3.0 | 337.78 | 19.36 | 0.7623 | 0.1458 |
