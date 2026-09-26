const json = (data, status=200) => new Response(JSON.stringify(data), {
  status, headers: { "content-type": "application/json; charset=utf-8", "access-control-allow-origin": "*", "access-control-allow-headers": "Content-Type, Authorization", "access-control-allow-methods": "GET, POST, OPTIONS" }
});

const now = () => new Date().toISOString();

async function sha256(value) {
  const bytes = new TextEncoder().encode(value);
  const hash = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(hash)].map(x => x.toString(16).padStart(2, "0")).join("");
}

function auth(request, env) {
  const header = request.headers.get("Authorization") || "";
  return env.ADMIN_API_KEY && header === "Bearer " + env.ADMIN_API_KEY;
}

function randomCode(prefix) {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  const value = [...bytes].map(x => x.toString(16).padStart(2, "0")).join("").toUpperCase();
  return prefix + value;
}

async function ensureSchema(env) {
  await env.DB.exec(`
    CREATE TABLE IF NOT EXISTS licenses (
      id TEXT PRIMARY KEY,
      customer_name TEXT NOT NULL,
      license_code_hash TEXT NOT NULL UNIQUE,
      plan TEXT NOT NULL CHECK(plan IN ('6_months','1_year','permanent')),
      device_id TEXT,
      issued_at TEXT NOT NULL,
      activated_at TEXT,
      expires_at TEXT,
      status TEXT NOT NULL DEFAULT 'active',
      last_check_at TEXT,
      created_at TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_licenses_device ON licenses(device_id);
    CREATE INDEX IF NOT EXISTS idx_licenses_status ON licenses(status);
    CREATE TABLE IF NOT EXISTS audit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      action TEXT NOT NULL,
      license_id TEXT,
      device_id TEXT,
      details TEXT,
      created_at TEXT NOT NULL
    );
  `);
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return json({ok:true});
    const url = new URL(request.url);

    try {
      await ensureSchema(env);
      if (url.pathname === "/" && request.method === "GET") {
        return json({ok:true, service:"ADREEMK Licensing API", version:"1.0.0"});
      }

      if (url.pathname === "/v1/activate" && request.method === "POST") {
        const body = await request.json();
        const code = String(body.code || "").trim().toUpperCase();
        const deviceId = String(body.deviceId || "").trim();
        if (!code || !deviceId) return json({ok:false,error:"code_and_device_required"},400);

        const hash = await sha256(code);
        const row = await env.DB.prepare("SELECT * FROM licenses WHERE license_code_hash = ? AND status = 'active'").bind(hash).first();
        if (!row) return json({ok:false,error:"invalid_license"},403);

        if (row.device_id && row.device_id !== deviceId) return json({ok:false,error:"device_mismatch"},409);

        if (row.expires_at && new Date(row.expires_at) <= new Date()) {
          await env.DB.prepare("UPDATE licenses SET status='expired' WHERE id=?").bind(row.id).run();
          return json({ok:false,error:"license_expired"},403);
        }

        await env.DB.prepare("UPDATE licenses SET device_id=?, activated_at=COALESCE(activated_at,?), last_check_at=? WHERE id=?")
          .bind(deviceId, now(), now(), row.id).run();

        await env.DB.prepare("INSERT INTO audit_logs(action,license_id,device_id,details,created_at) VALUES(?,?,?,?,?)")
          .bind("activate",row.id,deviceId,"activation check",now()).run();

        return json({ok:true, license:{
          id:row.id, plan:row.plan, expiresAt:row.expires_at, permanent:row.plan==="permanent"
        }});
      }

      const licenseMatch = url.pathname.match(/^\/v1\/license\/([^/]+)$/);
      if (licenseMatch && request.method === "GET") {
        const deviceId = decodeURIComponent(licenseMatch[1]);
        const row = await env.DB.prepare("SELECT id,plan,expires_at,status FROM licenses WHERE device_id=? AND status='active'").bind(deviceId).first();
        if (!row) return json({ok:false,error:"license_not_found"},404);
        if (row.expires_at && new Date(row.expires_at) <= new Date()) {
          await env.DB.prepare("UPDATE licenses SET status='expired' WHERE id=?").bind(row.id).run();
          return json({ok:false,error:"license_expired"},403);
        }
        await env.DB.prepare("UPDATE licenses SET last_check_at=? WHERE id=?").bind(now(),row.id).run();
        return json({ok:true,license:{id:row.id,plan:row.plan,expiresAt:row.expires_at,permanent:row.plan==="permanent"}});
      }

      if (url.pathname === "/v1/admin/licenses" && request.method === "POST") {
        if (!auth(request,env)) return json({ok:false,error:"unauthorized"},401);
        const body = await request.json();
        const plan = String(body.plan || "");
        if (!["6_months","1_year","permanent"].includes(plan)) return json({ok:false,error:"invalid_plan"},400);

        const prefix = plan==="6_months" ? "AD6-" : plan==="1_year" ? "AD12-" : "ADP-";
        const code = randomCode(prefix);
        const hash = await sha256(code);
        const id = crypto.randomUUID();
        const issued = now();
        let expires = null;
        if (plan==="6_months") expires = new Date(Date.now()+183*86400000).toISOString();
        if (plan==="1_year") expires = new Date(Date.now()+365*86400000).toISOString();

        await env.DB.prepare("INSERT INTO licenses(id,customer_name,license_code_hash,plan,issued_at,expires_at,status,created_at) VALUES(?,?,?,?,?,?,?,?)")
          .bind(id,String(body.customerName||"عميل"),hash,plan,issued,expires,"active",issued).run();

        await env.DB.prepare("INSERT INTO audit_logs(action,license_id,details,created_at) VALUES(?,?,?,?)")
          .bind("create",id,"license created",issued).run();

        return json({ok:true,id,code,plan,expiresAt:expires});
      }

      if (url.pathname === "/v1/admin/licenses" && request.method === "GET") {
        if (!auth(request,env)) return json({ok:false,error:"unauthorized"},401);
        const {results=[]}=await env.DB.prepare("SELECT id,customer_name,plan,device_id,issued_at,activated_at,expires_at,status,last_check_at,created_at FROM licenses ORDER BY created_at DESC").all();
        return json({ok:true,licenses:results});
      }

      return json({ok:false,error:"not_found"},404);
    } catch (e) {
      return json({ok:false,error:"server_error",message:String(e)},500);
    }
  }
};