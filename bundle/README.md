# NC-World 精选 demo 包

12 组视频，每组三件：**模型生成的视频**、**与之配对的原视频（ground truth）**、以及**模型被给定的条件**。
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

**因此这些不是重建。** 唯一的重建在 demo 页的"评测上限"一节（真值经 VAE 编解码往返），
那一列是用来标出天花板的，不在本包内。同时也要讲清楚另一面：这是
**"给定真实动作、预测真实未来"的配对协议**，不是自由生成——PSNR/SSIM/LPIPS 只有在配对下才有意义。

---

## 这 12 条是怎么选出来的

**只按保真度选片会挑出接近静止的片段。** DROID 上按 PSNR 排前七的片子里有六片，
其真值运动低于该域中位数——静止片段本来就好预测，会在任何保真度榜上排前面，
而把它们当"最好的 demo"发出去，恰好是"画面变化非常缓慢"这个问题本身。

所以选片走两轴：**先要求真值运动不低于该域中位数，再在其中比 LPIPS（感知质量）**，
并列出"运动比"= 生成/真值 的运动量，越接近 1 说明动得越像。
运动量为逐帧差均值（CPU 可算、与运动单调相关）——**这不是 VBench 统计量，
不可与 benchmark 分数并列**。

**但两轴仍然不够，还必须过一遍眼睛。** 已终止的通用视频线上，按上述两轴选出的片段
逐帧看下来全部在第 40 帧崩解——**崩解会产生极大的光流，运动类指标因此把它打成高分**，
指标与失效模式指向同一方向。所有片段现在都经过抽帧对照确认末帧仍然完整，
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
注意这一档运动比全部略大于 1（1.06–1.08）——生成比真值**动得稍多**。

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
（每域的取值见上面各节）。

选片依据由 `slurm/demo_bundle_audit.sbatch`（job 263222）产出：
`scripts/clip_motion.py` 给逐片运动，`scripts/export_conditions.py` 导出动作条件
并校验其 episode 顺序与评测 JSON 的 `episode_ids` 一致——顺序错位会把 A 片的动作
贴到 B 片的视频上，而那种错误从外观上看不出来。

完整在线版（含并排对照、消融与漂移曲线）：<https://lixuan27.github.io/NC-World-demo/>

---

## `figures/` — 八张结果图（英文 · 莫兰迪配色 · 衬线体）

| 文件 | 内容 |
|---|---|
| `fig1_causal_vs_bidirectional` | 核心受控结果：三臂全部随机初始化、同数据、同 7500 步、同评测协议，唯一变量是注意力掩码与噪声调度 |
| `fig2_external_benchmarks` | Bridge-V2 / Language-Table / RT-1 对两个公开基线，每域附冻结画面地板 |
| `fig3_curriculum_and_guidance` | 训练窗口 45 → 125 → 253 帧，以及引导强度扫描 |
| `fig4_drift_and_ceiling` | 253 帧连续生成的逐段 PSNR 对自编码器天花板 |
| `fig5_sampler_two_knobs` | 流水线宽度与去噪深度方向相反 |
| `fig6_ablation_and_headroom` | 两项训练侧对齐的价值，以及还剩多少余量 |
| `fig7_commit_granularity` | 提交粒度增大时保真度与可控性的权衡 |
| `fig8_action_dependence` | 打乱动作后的损失上升幅度，逐域 |

PNG 用于幻灯片，PDF 是矢量、用于论文。

## `tables/` — Quantitative results

`quantitative_results.html` 浏览器直接打开，跟随系统亮/暗主题。`.md` 便于编辑器阅读，
`.tex` 可直接贴进论文。

**三张表刻意不合并。** 外部基准、因果对照、设计消融三者在数据域、时长和片段数上都不同，
而 FVD 只在片段数相同时可比——合成一张表会呈现一个从未做过的比较。

每个数字都由脚本从存档的评测 JSON 直读（`scripts/quant_table.py`、`scripts/figs_en.py`），
任一输入缺失即整体不出图不出表。除坐标轴文字外没有任何数字是手抄进作图代码的。
