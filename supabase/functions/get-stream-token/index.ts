/**
 * Supabase Edge Function: get-stream-token
 *
 * Securely generates a GetStream Chat user token.
 *
 * Flow:
 * 1. Verify the caller's Supabase session (Authorization header).
 * 2. Extract the user's Supabase ID.
 * 3. Upsert the user in Stream (so they exist before any channel is created).
 * 4. Generate and return a Stream user token.
 *
 * Required Supabase secrets:
 *   STREAM_KEY    — GetStream API Key  (also used client-side)
 *   STREAM_SECRET — GetStream API Secret (SERVER-SIDE ONLY, never in Flutter)
 *
 * Deploy:
 *   supabase functions deploy get-stream-token
 *
 * Set secrets:
 *   supabase secrets set STREAM_KEY=ny4zvscgpxxz STREAM_SECRET=<your_secret>
 */

import { StreamChat } from "npm:stream-chat";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1. Authenticate the Supabase user ────────────────────────
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── 2. Initialize Stream server client ───────────────────────
    const streamKey = Deno.env.get("STREAM_KEY")!;
    const streamSecret = Deno.env.get("STREAM_SECRET")!;
    const serverClient = StreamChat.getInstance(streamKey, streamSecret);

    // ── 3. Upsert user in Stream ─────────────────────────────────
    // Fetch the user's profile from Supabase for name/avatar
    const { data: profile } = await supabaseClient
      .from("profiles")
      .select("display_name, avatar_url")
      .eq("id", user.id)
      .maybeSingle();

    const displayName =
      profile?.display_name ||
      user.user_metadata?.display_name ||
      user.email?.split("@")[0] ||
      "User";

    const avatarUrl =
      profile?.avatar_url || user.user_metadata?.avatar_url || "";

    await serverClient.upsertUsers([
      {
        id: user.id,
        name: displayName,
        image: avatarUrl || undefined,
      },
    ]);

    // ── 4. Generate token ────────────────────────────────────────
    const token = serverClient.createToken(user.id);

    return new Response(
      JSON.stringify({ token }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("get-stream-token error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
