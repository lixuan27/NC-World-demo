# NC-World — Native Causal World Model · Video Demos

**Demo page: https://lixuan27.github.io/NC-World-demo/**

Generated videos from NC-World, a streaming **block-causal video world model**
(block-causal DiT + rectified flow + rolling KV cache). Every pair shows a
held-out ground-truth trajectory (left) next to the model's streaming
continuation from the first frame + action/text conditioning (right).

| Domain | PSNR | LPIPS | FVD | Note |
|---|---|---|---|---|
| LIBERO (sim) | 37.07 | 0.013 | 97 | 63.5 fps generation — faster than real time |
| LangTable | 28.73 | 0.039 | 107 | |
| Bridge (real robot) | 26.37 | 0.090 | 187 | honest failure showcase included |
| RT-1 | 25.55 | 0.089 | 374 | |
| Long horizon (253 frames) | 19.62 | 0.139 | 171 | autoregressive, no reset |

Playback in the demos is at inspection rate (3–15 fps), **not** generation
speed. Controlled comparison vs a bidirectional baseline (same code, same
hyperparameters, 81 frames): causal **21.47 dB / FVD 230 / 8.0 fps /
~0.2 s first frame** vs bidirectional 17.73 / 1087 / 3.7 fps / 5.6 s.
