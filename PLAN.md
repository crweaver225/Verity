# Verity - AI Safety Suite: Implementation Plan

## Vision

Verity is software focusing on auditability, filtering, and response screening for LLMs. Using Haskell, all prompts to an LLM will first go through Verity which will use Servant to expose api's for prompting agents. Verity will follow the something like this:

## What it does

A request to Verity's proxy goes through five sequential gates:

```
Client
  │
  ▼
┌─────────────────────────────────────────────────────┐
│  Gate 1 — PromptGuard pre-screen                    │
│  DeBERTa-v3 neural jailbreak/injection detector     │
│  In-process via FFI to core-onnx (ONNX Runtime)     │
│  Malicious prompt → 403 before any LLM call         │
└──────────────────────────┬──────────────────────────┘
                           │ benign
                           ▼
┌─────────────────────────────────────────────────────┐
│  Gate 2 — Filter rules + ML classifier              │
│  Configurable regex/keyword rules (config.yaml)     │
│  Optional bag-of-words classifier as second pass    │
│  Block / warn / pass per rule                       │
└──────────────────────────┬──────────────────────────┘
                           │ pass
                           ▼
┌─────────────────────────────────────────────────────┐
│  Inference server                                   │
│  Ollama or frontier model api                       │
│  Supports streaming and non-streaming responses     │
│  Supports reasoning models (DeepSeek-R1, Phi-4, …)  │
└──────────────────────────┬──────────────────────────┘
                           │ raw response
                           ▼
┌─────────────────────────────────────────────────────┐
│  Reasoning parser                                   │
│  Splits <think>…</think> trace from final answer    │
│  Trace written to audit log; answer passed forward  │
│  Client receives only the answer by default         │
└──────────────────────────┬──────────────────────────┘
                           │ trace + answer
                           ▼
┌─────────────────────────────────────────────────────┐
│  Gate 5 — LLM reasoning judge                       │
│  Separate judge model loaded in inference server    │
│  Reads the <think> trace and the final answer       │
│  Detects deliberate deception: model knowing the    │
│  answer is wrong but giving it anyway, hiding facts,│
│  or planning to mislead the user                    │
│  Structured verdict: {observation, thought,         │
│    conclusion} — fail-safe: parse error → fail      │
│  Deceptive trace → 403 (hard_block) or log (warn)   │
└──────────────────────────┬──────────────────────────┘
                           │ honest (or no trace)
                           ▼
┌─────────────────────────────────────────────────────┐
│  Gate 6 — LLaMA Guard post-screen                   │
│  LLaMA Guard 3 8B via local Ollama, over HTTP       │
│  Screens the final answer (not the reasoning trace) │
│  against 14 safety categories                       │
│  Unsafe response → 403 before returning to client   │
└──────────────────────────┬──────────────────────────┘
                           │ safe
                           ▼
                        Client
```

## Architecture

Verity is written in Haskell. Gate 1 runs in-process through FFI to a C++ library. The LLMs run in Ollama, which Verity calls over HTTP. There is no Python.

| Component | Role | Tech |
|---|---|---|
| `verity` | Proxy, gate pipeline, audit log, admin API | Haskell, Servant, SQLite |
| `core-onnx` | Gate 1 classifier (shared library, linked through FFI) | C++, ONNX Runtime, SentencePiece, Prompt Guard 2 (86M) |
| `ollama` | Main LLM, Gate 5 judge, Gate 6 Llama Guard (separate process) | Ollama (or a frontier API for the main LLM) |

- `core-onnx` exposes a small C API (load, classify, free). It is built with CMake and linked into Verity through cabal.
- Each gate sits behind a common interface, so a backend can change (FFI ↔ HTTP, local → hosted) without touching the pipeline.
- A gate that errors or whose backend is unreachable fails closed (block), and the failure is logged.
- Streaming: the response is buffered until Gates 5 and 6 pass, then sent to the client.

## Storage

SQLite stores audit logs (per-gate verdicts, reasoning traces, timestamps) and the configuration.

The next important step is that we will want to periodically pull the audit log for a model and run safety evaluations on it. The critera for this I will need to think through at a later date. 

All this will need to be managed from a web app where you can chat with an LLM with all Verity gates in place, you can look at the audit logs of every message to see which gates it passed and failed, and you can change configurations like which gates are on or off, or which custom filters are applied to gate 2. 