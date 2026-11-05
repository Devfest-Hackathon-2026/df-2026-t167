import type { Metadata } from "next";

export const metadata: Metadata = { title: "T167 Discussion", description: "AI協調型グループディスカッション支援" };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ja">
      <body>{children}</body>
    </html>
  );
}
