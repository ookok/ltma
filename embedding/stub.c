#include <onnxruntime_c_api.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#pragma comment(lib, "onnxruntime")

#define MAX_VOCAB 30528
#define MAX_TOKEN_LEN 128
#define MAX_SEQ_LEN 128
#define EMBED_DIM 384

// ---- Vocabulary ----

typedef struct { char token[128]; int id; } VocabEntry;
typedef struct { VocabEntry e[MAX_VOCAB]; int n; } Vocab;
static Vocab g_vocab;
static int g_vocab_loaded = 0;

static int vfind(const char* t) {
  if (!g_vocab_loaded) return -1;
  for (int i = 0; i < g_vocab.n; i++)
    if (strcmp(g_vocab.e[i].token, t) == 0) return g_vocab.e[i].id;
  return -1;
}

static int vload(const char* p) {
  FILE* f = fopen(p, "r");
  if (!f) return -1;
  char line[1024]; g_vocab.n = 0;
  while (fgets(line, sizeof(line), f) && g_vocab.n < MAX_VOCAB) {
    size_t l = strlen(line);
    while (l > 0 && (line[l-1] == '\n' || line[l-1] == '\r')) line[--l] = '\0';
    if (l == 0) continue;
    strncpy(g_vocab.e[g_vocab.n].token, line, 127);
    g_vocab.e[g_vocab.n].id = g_vocab.n;
    g_vocab.n++;
  }
  fclose(f);
  g_vocab_loaded = 1;
  return g_vocab.n;
}

// ---- Tokenizer ----

static int tok(const char* text, int64_t* ids, int64_t* mask, int max_len) {
  int pos = 0;
  int cls = vfind("[CLS]"); if (cls >= 0 && pos < max_len) ids[pos++] = cls;
  char buf[2048]; int bi = 0;
  for (int i = 0; text[i] && bi < 2047; i++) {
    char c = text[i];
    buf[bi++] = (c >= 'A' && c <= 'Z') ? (c + 32) : c;
  }
  buf[bi] = '\0';

  char w[256]; int wi = 0;
  for (int i = 0; buf[i] && pos < max_len - 1; i++) {
    if (buf[i] == ' ' || buf[i] == '\t') {
      if (wi == 0) continue;
      w[wi] = '\0'; wi = 0;
      int id = vfind(w);
      if (id >= 0) { ids[pos++] = id; continue; }
      // Subword fallback
      for (int j = 0; w[j] && pos < max_len - 1; j++) {
        char sw[10] = {0}; int swl = 0;
        for (int k = j; k <= j + 4 && w[k]; k++) {
          if (swl == 0) { sw[swl++] = w[k]; sw[swl] = 0; id = vfind(sw); }
          else { char tmp[10]; sprintf(tmp, "##%.*s", swl + 1, w + j); id = vfind(tmp); }
          if (id >= 0) { ids[pos++] = id; j += swl; swl = -1; break; }
          swl++;
        }
        if (swl >= 0) { int unk = vfind("[UNK]"); ids[pos++] = unk >= 0 ? unk : 100; }
      }
    } else { w[wi++] = buf[i]; }
  }
  if (wi > 0 && pos < max_len - 1) { w[wi] = 0;
    int id = vfind(w); if (id >= 0) ids[pos++] = id; else { int unk = vfind("[UNK]"); ids[pos++] = unk >= 0 ? unk : 100; }
  }
  int sep = vfind("[SEP]"); if (sep >= 0 && pos < max_len) ids[pos++] = sep;
  int pad = vfind("[PAD]"); if (pad < 0) pad = 0;
  for (int i = 0; i < max_len; i++) { mask[i] = (i < pos) ? 1 : 0; if (i >= pos) ids[i] = pad; }
  return pos;
}

// ---- ONNX Runtime ----

typedef struct {
  const OrtApi* api;
  OrtEnv* env;
  OrtSession* session;
  OrtMemoryInfo* mem;
  float result[EMBED_DIM];
  char err[512];
} Model;

void* embedding_init(const char* model_path, const char* vocab_path) {
  int vn = vload(vocab_path);
  if (vn < 0) return NULL;
  Model* m = (Model*)calloc(1, sizeof(Model));
  if (!m) return NULL;
  m->api = OrtGetApiBase()->GetApi(ORT_API_VERSION);
  if (!m->api) { free(m); return NULL; }
  OrtStatus* s;
  s = m->api->CreateEnv(ORT_LOGGING_LEVEL_ERROR, "ltma", &m->env);
  if (s) { m->api->ReleaseStatus(s); free(m); return NULL; }
  FILE* mf = fopen(model_path, "rb");
  if (!mf) { m->api->ReleaseEnv(m->env); free(m); return NULL; }
  fseek(mf, 0, SEEK_END);
  long msize = ftell(mf);
  fseek(mf, 0, SEEK_SET);
  void* mdata = malloc(msize);
  if (!mdata) { fclose(mf); m->api->ReleaseEnv(m->env); free(m); return NULL; }
  fread(mdata, 1, msize, mf);
  fclose(mf);

  OrtSessionOptions* o;
  m->api->CreateSessionOptions(&o);
  m->api->SetSessionGraphOptimizationLevel(o, ORT_ENABLE_BASIC);
  s = m->api->CreateSessionFromArray(m->env, mdata, msize, o, &m->session);
  free(mdata);
  m->api->ReleaseSessionOptions(o);
  if (s) { m->api->ReleaseStatus(s); m->api->ReleaseEnv(m->env); free(m); return NULL; }
  m->api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &m->mem);
  return m;
}

int embedding_get(void* handle, const char* text) {
  Model* m = (Model*)handle;
  if (!m || !m->session) return 0;
  int64_t ids[EMBED_DIM * 2], mask[EMBED_DIM * 2];
  int len = tok(text, ids, mask, MAX_SEQ_LEN);
  if (len <= 0) return 0;

  int64_t shape[2] = {1, MAX_SEQ_LEN};
  size_t sz = MAX_SEQ_LEN * sizeof(int64_t);

  // Build int64 input arrays
  int64_t iid[MAX_SEQ_LEN], ima[MAX_SEQ_LEN], itt[MAX_SEQ_LEN];
  for (int i = 0; i < MAX_SEQ_LEN; i++) {
    iid[i] = ids[i]; ima[i] = mask[i]; itt[i] = 0;
  }

  OrtValue *iv[3], *ov[1];
  const char* inames[] = {"input_ids", "attention_mask", "token_type_ids"};
  const char* onames[] = {"last_hidden_state"};
  OrtStatus* st = NULL;

#define MK(v, d) st = m->api->CreateTensorWithDataAsOrtValue(m->mem, d, sz, shape, 2, ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, &v)
  MK(iv[0], iid); if (st) { m->api->ReleaseStatus(st); return 0; }
  MK(iv[1], ima); if (st) { m->api->ReleaseStatus(st); m->api->ReleaseValue(iv[0]); return 0; }
  MK(iv[2], itt); if (st) { m->api->ReleaseStatus(st); m->api->ReleaseValue(iv[0]); m->api->ReleaseValue(iv[1]); return 0; }
#undef MK

  OrtRunOptions* ro;
  m->api->CreateRunOptions(&ro);
  st = m->api->Run(m->session, ro, inames, (const OrtValue* const*)iv, 3, onames, 1, ov);
  m->api->ReleaseRunOptions(ro);
  m->api->ReleaseValue(iv[0]); m->api->ReleaseValue(iv[1]); m->api->ReleaseValue(iv[2]);
  if (st) { m->api->ReleaseStatus(st); return 0; }

  float* raw = NULL;
  m->api->GetTensorMutableData(ov[0], (void**)&raw);
  if (!raw) { m->api->ReleaseValue(ov[0]); return 0; }

  // Mean pool + L2 normalize
  memset(m->result, 0, sizeof(m->result));
  int valid = 0;
  for (int i = 0; i < MAX_SEQ_LEN; i++) {
    if (mask[i]) {
      for (int j = 0; j < EMBED_DIM; j++) m->result[j] += raw[i * EMBED_DIM + j];
      valid++;
    }
  }
  if (valid > 0) {
    for (int j = 0; j < EMBED_DIM; j++) m->result[j] /= valid;
    float norm = 0;
    for (int j = 0; j < EMBED_DIM; j++) norm += m->result[j] * m->result[j];
    norm = sqrtf(norm);
    if (norm > 0) for (int j = 0; j < EMBED_DIM; j++) m->result[j] /= norm;
  }
  m->api->ReleaseValue(ov[0]);
  return EMBED_DIM;
}

double embedding_read(void* handle, int index) {
  Model* m = (Model*)handle;
  if (!m || index < 0 || index >= EMBED_DIM) return 0.0;
  return (double)m->result[index];
}

int embedding_dim() { return EMBED_DIM; }

void embedding_free(void* handle) {
  if (!handle) return;
  Model* m = (Model*)handle;
  if (m->mem) m->api->ReleaseMemoryInfo(m->mem);
  if (m->session) m->api->ReleaseSession(m->session);
  if (m->env) m->api->ReleaseEnv(m->env);
  free(m); g_vocab_loaded = 0;
}
