# EduAssist AI — LLMOps: API Cost, Latency, and Prompt Version Management

MLOps Assignment 2. The notebook measures the latency, token usage and cost of an LLM API, versions three prompts in the
MLflow Prompt Registry, evaluates them on the same five questions, and promotes the best one with the alias `production`.

## Environment

- Python **3.12.13**, macOS (Apple Silicon)
- Model: **gemini-3.1-flash-lite**, called through the **Google Gemini API v1beta**, native `models.generateContent` REST endpoint (via `requests`)
- Pricing: **$0.25** input / **$1.50** output per 1M tokens, standard tier, **USD**, pricing date **2026-11-03** (Gemini bills thinking tokens as output; none were reported in this run)
- MLflow **3.17.2** tracking server in **Podman** (SQLite backend, proxied artifact store)

## Required libraries

See `requirements.txt` (all pinned): mlflow 3.17.2, requests 2.34.2, pandas 3.1.0, numpy 2.5.4, python-dotenv 1.2.4,
jsonschema 4.26.0, jupyterlab 4.6.5, ipykernel 7.4.0, nbconvert 7.17.2.

## Environment variables (`.env`, never committed)

| Variable | Value used | Purpose |
|---|---|---|
| GEMINI_API_KEY | (secret) | API key, read with python-dotenv, sent in the `X-goog-api-key` header |
| GEMINI_BASE_URL | https://generativelanguage.googleapis.com/v1beta | API base URL |
| LLM_PROVIDER | Google Gemini | Label only |
| LLM_MODEL | gemini-3.1-flash-lite | Model id |
| API_NAME | Gemini API v1beta, models.generateContent (native REST) | Documented API version |
| INPUT_PRICE_PER_MILLION | 0.25 | USD per 1M input tokens |
| OUTPUT_PRICE_PER_MILLION | 1.50 | USD per 1M output tokens |
| PRICING_DATE | 2026-11-03 | Date the prices were checked |
| CURRENCY | USD | |
| MONTHLY_REQUESTS | 10000 | Projection volume |
| MLFLOW_TRACKING_URI | http://127.0.0.1:5001 | MLflow server |

Copy `.env.example` to `.env`, then fill in `GEMINI_API_KEY` and `PRICING_DATE`.

## Installation

```bash
/opt/homebrew/bin/python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m ipykernel install --user --name eduassist-llmops --display-name "Python 3.12 (eduassist-llmops)"
cp .env.example .env    # then edit .env
```

## MLflow UI (Podman)

```bash
podman machine start                       # if not running
podman build -t localhost/eduassist-mlflow:3.17.2 -f containers/mlflow/Containerfile containers/mlflow
./scripts/mlflow_up.sh                     # creates the volume and starts the container
```

Open http://127.0.0.1:5001 (health check: `curl http://127.0.0.1:5001/health` prints `OK`). Port 5001 is used because macOS AirPlay
Receiver occupies 5000, and the server is bound to 127.0.0.1 only. Stop it with `./scripts/mlflow_down.sh`; data persists in the Podman volume.

Without Podman, the equivalent local command is:
`mlflow server --host 127.0.0.1 --port 5001 --backend-store-uri sqlite:///mlflow.db`

## Reproduce the experiment

1. Start the MLflow server (above).
2. `source .venv/bin/activate && jupyter lab` from this folder.
3. Open `eduassist_llmops_assignment.ipynb`, select kernel "Python 3.12 (eduassist-llmops)".
4. Kernel → Restart Kernel and Run All Cells (about 21 Gemini API calls, a fraction of a cent).
5. The last cell prints `All checks passed.`
6. The notebook writes its results to `outputs/` (`latency_tokens_cost.csv`, `prompt_evaluation_results.csv`, `prompt_comparison.csv`,
   `latency_summary.csv`, `run_metadata.json`) and logs to MLflow: experiment `eduassist_llmops_assignment`, prompt `eduassist-academic-qa`
   (versions 1–3, alias `production`).
7. Re-running reuses the registered prompt versions and adds three new runs. Numbers vary between runs because LLM output and network
   latency are not deterministic.

## Files

| File | Content |
|---|---|
| eduassist_llmops_assignment.ipynb / .html | Notebook with outputs and written analysis |
| latency_tokens_cost.csv | Tasks 1–2: five requests with timing, status, tokens and cost |
| prompt_evaluation_results.csv | Task 3: 15 rows (v1–v3 × Q1–Q5) with metrics, JSON validity and responses |
| prompt_comparison.csv | Task 3 comparison table with the recommendation |
| screenshots/ | MLflow experiment, Prompt Registry, prompt diffs, metrics, production alias, trace feedback |
| final_report.pdf | Report |
| containers/, scripts/ | Podman MLflow image definition and start/stop scripts |
| data/questions.csv | The five fixed questions |
