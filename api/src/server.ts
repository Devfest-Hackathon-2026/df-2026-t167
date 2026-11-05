import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { createApp } from './app.js';
import { mockGemini, vertexGemini } from './gemini.js';

const project = process.env.GOOGLE_CLOUD_PROJECT;
if (!project) throw new Error('GOOGLE_CLOUD_PROJECT が未設定です');
initializeApp({ projectId: project });

const useMock = process.env.GEMINI_MOCK === '1';
const gemini = useMock
  ? mockGemini({ fail: () => process.env.GEMINI_MOCK_FAIL === '1' })
  // Vertex AI のプロジェクトは Firestore と別にできる。手元ではエミュレータ（demo-t167）のまま本物の Gemini を呼ぶため
  : vertexGemini(process.env.VERTEX_PROJECT ?? project, process.env.VERTEX_LOCATION ?? 'asia-northeast1', process.env.GEMINI_MODEL ?? (() => { throw new Error('GEMINI_MODEL が未設定です'); })());

const port = Number(process.env.PORT ?? 8080);
createApp({ db: getFirestore(), auth: getAuth(), gemini }).listen(port, () => {
  console.log(`api listening on :${port} (gemini=${gemini.source})`);
});
