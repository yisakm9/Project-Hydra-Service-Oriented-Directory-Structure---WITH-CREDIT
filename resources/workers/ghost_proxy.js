/**
 * Project Hydra: Advanced Edge Redirector (Cloudflare Worker)
 * Features: Explicit Host rewriting, Method passthrough, Header Scrubbing
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const backend = new URL(env.C2_BACKEND);

    // Construct the true destination URL
    const targetUrl = new URL(url.pathname + url.search, backend);

    // CRITICAL FIX: Clone headers and rewrite the 'Host' to match CloudFront
    const newHeaders = new Headers(request.headers);
    newHeaders.set("Host", backend.hostname);

    // Build the clean proxy request configuration
    const init = {
      method: request.method,
      headers: newHeaders,
      redirect: "manual"
    };

    // Body cannot be attached to GET or HEAD requests
    if (request.method !== "GET" && request.method !== "HEAD") {
      init.body = request.body;
    }

    const proxyRequest = new Request(targetUrl, init);

    try {
      const response = await fetch(proxyRequest);

      // Sanitize the response headers to hide AWS/CloudFront origins
      const newResponse = new Response(response.body, response);
      newResponse.headers.delete("Server");
      newResponse.headers.delete("X-Cache");
      newResponse.headers.delete("Via");
      newResponse.headers.delete("X-Amz-Cf-Pop");
      newResponse.headers.delete("X-Amz-Cf-Id");

      return newResponse;
    } catch (e) {
      return new Response("Service Unavailable: " + e.message, { status: 503 });
    }
  }
};