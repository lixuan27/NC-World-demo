# NC-World 精选 demo 包

16 组视频，每组三件：**模型生成的视频**、**与之配对的原视频（ground truth）**、以及**模型被给定的条件**。
生成结果脱离这两样无法判断，所以这个包是按"三件一组"组织的，而不是把视频拷贝出来了事。

文件命名：`<域>/clip<编号>_generated.mp4`、`clip<编号>_groundtruth.mp4`、`clip<编号>_actions.csv`。

---

## 模型被给了什么（这决定了怎么读这些视频）

**机器人域**（DROID / LIBERO / LangTable / Bridge-V2）：模型拿到 **1 帧真实画面**，
外加该 episode **真实的动作序列**（全程逐帧），然后自回归推演出后面全部帧。
中途**不再看任何真值像素**——`history_len = 1` 个 latent 帧，而 Wan2.2 VAE 是因果 4× 时域压缩
（253 RGB 帧 ↔ 64 latent 帧 = 1 + 63×4），所以第 0 个 latent 帧恰好就是第 0 个 RGB 帧。

动作就是同目录下的 `clip*_actions.csv`：每行一帧转移，列为 `cartesian_position` + `gripper_position`
展平后的分量（DROID/LIBERO/Bridge 为 7 维，LangTable 是平面推物、2 维）。这就是"condition"的字面内容。

**通用视频域**：模型拿到 **1 帧真实画面 + 该 clip 自带的 caption**（OpenVid-HD 语料标注，
经 T5 编码）。caption 原文列在下面每条里。**没有任何一条 prompt 是手写的**——
全部来自留出集本身。

**因此这些不是重建。** 唯一的重建在 demo 页的"评测上限"一节（真值经 VAE 编解码往返），
那一列是用来标出天花板的，不在本包内。同时也要讲清楚另一面：这是
**"给定真实动作、预测真实未来"的配对协议**，不是自由生成——PSNR/SSIM/LPIPS 只有在配对下才有意义。

---

## 这 16 条是怎么选出来的

**只按保真度选片会挑出接近静止的片段。** DROID 上按 PSNR 排前七的片子里有六片，
其真值运动低于该域中位数——静止片段本来就好预测，会在任何保真度榜上排前面，
而把它们当"最好的 demo"发出去，恰好是"画面变化非常缓慢"这个问题本身。

所以选片走两轴：**先要求真值运动不低于该域中位数，再在其中比 LPIPS（感知质量）**，
并列出"运动比"= 生成/真值 的运动量，越接近 1 说明动得越像。
运动量为逐帧差均值（CPU 可算、与运动单调相关）——**这不是 VBench 统计量，
不可与 benchmark 分数并列**；通用视频域的运动比则来自 RAFT 光流（即 VBench 的统计量）。

**但两轴仍然不够，还必须过一遍眼睛。** 通用视频域按上述两轴选出的三条，逐帧看下来
全部在第 40 帧崩解——**崩解会产生极大的光流，运动类指标因此把它打成高分**。
所有片段现在都经过抽帧对照（`results/general_pick/*.png`）确认在末帧仍然完整，
指标只用来排候选顺序，不做最终决定。

---

## DROID（真机双臂，253 帧 @15fps ≈ 16.9 秒）

本项目最难也最主力的一档：单张真实帧起步，连续推演 252 帧。
权重 `b_s2b` step 16000；采样 cfg 1.5 · steps 64 · ar_step 4 · inflight 3 · cache 3 · sink 1。
**该域 24 片整体：PSNR 19.71 · SSIM 0.7827 · LPIPS 0.1337 · FVD 274.8。**

| 片 | episode | PSNR | LPIPS | 真值运动 | 运动比 | 动作行程 |
|---|---|---|---|---|---|---|
| clip14 | 1666 | 18.74 | 0.1268 | 2.400 | **1.01** | 27.50 |
| clip05 | 429 | 19.22 | **0.1263** | 2.054 | 0.86 | 22.38 |
| clip17 | 2046 | **20.74** | 0.1327 | 1.830 | 1.02 | 18.60 |

clip14 是这一档里运动最像真值的一条（比值 1.01）且感知质量并列最好；
clip17 保真度最高。**该域仍是全部域里伪影最重的一档**，17 秒尾段的漂移看得见——
demo 页的漂移曲线量化了这一点（首 15 帧 28.3 dB → 末段 17.9 dB）。

## LIBERO（仿真机械臂，49 帧）

本项目质量最好的一档，全程锐利刚体。权重 `libero_s1` step 100000；cfg 2 · ar_step 8 · inflight 1 · cache 2。
**该域 24 片整体：PSNR 33.99 · SSIM 0.9697 · LPIPS 0.0190 · FVD 56.5。**

| 片 | episode | PSNR | LPIPS | 真值运动 | 运动比 | 动作行程 |
|---|---|---|---|---|---|---|
| clip17 | 17 | 35.47 | 0.0112 | **3.077** | 1.06 | 5.44 |
| clip23 | 23 | **36.54** | **0.0107** | 2.044 | 1.08 | 4.57 |
| clip14 | 14 | 34.00 | 0.0128 | 2.461 | 1.07 | 5.18 |

clip17 是"高运动 + 高质量"同时成立的一条，最能说明问题。
注意这一档运动比全部略大于 1（1.06–1.08）——生成比真值**动得稍多**，
与通用视频域的方向正好相反。

## LangTable（平面推物，41 帧）

多物体交互下的跟踪。权重 `langtable_s1` step 120000；cfg 2 · ar_step 2 · inflight 1 · cache 2。
**该域 24 片整体：PSNR 28.26 · SSIM 0.9047 · LPIPS 0.0425 · FVD 168.0。**

| 片 | episode | PSNR | LPIPS | 真值运动 | 运动比 | 动作行程 |
|---|---|---|---|---|---|---|
| clip09 | 18989 | 27.80 | 0.0371 | **6.910** | 0.92 | 6.67 |
| clip23 | 32235 | **29.69** | **0.0263** | 5.702 | 0.88 | 4.93 |
| clip05 | 7210 | 26.51 | 0.0347 | 6.274 | 0.87 | 13.30 |

这一档真值运动量本身就大（是 DROID 的 3 倍上下），clip09 在这个运动量下仍保持 0.92 的运动比。

## Bridge-V2（真机厨房场景，77 帧）

权重 `bridge_c8` step 100000；cfg 2 · ar_step 8 · inflight 1 · cache 2。
**该域 23 片整体：PSNR 22.58 · SSIM 0.8547 · LPIPS 0.0748 · FVD 251.7。**

| 片 | episode | PSNR | LPIPS | 真值运动 | 运动比 | 动作行程 |
|---|---|---|---|---|---|---|
| clip01 | 1162 | 22.08 | **0.0740** | 4.566 | **0.99** | 76.34 |
| clip13 | 2814 | 22.04 | 0.0785 | 4.488 | 0.98 | 58.14 |
| clip07 | 1914 | **22.28** | 0.0791 | **5.212** | 0.90 | 73.78 |

⚠️ **一处必须讲清的口径差**：这三条是 **77 帧**的长版，而本项目在 Bridge-V2 上对外报的
benchmark 分数走的是 **9 帧**续写协议（IRASim 的设定）。视频与那一行分数**不同源**，
不要把这里的观感对应到那个数字上。上表里的 22.58/251.7 是 77 帧这一档自己的数。

Bridge 的长度上限是**数据集限制**，不是模型限制——留出集中最长的 episode 只有 79 帧。

## 通用视频（文本+首帧条件，81 帧 @12fps）

**这是本项目最弱的一档，且这里发生过一次选片事故，必须先讲清楚。**

⚠️ **本包最初发的三条（clip15/25/23）是坏的，已撤下。** 它们按"运动比"（预测运动 ÷ 真值运动）
选出，看着是这一档最忠实的三条；抽帧逐张看才发现，**它们在第 40 帧全部崩解成抽象色块**。
原因不是巧合：**画面解体会产生极大的光流**，所以光流比值型指标把"崩解"打成了"运动忠实"。
指标与失效模式指向同一个方向，纯按指标选片必然选中最坏的那几条。

复查采样设置后判明：`ar_step=4` 与 `ar_step=8` 都在第 40 帧崩，**只有 `ar_step=2` 撑满 81 帧**。
本节现已全部改用 `ar_step=2`，权重 `trackb_s4` step 60000 · cfg 2。

**代价要说在前面**：稳定设置下这四条的运动比只有 **0.13–0.22**，即模型只给出真值约五分之一的
运动量。这一档的真实状态是**"稳而慢"与"动而碎"之间没有好选项**，不是"参数调对就好了"。

**clip01** — 真值运动 4.43，运动比 0.19，PSNR 14.07。**本档画质最好的一条**，78 帧全程清晰连贯。
> The video features a man standing on a cliff overlooking a mountainous landscape. He is wearing a yellow jacket and a black baseball cap. In the first frame, he is looking out towards the mountains with a contemplative expression. In the second frame, he is gesturing with his hands, possibly explaining something about the landscape. The style of the video is a combination of travel and adventure, with a focus on the natural beauty of the landscape.

**clip17** — 真值运动 5.27，运动比 0.18，PSNR 14.95。两个主体的身份全程稳住，面部略有软化。
> The video features a man in a red shirt standing in front of a woman with a zombie-like appearance. The man has a beard and is making a gesture with his hands, possibly in a state of shock or surprise. The woman has a pale complexion, dark eye makeup, and a wide, unnerving smile. The overall style of the video is eerie and suspenseful.

**clip20** — 真值运动 9.37，运动比 0.13，PSNR 13.62。车内双人场景保持到底，右侧人物有涂抹。
> The video is a lively and dynamic scene featuring two men in a car. The man in the driver's seat is wearing a brown shirt and sunglasses, while the man in the passenger seat is wearing a black tank top and sunglasses. They are both smiling and appear to be enjoying their ride. The car is moving down a road with trees and bushes on either side.

**clip03** — 真值运动 **11.32**（本档最大），运动比 0.22，PSNR 12.11。场景撑满 78 帧，但末帧面部明显变形。
> In the video, a man with red hair and sunglasses is seen sitting in the back seat of a car. He is holding a white phone in his hands, which he appears to be using. The car is moving, as indicated by the blurred background. The overall style of the video is casual and candid.

⚠️ **这一档的运动不足是结构性的。** 跨 clip 的响应度斜率（预测运动对真值运动的 log-log 斜率，
1 为忠实）在这一档是 **0.29–0.52**，而同一套架构在动作条件域是 **0.46–0.89**。
引导强度扫过（cfg 2/4/7，斜率 0.288/0.269/0.366，无趋势），两条损失侧改法都按预注册判据关闭了。
**缺的是"该动多快"这个信号本身**——文本不指定运动幅度。修法在**条件侧**，还没做。

⚠️ 一并更正此前一条说法：我们曾报"把 ar_step 从 4 提到 8 能把响应度从 0.288 抬到 0.466"。
补测 ar2 后该说法作废——**ar2 的响应度最高（0.517）且是唯一不崩的**；
ar8 抬的是运动**水平**（平均比 0.48 vs ar2 的 0.34），而那个水平来自崩解。

---

## 复现这些视频的命令

DROID：

```bash
python -m ncworld.evaluate --ckpt checkpoints/b_s2b/last.pt \
  --out results/sink_cfg/eval_cfg1p5.json --clips 24 --frames 253 --no-ema \
  --clip-select prefix --dump-videos results/sink_cfg/dump_cfg1p5 --dump-fps 15 \
  --set stream.cfg_scale=1.5 stream.steps=64 stream.ar_step=4 \
        stream.max_cache_chunks=3 stream.inflight_chunks=3 stream.sink_frames=1
```

其余机器人域同一入口，只改 `--ckpt` / `--frames` / `stream.ar_step` / `stream.cfg_scale`
（每域的取值见上面各节）。通用视频走另一入口：

```bash
python scripts/gen_textvideo.py --ckpt checkpoints/trackb_s4/step_00060000.pt \
  --out results/general_ar/gen_ar2 --clips 32 --frames 81 --seed 1234 --fps 12 \
  --set stream.cfg_scale=2 stream.ar_step=2
```

选片依据由 `slurm/demo_bundle_audit.sbatch`（job 263222）产出：
`scripts/clip_motion.py` 给逐片运动，`scripts/export_conditions.py` 导出动作条件
并校验其 episode 顺序与评测 JSON 的 `episode_ids` 一致——顺序错位会把 A 片的动作
贴到 B 片的视频上，而那种错误从外观上看不出来。

完整在线版（含并排对照、消融与漂移曲线）：<https://lixuan27.github.io/NC-World-demo/>
