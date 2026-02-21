/**
 * Project Hydra: Edge Redirector (Cloudflare Worker)
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // The AWS CloudFront URL injected by Terraform
    const backend = env.C2_BACKEND; 
    const targetUrl = backend + url.pathname + url.search;

    // Create a clean request to forward
    const proxyRequest = new Request(targetUrl, request);

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
        return new Response("Service Unavailable", { status: 503 });
    }
  }
};