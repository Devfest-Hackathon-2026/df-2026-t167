"use client";
import { use, useEffect, useState } from "react";
import { doc, onSnapshot, serverTimestamp, setDoc } from "firebase/firestore";
import { ensureSignedIn, firebase } from "@/lib/firebase";

type Room = { title: string; phase: "collecting" | "discussing" | "consensus" | "closed" };
const PHASE_LABEL: Record<Room["phase"], string> = { collecting: "事前意見の受付中", discussing: "議論中", consensus: "合意の確認中", closed: "終了" };

export default function RoomPage({ params }: { params: Promise<{ roomId: string }> }) {
  const { roomId } = use(params);
  const [room, setRoom] = useState<Room | null>(null);
  const [error, setError] = useState("");
  const [opinion, setOpinion] = useState("");
  const [sent, setSent] = useState(false);

  useEffect(() => {
    let unsub = () => {};
    ensureSignedIn().then(() => {
      unsub = onSnapshot(doc(firebase().db, `rooms/${roomId}`), (s) => setRoom(s.data() as Room), (e) => setError(e.message));
    });
    return () => unsub();
  }, [roomId]);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const user = await ensureSignedIn();
    await setDoc(doc(firebase().db, `rooms/${roomId}/privateOpinions/${user.uid}`), { text: opinion, updatedAt: serverTimestamp() });
    setSent(true);
  }

  if (error) return <main role="alert">この部屋を表示できません：{error}</main>;
  if (!room) return <main>読み込み中…</main>;
  return (
    <main style={{ maxWidth: 480, margin: "32px auto", padding: 16, fontFamily: "sans-serif" }}>
      <h1>{room.title}</h1>
      <p data-testid="phase">{PHASE_LABEL[room.phase]}</p>
      {room.phase === "collecting" && (
        <form onSubmit={submit}>
          <label htmlFor="opinion">あなたの意見（ほかの人には見えません）</label>
          <textarea id="opinion" value={opinion} onChange={(e) => setOpinion(e.target.value)} maxLength={1000} rows={5} style={{ display: "block", width: "100%" }} />
          <button type="submit" disabled={!opinion.trim()}>提出する</button>
          {sent && <p role="status">提出しました</p>}
        </form>
      )}
    </main>
  );
}
