/**
 * Project Hydra: Clean Edge Redirector (Cloudflare Worker)
 * Safely forwards traffic to GCP Load Balancer while maintaining stealth.
 * Domain: googleupdate.uk
 */
export default {
  async fetch(request, env) {
    const proxyHeaders = new Headers(request.headers);

    // Scrub standard Cloudflare & tracing headers from the inbound request
    proxyHeaders.delete("CF-Connecting-IP");
    proxyHeaders.delete("True-Client-IP");
    proxyHeaders.delete("X-Forwarded-For");
    proxyHeaders.delete("CF-Ray");
    proxyHeaders.delete("CF-IPCountry");
    proxyHeaders.delete("CF-Visitor");
    proxyHeaders.delete("CDN-Loop");

    // Build the request pointing natively to the same URL (relies on Cloudflare A record -> GCP Port 80 Flexible SSL)
    const proxyRequest = new Request(request.url, {
      method: request.method,
      headers: proxyHeaders,
      body: (request.method !== 'GET' && request.method !== 'HEAD') ? request.body : null,
      redirect: 'manual'
    });

    try {
      const response = await fetch(proxyRequest);

      const newResponseHeaders = new Headers(response.headers);
      // Scrub GCP and Google tracing headers for maximum stealth
      newResponseHeaders.delete("Server");
      newResponseHeaders.delete("X-Cloud-Trace-Context");
      newResponseHeaders.delete("X-GUploader-UploadID");
      newResponseHeaders.delete("X-Goog-Generation");
      newResponseHeaders.delete("X-Goog-Metageneration");
      newResponseHeaders.delete("X-Goog-Hash");
      newResponseHeaders.delete("Via");
      newResponseHeaders.delete("Alt-Svc");

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