"use client";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { callApi } from "@/lib/api";

export default function Home() {
  const router = useRouter();
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function join(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true); setError("");
    try {
      const { roomId } = await callApi<{ roomId: string }>("/rooms/join", { code });
      router.push(`/rooms/${roomId}`);
    } catch (err) {
      setError((err as Error).message);
      setBusy(false);
    }
  }

  return (
    <main style={{ maxWidth: 480, margin: "48px auto", padding: 16, fontFamily: "sans-serif" }}>
      <h1>みんなの考えが活きる議論へ</h1>
      <form onSubmit={join}>
        <label htmlFor="code">参加コード</label>
        <input id="code" value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} maxLength={6} autoComplete="off" style={{ display: "block", fontSize: 24, width: "100%", margin: "8px 0" }} />
        <button type="submit" disabled={busy || code.length !== 6}>参加する</button>
      </form>
      {error && <p role="alert">{error}</p>}
    </main>
  );
}
