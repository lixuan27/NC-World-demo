# NC-World — demo page

**https://lixuan27.github.io/NC-World-demo/**

A from-scratch, action-conditioned, **block-causal video world model** trained on real robot video (DROID),
and a purpose-built instrument for one question: *where does a native causal world model keep state it cannot see?*

The page carries, in one place:

* **253-frame free-running rollouts** on DROID beside the ground-truth recordings, plus the VAE round-trip ceiling;
* the **1B vs 3B scaling gate** that truncated the 3B chain (side-by-side video and numbers);
* the **occlusion probe** showing that an already-trained robot world model *re-renders* what the arm hid instead of carrying it;
* **RevealTable**, a five-cargo hidden-permutation task read directly out of the generated pixels
  (chance 1/120), with the carrier ladder and the linear carrier probes;
* the **test-time-training** line: what it buys (one-time deployment calibration, +1.60 dB at zero test-time cost),
  what it does not (open-loop gains; weight-as-memory beyond +0.2 dB), and the 2x2 that pins the mechanism;
* every **public-protocol benchmark** number as an absolute value, negative results included.

Older pages kept for reference: [`revealtable.html`](revealtable.html),
[`quantitative_results.html`](quantitative_results.html),
[`archive_index_2026-09-04.html`](archive_index_2026-09-04.html).

Project status: paused 2026-09-07, GPUs released to another project. All checkpoints, result JSONs and
per-clip pairing files are retained; the resume ledger lives in the code repository.
