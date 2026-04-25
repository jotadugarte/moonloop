# Images — upload & delivery rule (Moonloop)

This document defines the **mandatory** image upload + rendering rule for Moonloop.

## Goals

- Fast page loads (small, modern web formats)
- Reasonable storage usage
- Consistent visual quality
- Cross-cutting rule: no per-CRUD custom pipelines

## Canonical rule (v1)

- **Keep original uploads** (for traceability and future re-processing).
- **Serve standardized variants in WebP** for all UI usage.
- **If variants cannot be generated** (e.g. missing **libvips**), fall back to serving the **original blob**.

## Standard variants

All attached raster images used in the UI must support these variants:

- **thumb**: 160×160
- **list**: 640px max width (auto height)
- **detail**: 1200px max width (auto height)

## Performance targets (guidance)

Targets are for review and tuning; the rule is about serving **variants**, not originals.

- **thumb**: target < 20KB (max 40KB)
- **list**: target < 120KB (max 200KB)
- **detail**: target < 300KB (max 450KB)

## Safety limits (hard)

To protect CPU/RAM and request/job time, reject uploads that exceed:

- **Max bytes**: 25MB
- **Max dimensions**: 8000px on the longest side

## Checklist for any new CRUD that accepts images

- Use Active Storage attachments as usual (`has_one_attached` / `has_many_attached`).
- Render images through the project-standard helper/pipeline (do not inline ad-hoc `variant(...)` calls in views).
- Use only `thumb`, `list`, or `detail` in UI (add a new named size only when a concrete UI needs it).
- Ensure the UI serves WebP variants when variants are available; only explicit fallback may serve the original.

