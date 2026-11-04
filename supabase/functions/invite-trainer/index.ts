const corsHeaders = {
  "Access-Control-Allow-Origin": "https://bautnhaus.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve((req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: corsHeaders });
  }

  return new Response(
    JSON.stringify({
      success: false,
      error: "Diese alte Einladungsfunktion ist außer Betrieb. Bitte verwende die zentrale Mitgliedseinladung.",
      replacement: "invite-member",
    }),
    {
      status: 410,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});
