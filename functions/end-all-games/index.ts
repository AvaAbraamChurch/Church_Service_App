import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Cache access token to avoid regenerating on every request
let cachedToken: { token: string; expiresAt: number } | null = null;

async function getAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 300000) {
    return cachedToken.token;
  }

  const { GoogleAuth } = await import("https://esm.sh/google-auth-library@9.4.1");

  const privateKey = (Deno.env.get("FIREBASE_PRIVATE_KEY") || "")
    .replace(/\\n/g, "\n");

  const auth = new GoogleAuth({
    credentials: {
      type: Deno.env.get("FIREBASE_SERVICE_ACCOUNT_TYPE"),
      project_id: Deno.env.get("FIREBASE_PROJECT_ID"),
      private_key_id: Deno.env.get("FIREBASE_PRIVATE_KEY_ID"),
      private_key: privateKey,
      client_email: Deno.env.get("FIREBASE_CLIENT_EMAIL"),
      client_id: Deno.env.get("FIREBASE_CLIENT_ID"),
      auth_uri: Deno.env.get("FIREBASE_AUTH_URI"),
      token_uri: Deno.env.get("FIREBASE_TOKEN_URI"),
      auth_provider_x509_cert_url: Deno.env.get("FIREBASE_AUTH_PROVIDER_X509_CERT_URL"),
      client_x509_cert_url: Deno.env.get("FIREBASE_CLIENT_X509_CERT_URL"),
      universe_domain: Deno.env.get("FIREBASE_UNIVERSE_DOMAIN"),
    },
    scopes: [
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/cloud-platform",
    ],
  });

  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();

  if (!tokenResponse.token) {
    throw new Error("Failed to obtain access token");
  }

  cachedToken = {
    token: tokenResponse.token,
    expiresAt: Date.now() + 3540000,
  };

  return tokenResponse.token;
}

function validateAdmin(req: Request): boolean {
  const apiKey = req.headers.get("apikey");
  const adminKey = Deno.env.get("ADMIN_API_KEY");
  return !!(apiKey && adminKey && apiKey === adminKey);
}

function getFirestoreBaseUrl(projectId: string): string {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
}

async function listAllDocumentNames(path: string): Promise<string[]> {
  const projectId = Deno.env.get("FIREBASE_PROJECT_ID") || "";
  const accessToken = await getAccessToken();
  const baseUrl = getFirestoreBaseUrl(projectId);

  const names: string[] = [];
  let pageToken: string | undefined;

  do {
    const url = new URL(`${baseUrl}/${path}`);
    url.searchParams.set("pageSize", "200");
    if (pageToken) url.searchParams.set("pageToken", pageToken);

    const response = await fetch(url.toString(), {
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${accessToken}`,
      },
    });

    const result = await response.json();
    if (!response.ok) {
      throw new Error(result.error?.message || "Failed to list Firestore documents");
    }

    const documents = result.documents || [];
    for (const doc of documents) {
      if (doc.name) names.push(doc.name as string);
    }

    pageToken = result.nextPageToken;
  } while (pageToken);

  return names;
}

async function updateGameStatusActive(documentName: string): Promise<void> {
  const accessToken = await getAccessToken();
  const url = new URL(`https://firestore.googleapis.com/v1/${documentName}`);
  url.searchParams.set("updateMask.fieldPaths", "status");

  const response = await fetch(url.toString(), {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      fields: {
        status: { stringValue: "active" },
      },
    }),
  });

  const result = await response.json();
  if (!response.ok) {
    throw new Error(result.error?.message || "Failed to update game status");
  }
}

async function deleteDocument(documentName: string): Promise<void> {
  const accessToken = await getAccessToken();
  const response = await fetch(`https://firestore.googleapis.com/v1/${documentName}`, {
    method: "DELETE",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    const result = await response.json().catch(() => ({}));
    throw new Error(result.error?.message || "Failed to delete document");
  }
}

function extractDocumentPath(documentName: string): string {
  const marker = "/documents/";
  const index = documentName.indexOf(marker);
  return index >= 0 ? documentName.slice(index + marker.length) : documentName;
}

async function endAllGames(): Promise<{ gamesUpdated: number; playingChildrenDeleted: number }> {
  const gameDocs = await listAllDocumentNames("club_games");

  let gamesUpdated = 0;
  let playingChildrenDeleted = 0;

  for (const gameDocName of gameDocs) {
    await updateGameStatusActive(gameDocName);
    gamesUpdated += 1;

    const gamePath = extractDocumentPath(gameDocName);
    const playingChildrenPath = `${gamePath}/playing_children`;
    const playingDocs = await listAllDocumentNames(playingChildrenPath);

    for (const playingDocName of playingDocs) {
      await deleteDocument(playingDocName);
      playingChildrenDeleted += 1;
    }
  }

  return { gamesUpdated, playingChildrenDeleted };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    if (!validateAdmin(req)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const result = await endAllGames();

    return new Response(
      JSON.stringify({
        success: true,
        message: "All games ended successfully",
        ...result,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error: any) {
    console.error("End-all games error:", {
      message: error.message,
      stack: error.stack,
      name: error.name,
    });

    return new Response(JSON.stringify({ error: error.message || "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

